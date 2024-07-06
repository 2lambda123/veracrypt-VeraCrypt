#!/bin/sh
#
# Copyright (c) 2013-2024 IDRIX
# Governed by the Apache License 2.0 the full text of which is contained
# in the file License.txt included in VeraCrypt binary and source
# code distribution packages.
#

# Errors should cause script to exit
set -e

# Absolute path to this script
export SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
export SCRIPTPATH=$(dirname "$SCRIPT")
# Source directory which contains the Makefile
export SOURCEPATH=$(readlink -f "$SCRIPTPATH/..")
# Directory where the VeraCrypt has been checked out
export PARENTDIR=$(readlink -f "$SCRIPTPATH/../../..")

# Check if wxWidgets-3.2.5 exists in PARENTDIR; if not, use /tmp
if [ ! -d "$PARENTDIR/wxWidgets-3.2.5" ]; then
    export PARENTDIR="/tmp"
fi

# The sources of wxWidgets 3.2.5 must be extracted to the parent directory
export WX_ROOT=$PARENTDIR/wxWidgets-3.2.5

# Exit with error if wxWidgets is not found
if [ ! -d "$WX_ROOT" ]; then
    echo "Error: wxWidgets-3.2.5 not found in either the default PARENTDIR or /tmp. Exiting."
    exit 1
fi

echo "Using wxWidgets sources in $WX_ROOT"

cd $SOURCEPATH

echo "Building GUI version of VeraCrypt for RPM using wxWidgets static libraries"

# This will be the temporary wxWidgets directory
export WX_BUILD_DIR=$PARENTDIR/wxBuildGui

# Check if wx-config exists in WX_BUILD_DIR
if [ -L "${WX_BUILD_DIR}/wx-config" ]; then
    echo "wx-config already exists in ${WX_BUILD_DIR}. Skipping wxbuild."
else
    make WXSTATIC=1 wxbuild || exit 1
    ln -s $WX_BUILD_DIR/lib  $WX_BUILD_DIR/lib64
fi

make WXSTATIC=1 clean 				|| exit 1
make WXSTATIC=1 					|| exit 1
make WXSTATIC=1 install DESTDIR="$PARENTDIR/VeraCrypt_Setup/GUI"	|| exit 1

echo "Building console version of VeraCrypt for RPM using wxWidgets static libraries"

# This is to avoid " Error: Unable to initialize GTK+, is DISPLAY set properly?" 
# when building over SSH without X11 Forwarding
# export DISPLAY=:0.0

# This will be the temporary wxWidgets directory
export WX_BUILD_DIR=$PARENTDIR/wxBuildConsole

# Check if wx-config exists in WX_BUILD_DIR
if [ -L "${WX_BUILD_DIR}/wx-config" ]; then
    echo "wx-config already exists in ${WX_BUILD_DIR}. Skipping wxbuild."
else
    make WXSTATIC=1 NOGUI=1 wxbuild || exit 1
    ln -s $WX_BUILD_DIR/lib  $WX_BUILD_DIR/lib64
fi

make WXSTATIC=1 NOGUI=1 clean 				|| exit 1
make WXSTATIC=1 NOGUI=1 					|| exit 1
make WXSTATIC=1 NOGUI=1 install DESTDIR="$PARENTDIR/VeraCrypt_Setup/Console"	|| exit 1

echo "Creating VeraCrypt RPM packages "

# -DCPACK_RPM_PACKAGE_DEBUG=TRUE for debugging cpack RPM
# -DCPACK_RPM_PACKAGE_DEBUG=TRUE for debugging cpack RPM

mkdir -p $PARENTDIR/VeraCrypt_Packaging/GUI
mkdir -p $PARENTDIR/VeraCrypt_Packaging/Console

# wxWidgets was built using native GTK version
cmake -H$SCRIPTPATH -B$PARENTDIR/VeraCrypt_Packaging/GUI -DVERACRYPT_BUILD_DIR="$PARENTDIR/VeraCrypt_Setup/GUI" -DNOGUI=FALSE || exit 1		
cpack --config $PARENTDIR/VeraCrypt_Packaging/GUI/CPackConfig.cmake || exit 1
cmake -H$SCRIPTPATH -B$PARENTDIR/VeraCrypt_Packaging/Console -DVERACRYPT_BUILD_DIR="$PARENTDIR/VeraCrypt_Setup/Console" -DNOGUI=TRUE || exit 1
cpack --config $PARENTDIR/VeraCrypt_Packaging/Console/CPackConfig.cmake|| exit 1
