#!/bin/bash
set -ev

if [ "$BUILD_TARGERT" = "windows_mingw" \
    -a -n "$APPVEYOR" ]; then
    export PATH=/C/Qt/Tools/mingw${TOOLCHAIN_VERSION}_32/bin:$PATH
    export USER_ROOT_PATH=/C/Qt/Tools/mingw${TOOLCHAIN_VERSION}_32
fi
export PKG_CONFIG=/c/msys64/mingw32/bin/pkg-config.exe
if [ "$BUILD_TARGERT" = "windows_msvc" ]; then
    export PATH=/C/Perl/bin:$PATH
    rm -fr /usr/include
fi

PROJECT_DIR=`pwd`
if [ -n "$1" ]; then
    PROJECT_DIR=$1
fi

SCRIPT_DIR=${PROJECT_DIR}/build_script
if [ -d ${PROJECT_DIR}/ThirdLibrary/build_script ]; then
    SCRIPT_DIR=${PROJECT_DIR}/ThirdLibrary/build_script
fi
cd ${SCRIPT_DIR}
SOURCE_DIR=${SCRIPT_DIR}/../src

#下载预编译库
if [ -n "$DOWNLOAD_FILE" ]; then
   echo "wget -q -c -O ${SCRIPT_DIR}/../${BUILD_TARGERT}.tar.gz ${DOWNLOAD_FILE}"
   wget -q -c -O ${SCRIPT_DIR}/../${BUILD_TARGERT}.tar.gz ${DOWNLOAD_FILE}
   md5sum ${SCRIPT_DIR}/../${BUILD_TARGERT}.tar.gz
   tar xzf ${SCRIPT_DIR}/../${BUILD_TARGERT}.tar.gz -C ${SCRIPT_DIR}/..
   if [ "$PROJECT_NAME" != "RabbitThirdLibrary" \
        -a "$BUILD_TARGERT_${RABBIT_ARCH}" != "windows_msvc_${RABBIT_ARCH}" \
        -a -f "${SCRIPT_DIR}/../${BUILD_TARGERT}_${RABBIT_ARCH}/change_prefix.sh" ]; then
       cd ${SCRIPT_DIR}/../$BUILD_TARGERT_${RABBIT_ARCH}
       
       if [ -n "$APPVEYOR" ]; then
           THIRDLIBRARY_DIR_PREFIX=/c/projects/rabbitthirdlibrary/build_script/../${BUILD_TARGERT}_${RABBIT_ARCH}
       else
           THIRDLIBRARY_DIR_PREFIX=/home/travis/build/KangLin/RabbitThirdLibrary/unix
       fi
       
       echo "bash ${SCRIPT_DIR}/../${BUILD_TARGERT}_${RABBIT_ARCH}/change_prefix.sh $THIRDLIBRARY_DIR_PREFIX `pwd`"
       bash ${SCRIPT_DIR}/../${BUILD_TARGERT}_${RABBIT_ARCH}/change_prefix.sh $THIRDLIBRARY_DIR_PREFIX `pwd`
       cat ${SCRIPT_DIR}/../${BUILD_TARGERT}_${RABBIT_ARCH}/lib/pkgconfig/libcurl.pc
       
       cd ${SCRIPT_DIR}
   fi
fi

if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${SCRIPT_DIR}/../Tools/android-sdk
    export ANDROID_NDK_ROOT=${SCRIPT_DIR}/../Tools/android-ndk
    if [ -z "$APPVEYOR" ]; then
        export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
    fi
    export QT_ROOT=${SCRIPT_DIR}/../Tools/Qt/${QT_VERSION}/${QT_VERSION_DIR}/android_armv7
    if [ "${QT_VERSION}" = "5.2.1" ]; then
        export QT_ROOT=${SCRIPT_DIR}/../Tools/Qt/${QT_VERSION}/android_armv7
    fi
    export PATH=${SCRIPT_DIR}/../Tools/apache-ant/bin:$JAVA_HOME:$PATH
fi
if [ "$BUILD_TARGERT" != "windows_msvc" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
            RABBIT_MAKE_JOB_PARA="-j2"
    fi
    export RABBIT_MAKE_JOB_PARA
fi

echo "---------------------------------------------------------------------------"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "QT_BIN:$QT_BIN"
echo "QT_ROOT:$QT_ROOT"
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "PKG_CONFIG_SYSROOT_DIR:$PKG_CONFIG_SYSROOT_DIR"
echo "PATH=$PATH"
echo "RABBIT_BUILD_THIRDLIBRARY:$RABBIT_BUILD_THIRDLIBRARY"
echo "---------------------------------------------------------------------------"

for v in $RABBIT_BUILD_THIRDLIBRARY
do
    if [ "$v" = "rabbitim" ]; then
        bash ./build_$v.sh ${BUILD_TARGERT} # > /dev/null
    else
        bash ./build_$v.sh ${BUILD_TARGERT} ${SOURCE_DIR}/$v #> /dev/null
    fi
done
