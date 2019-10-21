#!/bin/bash
#
#   This script builds a python package using setup.py,
#   and then builds an rpm using the user created .spec file.
#
#   Not useful for packages that can do a simple python setup.py bdist_rpm
#

# Read the package name and version from setup.py
PACKAGE_NAME=$(grep -P "package_name = '.*'" setup.py | awk -F\' '{print $2}')

if [[ ${PACKAGE_NAME} == "" ]]
then
    echo "Could not find the package_name variable in setup.py."
    exit 1
fi

VERSION=$(grep "version='" setup.py | awk -F\' '{print $2}')

if [[ ${VERSION} == "" ]]
then
    echo "Unable to read the package's version from setup.py."
    exit 1
fi

# Set the build number
if [[ $# -ge 1 ]]
then
    BUILD_NUMBER="$1"
else
    BUILD_NUMBER="1"
fi

# The directory where rpmbuild throws everything
RPMBUILD_DIR=${HOME}/rpmbuild

# The rpm-build spec file
SPEC_FILE="${PACKAGE_NAME}.spec"

# Check if this is a valid build environment
can_build() {
    # Check if rpmbuild is available
    which rpmbuild 2>&1 > /dev/null
    if [[ $? != 0 ]]
    then
        echo "This script can only be run on systems with the rpmbuild package available."
        echo "Basically, that means you need to run this on a RedHat-based Linux distro."
        exit 1
    fi

    # Check if we have setuptools installed
    rpm -q python36-setuptools --quiet || rpm -q python3-setuptools
    if [[ $? != 0 ]]
    then
        echo "The python-setuptools rpm package must be installed."
        exit 1
    fi

    # We need to know if this is a VirtualBox vagrant instance
    # setup.py can't build when running in a VirtualBox shared folder
    # This is due to the fact that VirtualBox intentionally doesn't support hard links in shared folders.
    if [[ -e /etc/is_vbox_vagrant ]]
    then
        IS_VBOX=1
    else
        IS_VBOX=0
    fi

    if [[ ${IS_VBOX} == 1 ]]
    then
        mountpoint -q .
        if [[ $? == 0 ]]
        then
            echo "ERROR: It is impossible to build in a vagrant shared folder with the VirtualBox provider."
            echo "VirtualBox purposefully doesn't support hard links in shared folders."
            echo "Please copy the source code to a local folder on your vagrant box."
            exit 1
        fi
    fi
}

can_build

# Create the rpmbuild directories
# Creating SOURCES is the only one that *truly* matters.
# rpmbuild should automatically create the rest, but let's be safe.
if [[ ! -d ${RPMBUILD_DIR} || ! -d ${RPMBUILD_DIR}/SOURCES ]]
then
    mkdir -p ${RPMBUILD_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
fi

# Clean any previous builds
python3.6 setup.py clean

# Build the source distribution
python3.6 setup.py sdist

# Look for the compiled source
ls dist/${PACKAGE_NAME}*.tar.gz 2>&1 > /dev/null
if [[ $? == 0 ]]
then
    cp dist/${PACKAGE_NAME}*.tar.gz ${RPMBUILD_DIR}/SOURCES/
else
    echo "Source files were not found!"
    exit 1
fi

# Update the version in the spec file to match $VERSION
sed -i "s/\\(%global version \\).*$/\\1${VERSION}/g" ${SPEC_FILE}

# Build the rpm files
rpmbuild -ba --define "package_version ${VERSION}" --define "build_number ${BUILD_NUMBER}" ${SPEC_FILE}

if [[ $? != 0 ]]
then
    echo "rpmbuild failed!"
    exit 1
fi

# Locate the built rpm file and throw it in the current directory
RPM_FILE=$(find ${RPMBUILD_DIR}/RPMS -type f -name python3*-${PACKAGE_NAME}-${VERSION}-${BUILD_NUMBER}*.rpm -print -quit)
if [[ $? != 0 || ${RPM_FILE} == "" ]]
then
    echo "Could not locate the build rpm file!"
    exit 1
fi

cp ${RPM_FILE} .
exit 0

