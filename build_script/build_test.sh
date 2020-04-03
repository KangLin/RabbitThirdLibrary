#!/bin/bash
set -e

HELP_STRING="Usage $0 PLATFORM(android|windows_msvc|windows_mingw|unix) [SOURCE_CODE_ROOT_DIRECTORY]"

case $1 in
    android|windows_msvc|windows_mingw|unix)
        BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    exit 1
    ;;
esac

RABBIT_BUILD_SOURCE_CODE=$2
echo ". `pwd`/build_envsetup_${BUILD_TARGERT}.sh"
. `pwd`/build_envsetup_${BUILD_TARGERT}.sh

cd ${RABBIT_BUILD_PREFIX}
ls
echo "${BUILD_TARGERT} $RABBIT_NUMBER" > test_${BUILD_TARGERT}_${RABBIT_NUMBER}.txt
ls
mkdir -p ${BUILD_TARGERT}_${RABBIT_NUMBER}
cd ${BUILD_TARGERT}_${RABBIT_NUMBER}
echo "${BUILD_TARGERT} $RABBIT_NUMBER" > test_${BUILD_TARGERT}_${RABBIT_NUMBER}.txt
ls
