#!/bin/bash
set -ev

if [  "$BUILD_TARGERT" = "windows_mingw" ]; then
    export PATH=/C/Qt/Tools/mingw${toolchain_version}_32/bin:$PATH
    export LIBRARY_PATH=/C/Qt/Tools/mingw${toolchain_version}_32/i686-w64-mingw32/lib:$LIBRARY_PATH
    export LDLIBRARY_PATH=/C/Qt/Tools/mingw${toolchain_version}_32/i686-w64-mingw32/lib:$LIBRARY_PATH
fi

SOURCE_DIR=`pwd`
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
SCRIPT_DIR=${SOURCE_DIR}/build_script
if [ -d ${SOURCE_DIR}/ThirdLibrary/build_script ]; then
    SCRIPT_DIR=${SOURCE_DIR}/ThirdLibrary/build_script
fi
cd ${SCRIPT_DIR}
SOURCE_DIR=${SCRIPT_DIR}/../src

#下载预编译库
if [ -n "$DOWNLOAD_FILE" ]; then
   echo "wget -q -c -O ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip ${DOWNLOAD_FILE}"
   wget -q -c -O ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip ${DOWNLOAD_FILE}
   unzip -q ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip -d ${SCRIPT_DIR}/../${BUILD_TARGERT}
   if [ "$APPVEYOR_PROJECT_NAME" != "rabbitim-third-library" and  "$BUILD_TARGERT" != "windows_msvc" ]; then
       bash ${SCRIPT_DIR}/../${BUILD_TARGERT}/change_prefix.sh
   fi
fi

if [ "$BUILD_TARGERT" = "windows_mingw" ]; then
    RABBITIM_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBITIM_MAKE_JOB_PARA" = "-j1" ];then
            RABBITIM_MAKE_JOB_PARA="-j2"
    fi
    export RABBITIM_MAKE_JOB_PARA
fi
echo "RABBITIM_BUILD_THIRDLIBRARY:$RABBITIM_BUILD_THIRDLIBRARY"
for v in $RABBITIM_BUILD_THIRDLIBRARY
do
    if [ "$v" = "rabbitim" ]; then
        ./build_$v.sh ${BUILD_TARGERT}
    else
        ./build_$v.sh ${BUILD_TARGERT} ${SOURCE_DIR}/$v #> /dev/null
    fi
done
