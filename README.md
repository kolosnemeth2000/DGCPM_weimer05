# Dynamic Global Core Plasma Model (DGCPM) with Weimer05 Electric Field in SWMF

[![Fortran](https://img.shields.io/badge/Language-Fortran_90%2F95-blue.svg)](https://en.wikipedia.org/wiki/Fortran)
[![Framework](https://img.shields.io/badge/Framework-SWMF-orange.svg)](https://github.com/SWMFsoftware/SWMF)
[![Electric Field](https://img.shields.io/badge/Electric_Field-Weimer05-green.svg)](#electric-field-models-volland-stern-vs-weimer05)
[![License](https://img.shields.io/badge/License-University_of_Michigan-lightgrey.svg)](LICENSE.txt)

A complete, self-contained, and reproducible release of the **Dynamic Global Core Plasma Model (DGCPM)** integrated with the empirical **Weimer05 electric potential model**, hosted within the **Space Weather Modeling Framework (SWMF)**.

This repository provides all source code, empirical coefficient tables, parameter files, and driver data required to build and run DGCPM with high-latitude empirical convection fields driven directly by upstream Solar Wind (SW) and Interplanetary Magnetic Field (IMF) time series.

---

## Table of Contents

1. [Overview & Motivation](#1-overview--motivation)
2. [Scientific Model Description](#2-scientific-model-description)
3. [Electric Field Models: Volland-Stern vs. Weimer05](#3-electric-field-models-volland-stern-vs-weimer05)
4. [Required Input Parameters](#4-required-input-parameters)
5. [Driver File Formats](#5-driver-file-formats)
6. [Parameter File (PARAM.in) Configuration Guide](#6-parameter-file-paramin-configuration-guide)
7. [Installation & Build Instructions](#7-installation--build-instructions)
8. [Running Simulations](#8-running-simulations)
9. [Output Files & Data Visualization](#9-output-files--data-visualization)
10. [Code Architecture & Weimer Integration Details](#10-code-architecture--weimer-integration-details)
11. [References & Citations](#11-references--citations)

---

## 1. Overview & Motivation

**DGCPM** is a two-dimensional equatorial model of the Earth's core plasma (the plasmasphere). Historically, standard DGCPM relied on a simplified analytic electric field model—the **Volland-Stern** model—which depends on a single scalar parameter: the 3-hour geomagnetic **$K_p$ index**. While computationally lightweight, the Volland-Stern model cannot represent:
- Asymmetric dawn-dusk convection driven by IMF $B_y$.
- Dynamic responses to rapid IMF $B_z$ southward and northward turnings.
- Variable solar wind speed ($V_{sw}$) and dynamic pressure ($P_{dyn}$) effects.
- Realistic plasmaspheric drainage plume orientations and boundary structures.

To overcome these limitations, we integrated the empirical **Weimer05** electric potential model into DGCPM. Because Weimer05 evaluates empirical spherical harmonic expansions based on satellite measurements and requires upstream solar wind indices, it relies on SWMF's empirical ionospheric electrodynamics library (`util/EMPIRICAL/srcIE`) and time-series indices reader (`util/DATAREAD/srcIndices`).

This repository packages the entire working SWMF environment configured specifically for DGCPM (`PS` component) so that any researcher can clone, build, and run the code without needing access to private institutional repositories.

---

## 2. Scientific Model Description

The **Earth's plasmasphere** consists of cold ($\sim 1\text{ eV}$), dense ($10^1 - 10^4\text{ cm}^{-3}$) ionospheric plasma trapped along closed geomagnetic field lines inside the magnetosphere.

DGCPM solves for the equatorial core plasma flux-tube content and density by modeling two coupled physical processes:
1. **Flux-Tube Refilling & Emptying**:
   - Day-side refilling from the underlying ionosphere via ambipolar diffusion.
   - Night-side refilling / drainage and convective loss when flux tubes are convected beyond the magnetopause or onto open drift paths.
2. **Equatorial Transport ($\mathbf{E} \times \mathbf{B}$ Drift)**:
   Plasma elements drift according to the total electric field:
   $$\mathbf{v}_{\perp} = \frac{\mathbf{E} \times \mathbf{B}}{B^2}$$
   where the total electric field is the sum of:
   - **Corotation Electric Field** $\mathbf{E}_{cor}$: Induced by the rotation of the Earth's magnetic field.
   - **Convection Electric Field** $\mathbf{E}_{conv} = -\nabla \Phi$: Imposed by the solar wind interaction with the magnetosphere and mapped along geomagnetic field lines.

The competition between corotation (dominant close to Earth, $L < 3$) and convection (dominant at higher $L$-shells) defines the **plasmapause boundary** and produces dynamic features such as **plasmaspheric drainage plumes** during geomagnetic storms.

---

## 3. Electric Field Models: Volland-Stern vs. Weimer05

| Feature | Volland-Stern (Legacy) | Weimer05 (Integrated in this Release) |
| :--- | :--- | :--- |
| **Driver Inputs** | Scalar $K_p$ index only | IMF $B_y$, $B_z$, $V_{sw}$, $N_{sw}$, Earth Dipole Tilt |
| **Time Resolution** | 3 hours (inherent to $K_p$) | Continuous / 1 minute (high-resolution solar wind) |
| **Symmetry** | Strictly dawn-dusk symmetric | Realistic IMF $B_y$-dependent dawn-dusk distortion |
| **Potential Saturation**| Linear / power-law (no saturation) | Empirical saturation during extreme driving |
| **Plume Morphology** | Standard sunward-pointing tail | Dynamically rotated and sheared drainage plumes |
| **Substorm / Turning** | Delayed, smoothed | Immediate response to IMF $B_z$ northward/southward turnings |

### Volland-Stern Formulation
$$\Phi_{VS}(L, \phi) = -A(K_p) \cdot L^{\gamma} \sin(\phi - \phi_0)$$
where $A(K_p)$ is an empirical amplitude scaled by $K_p$ and $\gamma \approx 2$.

### Weimer05 Formulation
The Weimer05 model evaluates electric potential expanded into spherical harmonics on a magnetic latitude ($\lambda_{mag}$) and Magnetic Local Time ($\text{MLT}$) grid:
$$\Phi(\lambda_{mag}, \text{MLT}) = \sum_{l=0}^{L} \sum_{m=-l}^{l} c_{lm}(B_y, B_z, V_{sw}, N_{sw}, \theta_{tilt}) Y_{lm}(\lambda_{mag}, \text{MLT})$$
The coefficients $c_{lm}$ are parameterized non-linearly from extensive satellite electric field and magnetometer measurements (DE-2, etc.).

---

## 4. Required Input Parameters

When running DGCPM in **Weimer05** mode, the model requires time-dependent solar wind and interplanetary magnetic field (IMF) parameters:

| Parameter | Symbol | Units | Description & Physical Role |
| :--- | :--- | :--- | :--- |
| **IMF $B_y$** | $B_y$ | $\text{nT}$ | Dawn-dusk IMF component (GSM coordinates). Controls convection cell asymmetry and rotates the plasmaspheric drainage plume. |
| **IMF $B_z$** | $B_z$ | $\text{nT}$ | North-south IMF component (GSM coordinates). Negative ($B_z < 0$, southward) drives reconnection, expanding the convection zone and eroding the plasmasphere. |
| **IMF $B_x$** | $B_x$ | $\text{nT}$ | Sun-Earth IMF component (GSM coordinates). Included in standard driver files. |
| **Solar Wind Velocity** | $V_x, V_y, V_z$ | $\text{km/s}$ | Solar wind bulk velocity vectors (GSM coordinates). DGCPM calculates speed $V_{sw} = \sqrt{V_x^2 + V_y^2 + V_z^2}$. |
| **Proton Number Density**| $N_{sw}$ | $\text{cm}^{-3}$ ($n/\text{cc}$) | Solar wind proton density. Sets dynamic pressure $P_{dyn} = m_p N_{sw} V_{sw}^2$, compressing the magnetosphere. |
| **Proton Temperature** | $T_{sw}$ | $\text{K}$ | Solar wind proton temperature. |
| **Simulation Epoch** | Year, Month, Day, Hour, Min, Sec | UTC | Determines the orientation of the Earth's dipole axis ($\theta_{tilt}$) relative to the Sun-Earth line. |
| **Geomagnetic $K_p$** | $K_p$ | $0 - 9$ | Used by DGCPM for ionospheric refilling rate scaling and boundary conditions, or as fallback if Volland-Stern is selected. |

---

## 5. Driver File Formats

### 5.1 Solar Wind & IMF Driver File (`read_MHDIMF_indices` format)

The Weimer05 electric field reader parses time-series files formatted according to SWMF's standard `#MHD_INDICES` format:

```text
#COORDINATES
GSM

#POSITION
0.0
0.0

#START
year month day hour min sec msec   IMF_Bx  IMF_By  IMF_Bz   SW_Vx   SW_Vy   SW_Vz   SW_N       SW_T
2024    05  09   00  00  00    0    -1.46    0.95    1.45 -458.20    4.00   -9.80   2.82  101586.00
2024    05  09   00  01  00    0    -1.75    0.90    1.10 -457.90   10.50  -19.50   3.03  111521.00
...
```

#### Included Datasets:
- **`GM/DGCPM/Input/imf_input.dat`**: Real 1-minute OMNI solar wind data covering the historic **May 9–13, 2024 severe geomagnetic storm** (Mother's Day Storm, $K_p = 9$).
- **`GM/DGCPM/Input/imf_test_input.dat`**: Synthetic 24-hour test dataset featuring a southward IMF turning from $+5\text{ nT}$ to $-5\text{ nT}$.

### 5.2 $K_p$ Index Driver File (`kp_test_input.dat`)

```text
#
# Element: kp
# Measure units: Kp
# Description: Kyoto Kp
#
#yyyy-MM-dd HH:mm value qualifier description
2024-05-09 00:00    2.0	"0"	""
2024-05-09 03:00    3.0	"-"	""
2024-05-09 06:00    4.0	"+"	""
2024-05-09 09:00    8.0	"-"	""
...
```

---

## 6. Parameter File (`PARAM.in`) Configuration Guide

Simulations are configured through the `PARAM.in` file (placed in the execution directory, e.g. `bin/PARAM.in`).

### Key Command Blocks

#### 1. Component Mapping & Time Settings
```text
#COMPONENTMAP
PS  0  0  1		Runs Plasmasphere (DGCPM) on 1 processor

#STARTTIME
2024			iYear
05			iMonth
09			iDay
00			iHour
00			iMinute
0			iSecond
0.0			FracSecond

#TIMEACCURATE
T			IsTimeAccurate
```

#### 2. Plasmasphere Component Block (`#BEGIN_COMP PS`)
```text
#BEGIN_COMP PS ---------------------------------------------------------------

#TIMESTEP
20.0			DtStep (seconds per update step)

#KP
file                    NameSourceKp (read Kp from file)
kp_test_input.dat       NameKpFile

#WEIMERIMF
imf_input.dat           Activates Weimer05 and specifies the IMF driver file

#OUTPUT
T			WriteStatic (writes grid coordinates)
T			WriteDynamic (writes time-dependent 2D density/potential)
600.			OutputInterval (seconds between output dumps, e.g. 10 min)
SHORT			OutputType (concise format)
DIPOLE			MagneticType

#MLTSLICE
4			nMltSlice (number of MLT radial cuts to extract)
300.0			DtMltSlice (extraction frequency in seconds)

#LOG
T			WriteLogFile

#END_COMP PS -----------------------------------------------------------------
```

#### 3. Simulation End Condition
```text
#STOP
-1			MaxIter (-1 = unlimited iterations)
86400.0			TimeMax (simulation duration in seconds, e.g. 86400s = 24h)

#END
```

### Pre-Configured Parameter Files Included
- **`bin/PARAM.in`**: Configured for May 2024 storm run with Weimer05.
- **`bin/PARAM.in.short_test`**: Fast 60-second execution test for immediate validation.
- **`Param/PARAM.in.weimer05_real_storm`**: Full 4-day May 2024 storm simulation.
- **`Param/PARAM.in.weimer05_synthetic`**: 24-hour synthetic IMF turning test.
- **`Param/PARAM.in.volland_stern`**: Classical Volland-Stern ($K_p$-only) baseline comparison.

---

## 7. Installation & Build Instructions

### 7.1 Prerequisites
DGCPM in SWMF requires standard Unix development tools:
- **Fortran Compiler**: `gfortran` (GCC $\ge 8$)
- **C/C++ Compiler**: `gcc`, `g++`
- **MPI Implementation**: OpenMPI or MPICH (`mpif90`, `mpicc`, `mpicxx`)
- **Utilities**: `make`, `perl`

On Debian/Ubuntu:
```bash
sudo apt update
sudo apt install build-essential gfortran gcc g++ libopenmpi-dev openmpi-bin perl make
```

### 7.2 One-Command Automated Setup (Recommended)
We provide an automated setup script that checks dependencies, installs compiler configurations, builds `SWMF.exe`, and links all runtime data tables:

```bash
git clone https://github.com/kolosnemeth2000/DGCPM_weimer05.git
cd DGCPM_weimer05
./setup_weimer_run.sh
```

### 7.3 Manual Step-by-Step Installation

1. **Configure SWMF**:
   ```bash
   ./Config.pl -install -compiler=gfortran
   ```
2. **Compile SWMF**:
   ```bash
   make -j4 SWMF
   ```
3. **Set Up Runtime Weimer05 Empirical Tables**:
   The Weimer05 backend requires four empirical data tables in an `EIE/` subdirectory in the run folder:
   ```bash
   mkdir -p bin/EIE
   cd bin/EIE
   ln -sf ../../util/EMPIRICAL/srcIE/data/W05scEpot.dat .
   ln -sf ../../util/EMPIRICAL/srcIE/data/SCHAtable.dat .
   ln -sf ../../util/EMPIRICAL/srcIE/data/W05scBndy.dat .
   ln -sf ../../util/EMPIRICAL/srcIE/data/hpke.noaa .
   cd ../..
   ```
4. **Ensure Runtime Driver Symlinks**:
   ```bash
   cd bin
   ln -sf ../GM/DGCPM/Input/imf_input.dat .
   ln -sf ../GM/DGCPM/Input/imf_test_input.dat .
   mkdir -p PS/Output PS/restartIN PS/restartOUT
   cd ..
   ```

---

## 8. Running Simulations

1. Enter the execution directory:
   ```bash
   cd bin
   ```
2. Execute the simulation using MPI (DGCPM standalone runs on 1 PE):
   ```bash
   mpirun -np 1 ./SWMF.exe
   ```
3. Monitor progress in terminal stdout:
   ```text
   DEBUG: entering #WEIMERIMF block parser
   DEBUG: read #WEIMERIMF line = imf_input.dat
   DEBUG: set_weimer05_potential after EIE_Initialize, iError = 0
   DEBUG: set_weimer05_potential after read_MHDIMF_Indices, iError = 0
   ...
   Finished Numerical Simulation
   Simulated time = 8.64000E+04 s
   ```

To run the fast 60-second sanity test:
```bash
cp PARAM.in.short_test PARAM.in
mpirun -np 1 ./SWMF.exe
```

---

## 9. Output Files & Data Visualization

Simulation results are written to `bin/PS/Output/`:

### Static Grid File: `dgcpm_static.dat`
Contains grid invariant geometry:
- $L$-shell coordinates, magnetic colatitude ($\theta$), and magnetic longitude ($\phi$).
- Flux tube volumes and magnetic field strengths.

### Dynamic Snapshot Files: `dgcpm_t<YYYYMMDD_HHMMSS>_<step>.dat`
Written at every `OutputInterval` (default: 600s / 10 min):
- **Equatorial Electron / Proton Density** ($N_{eq}$ in $\text{cm}^{-3}$).
- **Total Flux Tube Content** ($N_{total}$).
- **Electric Potential** ($\Phi$ in $\text{kV}$).
- **Convection and Corotation Velocities** ($V_r, V_\phi$).

### Diagnostic Completion Files
- **`bin/SWMF.SUCCESS`**: Created upon clean completion.
- **`bin/RESTART.out`**: Contains restart checkpoint metadata.

---

## 10. Code Architecture & Weimer Integration Details

For developers and researchers who wish to inspect or extend the integration, here is how the bridge was constructed:

```
┌─────────────────────────────────────────────────────────────────┐
│                          SWMF Core                              │
│                   CON/Control (CON_main.f90)                    │
└───────────────────────────────┬─────────────────────────────────┘
                                │ calls PS_init_session / PS_run
┌───────────────────────────────▼─────────────────────────────────┐
│                     DGCPM Component Wrapper                     │
│                GM/DGCPM/src/PS_wrapper.f90                      │
│   • Parses #WEIMERIMF and #EFIELDMODEL commands                 │
│   • Sets WeimerImfFile, WeimerInput='file', EFieldModel='weimer05'│
└───────────────────────────────┬─────────────────────────────────┘
                                │ invokes thermal loop
┌───────────────────────────────▼─────────────────────────────────┐
│                    DGCPM Physical Setup                         │
│                GM/DGCPM/src/dgcpm_setup.f90                     │
│   • Subroutine: set_weimer05_potential(Time, mgridpot)          │
│   • Calls EIE_Initialize('weimer05')                            │
│   • Calls read_MHDIMF_Indices(imf_input.dat) via DATAREAD       │
│   • Queries get_IMF_By, get_IMF_Bz, get_SW_V, get_SW_N         │
│   • Maps DGCPM (theta, phi) -> MLT and Magnetic Latitude        │
│   • Evaluates IO_GetPotential and transposes to mgridpot        │
└───────────────────────────────┬─────────────────────────────────┘
                                │ passes grid potential
┌───────────────────────────────▼─────────────────────────────────┐
│                DGCPM ExB Transport & Refilling                  │
│   • setpot computes electric-field gradients & ExB drifts       │
│   • Advection advances equatorial density and plume dynamics    │
└─────────────────────────────────────────────────────────────────┘
```

### Key Modified Files:
- `GM/DGCPM/src/PS_wrapper.f90`: Added parser commands and dispatch logic.
- `GM/DGCPM/src/ModMainDGCPM.f90`: Added global runtime Weimer variables.
- `GM/DGCPM/src/dgcpm_setup.f90`: Implemented `set_weimer05_potential`.
- `GM/DGCPM/src/dgcpm_main.f90`: Removed hardcoded `magconv` call so potential is updated via `thermal`.
- `GM/DGCPM/src/Makefile`: Added links to `-lEMPIRICALIE -lINDICES -lSHARE`.
- `util/EMPIRICAL/srcIE`: Hosts Weimer05 solver and empirical tables (`W05scEpot.dat`, `SCHAtable.dat`, `W05scBndy.dat`, `hpke.noaa`).
- `util/DATAREAD/srcIndices`: Hosts the time-dependent solar wind file reader (`read_MHDIMF_indices.f90`).

---

## 11. References & Citations

If you use this code in scientific publications, please cite the following foundational works:

1. **DGCPM**:
   - Ober, D. M., Horwitz, J. L., & Gallagher, D. L. (1997). Formation of density troughs embedded in the outer plasmasphere by subauroral ion drifts. *Journal of Geophysical Research: Space Physics*, 102(A7), 14595-14602.
2. **Weimer05 Electric Field Model**:
   - Weimer, D. R. (2005). Improved ionospheric electrodynamic models and application to calculating Joule heating rates. *Journal of Geophysical Research: Space Physics*, 110(A5), A05306.
3. **Space Weather Modeling Framework (SWMF)**:
   - Tóth, G., et al. (2005). Space Weather Modeling Framework: A new tool for cyberinfrastructure on space weather. *Journal of Geophysical Research: Space Physics*, 110(A12), A12226.
   - Tóth, G., et al. (2012). Adaptive numerical modeling of solar wind interaction with the Earth's magnetosphere. *Journal of Computational Physics*, 231(3), 870-903.
