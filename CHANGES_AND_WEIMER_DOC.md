# DGCPM Weimer05 Integration Notes and Change Log

Date: 2026-04-11

## 1. Summary

This document describes all code changes made to integrate a Weimer05 electric potential option into DGCPM, while keeping existing Volland-Stern behavior as default fallback.

The implementation now supports two standalone driver modes for Weimer05:

1. fixed: use constant IMF/SW values from PARAM input
2. file: read time-dependent IMF/SW values from an MHD/IMF index file

The runtime model switch is controlled by EFieldModel.

## 2. Files Modified

1. GM/DGCPM/src/ModMainDGCPM.f90
2. GM/DGCPM/src/dgcpm_main.f90
3. GM/DGCPM/src/dgcpm_setup.f90
4. GM/DGCPM/src/PS_wrapper.f90
5. GM/DGCPM/src/Makefile

## 3. Detailed Code Changes

### 3.1 ModMainDGCPM.f90

Added new runtime configuration variables for Weimer05:

- WeimerImfFile (character): path to MHD/IMF driver file
- WeimerInput (character): fixed or file
- WeimerBy (real): IMF By in nT
- WeimerBz (real): IMF Bz in nT
- WeimerV (real): solar wind speed in km/s
- WeimerN (real): solar wind density in 1/cc

These are global state variables read from PARAM commands and consumed in dgcpm_setup.f90.

### 3.2 dgcpm_main.f90

Removed direct hard-coded call to magconv in the time loop.

Before:

- getkpa
- magconv
- thermal

After:

- getkpa
- thermal

Reason: thermal now selects and updates the electric potential model (Volland-Stern or Weimer05), so calling magconv in main would double-apply legacy behavior.

### 3.3 dgcpm_setup.f90

#### 3.3.1 Thermal model selection

Inside THERMAL, standalone branch now does:

- if EFieldModel contains weimer05: call set_weimer05_potential(CurrentTime, mgridpot)
- else: call magconv
- then always call setpot(..., mgridpot)

This preserves original interpolation/drift pipeline while replacing the potential source.

#### 3.3.2 New subroutine: set_weimer05_potential

Added a new subroutine that computes DGCPM-grid potential from the EIE Weimer05 backend.

Key logic:

- One-time initialization:
  - Set EIE background with model string weimer05
  - Call EIE_Initialize
  - Build DGCPM MLT and magnetic-latitude grids used by EIE IO_SetGrid
  - Initialize driver input source:
    - file mode: read_MHDIMF_Indices via IO_set_inputs
    - fixed mode: IO_set_IMF_By_single, IO_set_IMF_Bz_single, IO_set_SW_v_single, IO_set_SW_n_single
- Every call:
  - Read current driver values with get_IMF_By, get_IMF_Bz, get_SW_V, get_SW_N
  - Set EIE runtime inputs: time, IMF, SW
  - Evaluate potential via IO_SetGrid + IO_GetPotential
  - Transpose model output into DGCPM ordering PotOut_II(ntheta, nphi)

#### 3.3.3 Formula-related transformations in the new path

The Weimer05 backend itself computes potential from empirical coefficients and boundary tables.
The DGCPM-side preprocessing now applies:

1. MLT conversion from DGCPM phi:

   MLT = mod(phi_deg / 15 + 12, 24)

2. Magnetic latitude conversion from DGCPM colatitude:

   mlat = 90 - theta_deg

3. SW speed sign handling:

   Vsw_for_model = abs(Vsw)

No additional DGCPM-side analytic potential formula is imposed in Weimer05 mode.
The old Volland-Stern formula remains unchanged in magconv.

### 3.4 PS_wrapper.f90

#### 3.4.1 New PARAM commands

Added parser support:

- #EFIELDMODEL
  - EFieldModel
- #WEIMER
  - WeimerInput
  - if WeimerInput=file: WeimerImfFile
  - else fixed mode: WeimerBy, WeimerBz, WeimerV, WeimerN

#### 3.4.2 Initialization and run flow updates

In PS_init_session standalone branch:

- if EFieldModel=weimer05: call set_weimer05_potential
- else: call magconv
- then call setpot

In PS_run:

- removed direct standalone magconv call
- thermal is now the single place updating potential model each step

### 3.5 Makefile (GM/DGCPM/src/Makefile)

Updated include and link setup for Weimer support:

1. SEARCHDIR now includes EMPIRICALIEDIR
2. dgcpm target now explicitly ensures libraries are built:
   - libINDICES.a
   - libEMPIRICALIE.a
3. dgcpm.exe link command now links:
   - -lEMPIRICALIE
   - -lINDICES
   - -lSHARE

This is required because Weimer05 and index readers live in util/EMPIRICAL/srcIE and util/DATAREAD/srcIndices.

## 4. How Potential Calculation Works Now

### 4.1 Runtime selection

In standalone mode, THERMAL chooses potential source by EFieldModel:

1. weimer05 -> set_weimer05_potential
2. anything else -> magconv (Volland-Stern)

Then setpot interpolates and computes electric-field gradients and drifts as before.

### 4.2 Weimer05 data flow

1. DGCPM prepares (MLT, magnetic latitude) grid
2. IMF/SW drivers are loaded (fixed or file)
3. At each simulation time:
   - CurrentTime is sent to EIE
   - By, Bz, Vsw, Nsw are sent to EIE
   - EIE evaluates potential and returns Pot(MLT, MLAT)
4. DGCPM copies/transposes to mgridpot(ntheta, nphi)
5. Existing DGCPM setpot pipeline computes ExB drift coefficients

## 5. Variable and Data Source Mapping

### 5.1 Model selection and Weimer config variables

Defined in:

- GM/DGCPM/src/ModMainDGCPM.f90

Read from PARAM in:

- GM/DGCPM/src/PS_wrapper.f90

Consumed in:

- GM/DGCPM/src/dgcpm_setup.f90

### 5.2 IMF/SW values

Used variables in model call:

- By, Bz, Vsw, Nsw

Pulled by:

- get_IMF_By(CurrentTime,...)
- get_IMF_Bz(CurrentTime,...)
- get_SW_V(CurrentTime,...)
- get_SW_N(CurrentTime,...)

Interface definitions:

- util/DATAREAD/srcIndices/ModIndicesInterfaces.f90

### 5.3 File-driven IMF/SW reading

Reader:

- util/DATAREAD/srcIndices/read_MHDIMF_indices.f90

Initialization call path in DGCPM:

- IO_set_inputs(... '#MHDIMF_INDICES' ...)
- read_MHDIMF_Indices(iError)

Example input file format:

- GM/DGCPM/Input/IMF_NSturning_10nT.dat

Expected columns under #START are parsed as:

- time fields (year, month, day, hour, minute, second, msec)
- IMF Bx, By, Bz
- SW Vx, Vy, Vz
- SW density
- SW temperature

The reader computes SW speed magnitude internally from Vx,Vy,Vz.

## 6. Build/Compilation Check Performed

Command run:

- cd GM/DGCPM/src
- make dgcpm -j1

Result:

- Compilation of modified sources succeeded
- Link step failed due pre-existing standalone link gaps unrelated to the new Weimer calls:
  - missing legacy standalone routines referenced by dgcpm_main (dgcpc_read_inputs, readpara, constant, arrays)
  - unresolved framework symbols from CON_* modules when linking this standalone target
  - MPI symbol resolution issues due current standalone link toolchain/flags

Important note:

- After adding use ModIndicesInterfaces in set_weimer05_potential, the new get_IMF/get_SW unresolved symbols introduced during first attempt were fixed.
- Remaining errors indicate the current dgcpm.exe standalone target in this tree is not fully link-complete as configured.

## 7. Runtime Dependencies

For SWMF runs that initialize the Weimer05 model through PS, the runtime directory must contain an `EIE/` subdirectory in the launch folder. In practice, if you start `SWMF.exe` from `bin/`, create `bin/EIE/` and place symlinks there.

The Weimer05 initialization path requires these four files in `EIE/`:

1. `W05scEpot.dat`
2. `SCHAtable.dat`
3. `W05scBndy.dat`
4. `hpke.noaa`

Recommended setup:

mkdir -p /home/kolos/Kolos_munka/DGCPM_v3/SWMF/bin/EIE
ln -s /home/kolos/Kolos_munka/DGCPM_v3/SWMF/util/EMPIRICAL/srcIE/data/W05scEpot.dat  /home/kolos/Kolos_munka/DGCPM_v3/SWMF/bin/EIE/
ln -s /home/kolos/Kolos_munka/DGCPM_v3/SWMF/util/EMPIRICAL/srcIE/data/SCHAtable.dat   /home/kolos/Kolos_munka/DGCPM_v3/SWMF/bin/EIE/
ln -s /home/kolos/Kolos_munka/DGCPM_v3/SWMF/util/EMPIRICAL/srcIE/data/W05scBndy.dat    /home/kolos/Kolos_munka/DGCPM_v3/SWMF/bin/EIE/
ln -s /home/kolos/Kolos_munka/DGCPM_v3/SWMF/util/EMPIRICAL/srcIE/data/hpke.noaa        /home/kolos/Kolos_munka/DGCPM_v3/SWMF/bin/EIE/

The reason this directory matters is that `EIE_Initialize` resolves the model directory string as `EIE/` and then appends the filenames above. If the `EIE/` folder is missing from the launch directory, the run will fail with a file-open error before the model can compute any potential.

## 8. Working PARAM.in Structure

The following block is the final working structure under #BEGIN_COMP PS:

#EFIELDMODEL
weimer05        EFieldModel

#WEIMERIMF
/home/kolos/Kolos_munka/DGCPM_v3/SWMF/GM/DGCPM/Input/imf_test_input.dat

Notes:

1. #WEIMERIMF forces file-driven Weimer input and sets EFieldModel to weimer05.
2. Absolute path is supported and was used in the successful run.

## 9. IMF File Format

The IMF reader used by DGCPM is read_MHDIMF_Indices. It scans until it finds #START, then reads one data record per line with 15 columns:

1. year
2. month
3. day
4. hour
5. minute
6. second
7. millisecond
8. IMF_Bx
9. IMF_By
10. IMF_Bz
11. SW_Vx
12. SW_Vy
13. SW_Vz
14. SW_N
15. SW_T

The final working file template:

#COORDINATES
GSM

#POSITION
0.0
0.0

#START
2024 10 10 00 00 00 0   0.0  0.0  5.0  -400.0  0.0  0.0  5.0  100000.0
...
2024 10 11 00 00 00 0   0.0  0.0  5.0  -400.0  0.0  0.0  5.0  124000.0

## 10. Example PARAM Snippets

### 7.1 Fixed drivers

#EFIELDMODEL
EFieldModel = weimer05

#WEIMER
WeimerInput = fixed
WeimerBy = 2.0
WeimerBz = -6.0
WeimerV = 450.0
WeimerN = 6.0

### 7.2 File drivers

#EFIELDMODEL
EFieldModel = weimer05

#WEIMER
WeimerInput = file
WeimerImfFile = GM/DGCPM/Input/IMF_NSturning_10nT.dat

### 7.3 Raw filename block

The PS wrapper also accepts a compact block directly under #BEGIN_COMP PS:

#WEIMERIMF
imf_test_input.dat

This form sets WeimerInput=file, copies the filename into WeimerImfFile, and forces EFieldModel=weimer05.

## 11. Practical Notes

1. If your run is coupled to IE, DGCPM still uses incoming IE potential via setpot(Ie...)
2. Weimer05 path is used in standalone branch only
3. Keep EFieldModel as VS to preserve legacy Volland-Stern behavior
4. The Weimer05 backend expects model data files under EIE model directory (configured as EIE/)

## 12. Final Validation

Confirmed in run output:

1. DEBUG: set_weimer05_potential after read_MHDIMF_Indices, iError=0
2. Finished Numerical Simulation
3. Simulated time = 8.64000E+04 s
4. 24 hours simulated successfully with Weimer05 active
