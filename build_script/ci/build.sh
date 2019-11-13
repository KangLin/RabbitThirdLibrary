#!/bin/bash
set -e

#TODO:修改数组，修改完后，再修改appveyor.yml中的 RABBIT_QT_NUMBER 为QT开始的数组索引  
RABBIT_LIBRARYS[0]="change_prefix zlib expat libgpx openssl libsodium libcurl libqrencode"
RABBIT_LIBRARYS[1]="boost"
RABBIT_LIBRARYS[2]="libpng jpeg libgif libtiff freetype libyuv libvpx libopus x264 speex ffmpeg"
RABBIT_LIBRARYS[3]="opencv dlib" # geos gdal"
#RABBIT_LIBRARYS[3]="osg"
#RABBIT_LIBRARYS[4]="OsgQt osgearth "
RABBIT_LIBRARYS[4]="qxmpp qzxing"

export PATH=/usr/bin:$PATH
if [ "$BUILD_TARGERT" = "windows_mingw" \
    -a -n "$APPVEYOR" ]; then
    export RABBIT_TOOLCHAIN_ROOT=/C/Qt/Tools/mingw${RABBIT_TOOLCHAIN_VERSION}
    export PATH="${RABBIT_TOOLCHAIN_ROOT}/bin:/usr/bin:/c/Tools/curl/bin:/c/Program Files (x86)/CMake/bin"
fi

TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        export PKG_CONFIG=/c/msys64/mingw32/bin/pkg-config.exe
        ;;
    Linux* | Unix*)
    ;;
    *)
    ;;
esac
if [ "$BUILD_TARGERT" = "windows_msvc" ]; then
    export PATH=/C/Perl/bin:$PATH
    rm -fr /usr/include
fi

PROJECT_DIR=`pwd`
if [ -n "$1" ]; then
    PROJECT_DIR=$1
fi
echo "PROJECT_DIR:${PROJECT_DIR}"
SCRIPT_DIR=${PROJECT_DIR}/build_script
if [ -d ${PROJECT_DIR}/ThirdLibrary/build_script ]; then
    SCRIPT_DIR=${PROJECT_DIR}/ThirdLibrary/build_script
fi
cd ${SCRIPT_DIR}
SOURCE_DIR=${SCRIPT_DIR}/../src

if [ -z "${LIBRARY_NUMBER}" ]; then
    LIBRARY_NUMBER=0
fi

#下载预编译库
if [ -n "$DOWNLOAD_URL" ]; then
    wget -c -q -O ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip ${DOWNLOAD_URL}
fi

export RABBIT_BUILD_PREFIX=${SCRIPT_DIR}/../build #${BUILD_TARGERT}${RABBIT_TOOLCHAIN_VERSION}_${RABBIT_ARCH}_qt${QT_VERSION}_${RABBIT_CONFIG}
if [ ! -d ${RABBIT_BUILD_PREFIX} ]; then
    mkdir -p ${RABBIT_BUILD_PREFIX}
fi
cd ${RABBIT_BUILD_PREFIX}
export RABBIT_BUILD_PREFIX=`pwd`
cd ${SCRIPT_DIR}
if [ -f ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip ]; then
    echo "unzip -q -d ${RABBIT_BUILD_PREFIX} ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip"
    unzip -q -d ${RABBIT_BUILD_PREFIX} ${SCRIPT_DIR}/../${BUILD_TARGERT}.zip
    if [ "$PROJECT_NAME" != "RabbitThirdLibrary" \
        -a "$BUILD_TARGERT" != "windows_msvc" \
        -a -f "${RABBIT_BUILD_PREFIX}/change_prefix.sh" ]; then

        cd ${RABBIT_BUILD_PREFIX}
        cat lib/pkgconfig/zlib.pc
        cat change_prefix.sh
        echo "bash change_prefix.sh"
        bash change_prefix.sh
        cat lib/pkgconfig/zlib.pc
        cd ${SCRIPT_DIR}
    fi
fi

TOOLS_DIR=${SCRIPT_DIR}/../Tools
if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    if [ -n "$APPVEYOR" ]; then
        export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
        export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-sdk/ndk-bundle
    fi
    if [ "$TRAVIS" = "true" ]; then
        export JAVA_HOME=${TOOLS_DIR}/android-studio/jre
        #export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
    fi
    case $BUILD_ARCH in
        arm*)
            export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_armv7
            ;;
        x86)
        export QT_ROOT=${TOOLS_DIR}/Qt/${QT_VERSION}/${QT_VERSION}/android_x86
        ;;
    esac
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME:$PATH
    export ANDROID_SDK=${ANDROID_SDK_ROOT}
    export ANDROID_NDK=${ANDROID_NDK_ROOT}
fi

if [ "${BUILD_TARGERT}" = "unix" ]; then
    if [ "$DOWNLOAD_QT" = "TRUE" ]; then
        QT_DIR=${TOOLS_DIR}/Qt/${QT_VERSION}
        export QT_ROOT=${QT_DIR}/${QT_VERSION}/gcc_64
    else
        #source /opt/qt${QT_VERSION_DIR}/bin/qt${QT_VERSION_DIR}-env.sh
        export QT_ROOT=/opt/qt${QT_VERSION_DIR}
    fi
    export PATH=$QT_ROOT/bin:$PATH
    export LD_LIBRARY_PATH=$QT_ROOT/lib/i386-linux-gnu:$QT_ROOT/lib:$LD_LIBRARY_PATH
    export PKG_CONFIG_PATH=$QT_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH
fi

if [ "$BUILD_TARGERT" != "windows_msvc" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
        RABBIT_MAKE_JOB_PARA="-j2"
    fi
fi

echo "---------------------------------------------------------------------------"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "QT_BIN:$QT_BIN"
echo "QT_ROOT:$QT_ROOT"
echo "PKG_CONFIG:$PKG_CONFIG"
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "PKG_CONFIG_SYSROOT_DIR:$PKG_CONFIG_SYSROOT_DIR"
echo "PATH=$PATH"
echo "RABBIT_BUILD_THIRDLIBRARY:$RABBIT_BUILD_THIRDLIBRARY"
echo "SCRIPT_DIR:$SCRIPT_DIR"
echo "---------------------------------------------------------------------------"

cd ${SCRIPT_DIR}

if [ "$PROJECT_NAME" = "rabbitim" ]; then
    echo "bash ./build_rabbitim.sh ${BUILD_TARGERT} $PROJECT_DIR $CMAKE"
    bash ./build_rabbitim.sh ${BUILD_TARGERT} $CMAKE $PROJECT_DIR
    exit 0
fi

for v in ${RABBIT_LIBRARYS[$RABBIT_NUMBER]}
do
    if [ "$v" = "rabbitim" ]; then
        bash ./build_$v.sh ${BUILD_TARGERT} # > /dev/null
    else 
            if [ "$APPVEYOR" = "True" ]; then
                bash ./build_$v.sh ${BUILD_TARGERT} ${SOURCE_DIR}/$v
            else
                bash ./build_$v.sh ${BUILD_TARGERT} ${SOURCE_DIR}/$v > /dev/null
            fi
        
    fi
done
