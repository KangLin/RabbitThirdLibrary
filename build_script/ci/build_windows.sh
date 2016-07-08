#!/bin/bash
set -ev

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

if [ "$AUTOBUILD_COMPLER" = "MinGW" ]; then
    TARGET=windows_mingw 
    RABBITIM_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBITIM_MAKE_JOB_PARA" = "-j1" ];then
            RABBITIM_MAKE_JOB_PARA="-j2"
    fi
    export RABBITIM_MAKE_JOB_PARA
else 
    TARGET=windows_msvc
fi

export RABBITIM_USE_REPOSITORIES="FALSE"
#./build_webrtc.sh ${TARGET}

./build_openssl.sh ${TARGET} ${SOURCE_DIR}/openssl > /dev/null
./build_libcurl.sh ${TARGET} ${SOURCE_DIR}/curl #> /dev/null
./build_libvpx.sh ${TARGET} ${SOURCE_DIR}/libvpx > /dev/null
./build_libyuv.sh ${TARGET} ${SOURCE_DIR}/libyuv > /dev/null
./build_x264.sh ${TARGET} ${SOURCE_DIR}/libx264 > /dev/null
./build_ffmpeg.sh ${TARGET} ${SOURCE_DIR}/ffmpeg # > /dev/null

#./build_qxmpp.sh ${TARGET} ${SOURCE_DIR}/qxmpp > /dev/null
#./build_qzxing.sh ${TARGET} ${SOURCE_DIR}/qzxing > /dev/null
#./build_rabbitim.sh ${TARGET} ${SOURCE_DIR} qmake
