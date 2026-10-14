#!/bin/bash
# ==============================================================================
# Setup and Build Script for DGCPM with Weimer05 Electric Field Model in SWMF
# Repository: https://github.com/kolosnemeth2000/DGCPM_weimer05
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================================="
echo " Setting up DGCPM with Weimer05 in SWMF"
echo " Working directory: $SCRIPT_DIR"
echo "======================================================================="

# 1. Check prerequisites
echo ""
echo "--> [1/5] Checking system prerequisites..."
MISSING=""
for cmd in gfortran gcc mpif90 mpicc perl make; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if [ -n "$MISSING" ]; then
    echo "ERROR: Missing required build tools:$MISSING"
    echo "Please install them via your package manager (e.g. sudo apt install gfortran gcc libopenmpi-dev openmpi-bin perl make)"
    exit 1
fi
echo "    All required build tools found."

# 2. Configure SWMF
echo ""
echo "--> [2/5] Configuring SWMF with gfortran..."
./Config.pl -install -compiler=gfortran

# 3. Build SWMF executable
echo ""
echo "--> [3/5] Building SWMF executable (make -j4 SWMF)..."
make -j4 SWMF

# 4. Set up runtime environment and Weimer tables
echo ""
echo "--> [4/5] Preparing runtime directory and Weimer05 data tables..."
mkdir -p bin/EIE
mkdir -p bin/PS/Output bin/PS/restartIN bin/PS/restartOUT

cd bin/EIE
ln -sf ../../util/EMPIRICAL/srcIE/data/W05scEpot.dat .
ln -sf ../../util/EMPIRICAL/srcIE/data/SCHAtable.dat .
ln -sf ../../util/EMPIRICAL/srcIE/data/W05scBndy.dat .
ln -sf ../../util/EMPIRICAL/srcIE/data/hpke.noaa .
cd "$SCRIPT_DIR"

cd bin
ln -sf ../GM/DGCPM/Input/imf_input.dat .
ln -sf ../GM/DGCPM/Input/imf_test_input.dat .
cd "$SCRIPT_DIR"

# 5. Done
echo ""
echo "--> [5/5] Setup complete!"
echo "======================================================================="
echo " SWMF with DGCPM & Weimer05 is ready to run!"
echo ""
echo " To run a simulation:"
echo "   cd bin"
echo "   mpirun -np 1 ./SWMF.exe"
echo ""
echo " Simulation output files will be written to: bin/PS/Output/"
echo "======================================================================="
