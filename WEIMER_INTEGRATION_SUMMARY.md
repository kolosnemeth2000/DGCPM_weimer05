# Weimer05 Integration Summary for DGCPM in SWMF

Date: 2026-04-12

## Overview

This document summarizes the full integration path used to activate the Weimer05 empirical electric potential model for DGCPM in a PS-only SWMF run. The objective was to replace the default Volland-Stern-style convection driver in DGCPM with a modern, IMF and solar-wind-driven potential model while keeping execution inside the SWMF framework.

The integration now works end-to-end. A 24-hour simulation completed successfully, and Weimer05 was confirmed active at runtime.

## 1. The Origin: Where the Weimer model was found

The Weimer implementation used by SWMF was located in the empirical IE infrastructure under:

- util/EMPIRICAL/srcIE

Key files:

- util/EMPIRICAL/srcIE/EIE_Initialize.f90
- util/EMPIRICAL/srcIE/EIE_set_inputs.f90
- util/EMPIRICAL/srcIE/EIE_IoLibrary.f90
- util/EMPIRICAL/srcIE/ModWeimer05.f90
- util/EMPIRICAL/srcIE/data/W05scEpot.dat
- util/EMPIRICAL/srcIE/data/SCHAtable.dat
- util/EMPIRICAL/srcIE/data/W05scBndy.dat

These files form the model loader, runtime API, and coefficient/table data required for Weimer05.

## 2. Original Purpose: How Weimer was used before

In its original ecosystem, Weimer is part of the ionosphere-electrodynamics machinery used by SWMF components that need ionospheric potential patterns. The model calculates high-latitude electric potential as a function of upstream conditions and geophysical geometry, then exposes it through the EIE interface.

Conceptually, the model produced potential on an MLT-latitude grid, and that potential was consumed by component logic (for example IE-linked workflows or other components calling EIE library routines) to drive electrodynamic coupling.

In this integration, we did not re-implement Weimer. We reused the same EIE interface and model tables directly.

## 3. Inside the Routine: What Weimer05 looks like in code

The Weimer05 path is selected in EIE initialization logic:

- util/EMPIRICAL/srcIE/EIE_Initialize.f90

When the electric field model string is weimer05, EIE loads three model tables:

- W05scEpot.dat
- SCHAtable.dat
- W05scBndy.dat

The core implementation is in:

- util/EMPIRICAL/srcIE/ModWeimer05.f90

Structurally, the model does the following:

1. Reads precomputed coefficient tables.
2. Uses input drivers (IMF orientation and magnitude, solar-wind speed and density, dipole tilt, plus boundary handling) to build spherical harmonic-like coefficients.
3. Evaluates potential on requested magnetic latitude and MLT points.

Mathematically, it is an empirical basis-expansion model: coefficients are parameterized by driving conditions, then evaluated onto the requested ionospheric grid.

## 4. Dependencies: Physical parameters required by Weimer05

The active Weimer05 path depends on:

- IMF By
- IMF Bz
- Solar wind speed Vsw
- Solar wind density Nsw
- Time (for coordinate/tilt context in the EIE system)
- Requested output grid (MLT and magnetic latitude)

In DGCPM integration, these drivers are supplied through SWMF index interfaces and EIE IO setters each time the potential is computed.

## 5. The Bridge: How Weimer05 was channeled into DGCPM

The bridge consisted of four key changes.

### A. Runtime model switch in DGCPM state

Added Weimer configuration variables in:

- GM/DGCPM/src/ModMainDGCPM.f90

Including model mode and IMF file/fixed-value controls.

### B. Wrapper parser extensions

Extended parameter parsing in:

- GM/DGCPM/src/PS_wrapper.f90

Added commands:

- #EFIELDMODEL
- #WEIMER
- #WEIMERIMF

The #WEIMERIMF block reads a raw filename line and forces file-driven Weimer mode.

### C. New Weimer potential provider in DGCPM setup

Added routine:

- GM/DGCPM/src/dgcpm_setup.f90
- subroutine set_weimer05_potential

Flow inside the routine:

1. One-time EIE setup for weimer05.
2. Load MHD IMF file into index system (file mode) or set fixed single values.
3. Build DGCPM-to-EIE MLT and magnetic-latitude grids.
4. At runtime, read By/Bz/Vsw/Nsw for current time.
5. Call EIE APIs to produce potential on the requested grid.
6. Transfer resulting potential into DGCPM potential array.

### D. Main evolution path uses thermal-controlled model selection

Potential selection is now done inside the thermal path rather than a hard-coded pre-call in the legacy main loop. This ensures the selected model is applied consistently for each DGCPM update step.

## 6. The New Independence: Why IE coupling is no longer required

This workflow no longer requires a live GM-to-IE-to-PS coupling chain for electric potential input.

Reason:

- DGCPM now calls Weimer05 through EIE library interfaces locally.
- Upstream drivers are read from user-provided IMF/SW files through DATAREAD index routines.

What users must provide manually in PS-only runs:

1. A valid IMF/SW input file with required columns and time records.
2. PARAM.in blocks selecting Weimer and the IMF file.
3. Runtime EIE model data files available in launch directory via EIE symlinks.

## 7. Execution structure and required input format

### A. Required launch-folder EIE directory

If launching from bin, create:

- bin/EIE

Required files in bin/EIE (symlink or copy):

1. W05scEpot.dat
2. SCHAtable.dat
3. W05scBndy.dat
4. hpke.noaa

Source location found in repository:

- util/EMPIRICAL/srcIE/data

### B. Required PARAM.in structure in PS block

Minimal working pattern under #BEGIN_COMP PS:

- #EFIELDMODEL with value weimer05
- #WEIMERIMF followed by IMF file path on the next line

Example used successfully:

- #WEIMERIMF
- /home/kolos/Kolos_munka/DGCPM_v3/SWMF/GM/DGCPM/Input/imf_test_input.dat

### C. Required IMF file format

Reader used:

- util/DATAREAD/srcIndices/read_MHDIMF_indices.f90

Parsing behavior:

- Scans until it finds #START.
- Then reads one record per line with 15 columns:

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

A working test file was created at:

- GM/DGCPM/Input/imf_test_input.dat

## 8. Final result: How inputs are processed and used in DGCPM physics

Operationally, the final path is:

1. PARAM parser reads #WEIMERIMF and stores the IMF driver filename.
2. During first Weimer call, DGCPM initializes EIE in weimer05 mode and loads model tables.
3. DGCPM registers the IMF file with index I/O and reads time-dependent upstream data.
4. For each simulation time, DGCPM requests potential from Weimer05 on its mapped grid.
5. DGCPM inserts returned potential into its electric-potential field array.
6. Existing DGCPM field-gradient and ExB drift machinery uses that potential to advance plasma transport/filling/emptying dynamics.

So the Weimer model returns ionospheric electric potential values over MLT-latitude coordinates; DGCPM converts and interpolates those values into its native grid and uses them as the convection driver in the core plasma update.

## Closing note

The final run confirmation showed:

- Weimer IMF reader returned iError = 0
- Numerical simulation finished
- 24 hours of simulated time completed successfully

This validates both the model bridge and the runtime data plumbing for PS-only SWMF execution.
