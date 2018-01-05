#注意：修改后的本文件不要上传代码库中

#bash用法：  
#   在用一sh进程中执行脚本script.sh:
#   source script.sh
#   . script.sh
#   注意这种用法，script.sh开头一行不能包含 #!/bin/sh
#   相当于包含关系

#   新建一个sh进程执行脚本script.sh:
#   sh script.sh
#   ./script.sh
#   注意这种用法，script.sh开头一行必须包含 #!/bin/sh  

#需要设置下面变量，也可以把它们设置在环境变量中：  
#export JAVA_HOME="/C/Program Files/Java/jdk1.7.0_51"             #指定 jdk 根目录  
#export ANDROID_SDK_ROOT=/D/software/android-sdk-windows     #指定 android sdk 根目录,在msys2下需要注意路径符号："/"  
#export ANDROID_NDK_ROOT=/D/software/android-ndk-r10e   #指定 android ndk 根目录  
export ANDROID_NDK=$ANDROID_NDK_ROOT            #指定 android ndk 根目录  
export ANDROID_SDK=$ANDROID_SDK_ROOT
#export ANDROID_NDK_ABI_NAME=armeabi-v7a #armeabi,armeabi-v7a,arm64-v8a,mips,mips64,x86,x86_64

#ANT=/usr/bin/ant         #ant 程序  
if [ -z "$QT_ROOT" ]; then
    QT_VERSION=5.9.2
    QT_ROOT=/c/Qt/Qt${QT_VERSION}/${QT_VERSION}/android_armv7      #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/android/qt  
fi
if [ -z "$RABBIT_CLEAN" ]; then
    RABBIT_CLEAN=TRUE #编译前清理  
fi
RABBIT_BUILD_STATIC="static" #设置编译静态库，注释掉，则为编译动态库  
#RABBIT_USE_REPOSITORIES="FALSE" #下载指定的压缩包。省略，则下载开发库。  
#RABBIT_BUILD_TOOLCHAIN_VERSION=4.8   #工具链版本号,默认 4.8  
#RABBIT_BUILD_PLATFORMS_VERSION=16   #android ndk api (平台)版本号,默认 18
if [ -z "${RABBIT_MAKE_JOB_PARA}" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
        RABBIT_MAKE_JOB_PARA=
    fi
fi

if [ -z "$ANDROID_NDK_ROOT" -o -z "$ANDROID_NDK" -o -z "$ANDROID_SDK" -o -z "$ANDROID_SDK_ROOT"	-o -z "$JAVA_HOME" ]; then
    echo "Please set ANDROID_NDK_ROOT and ANDROID_NDK and ANDROID_SDK and ANDROID_SDK_ROOT and JAVA_HOME"
    exit 1
fi

if [ -z "${RABBIT_ARCH}" ]; then
    RABBIT_ARCH=arm #arm,arm64,mips,mips64,x86,x86_64
fi

if [ -z "$RABBIT_CONFIG" ]; then
    RABBIT_CONFIG=Release
fi

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    RABBIT_BUILD_PREFIX=`pwd`/../${RABBIT_BUILD_TARGERT}    #修改这里为安装前缀  
    RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}${RABBIT_TOOLCHAIN_VERSION}_${RABBIT_ARCH}_qt${QT_VERSION}_${RABBIT_CONFIG}
fi
if [ ! -d ${RABBIT_BUILD_PREFIX} ]; then
    mkdir -p ${RABBIT_BUILD_PREFIX}
fi

if [ -z "$RABBIT_USE_REPOSITORIES" ]; then
    RABBIT_USE_REPOSITORIES="TRUE" #下载开发库。省略，则下载指定的压缩包  
fi

#设置qt安装位置
if [ -z "$QT_ROOT" -a -d "${RABBIT_BUILD_PREFIX}/qt" ]; then
    QT_ROOT=${RABBIT_BUILD_PREFIX}/qt
fi
QMAKE=qmake
if [ -n "${QT_ROOT}" ]; then
    QT_BIN=${QT_ROOT}/bin       #设置用于 android 平台编译的 qt bin 目录  
    QMAKE=${QT_BIN}/qmake       #设置用于 unix 平台编译的 QMAKE。
                            #这里设置的是自动编译时的配置，你需要修改为你本地qt编译环境的配置.
fi

MAKE="make ${RABBIT_MAKE_JOB_PARA}"
#自动判断主机类型，目前只做了linux、windows判断
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        RABBIT_BUILD_HOST="windows"
        #RABBIT_CMAKE_MAKE_PROGRAM=$ANDROID_NDK/prebuilt/${RABBIT_BUILD_HOST}/bin/make #这个用不着，只有在windows命令行下才有用 
        RABBITIM_GENERATORS="MSYS Makefiles"
        ;;
    Linux* | Unix*)
        RABBIT_BUILD_HOST="linux-`uname -m`"    #windows、linux-x86_64
        RABBITIM_GENERATORS="Unix Makefiles" 
        ;;
    *)
    echo "Please set RABBIT_BUILD_HOST. see build_envsetup_android.sh"
    return 2
    ;;
esac


if [ -z "${RABBIT_BUILD_TOOLCHAIN_VERSION}" ]; then
    RABBIT_BUILD_TOOLCHAIN_VERSION=4.9  #工具链版本号  
fi
if [ -z "${RABBIT_BUILD_PLATFORMS_VERSION}" ]; then
    RABBIT_BUILD_PLATFORMS_VERSION=18    #android ndk api (平台)版本号  
fi

if [ "${RABBIT_ARCH}" = "x86" -o "${RABBIT_ARCH}" = "x86_64" ]; then
    export ANDROID_TOOLCHAIN_NAME=${RABBIT_ARCH}-${RABBIT_BUILD_TOOLCHAIN_VERSION}
    RABBIT_BUILD_CROSS_ROOT=$ANDROID_NDK_ROOT/toolchains/${RABBIT_ARCH}-${RABBIT_BUILD_TOOLCHAIN_VERSION}/prebuilt/${RABBIT_BUILD_HOST}
    #交叉编译前缀 
    if [ "${RABBIT_ARCH}" = "x86_64" ]; then
        export ANDROID_ABI="x86_64"
        RABBIT_BUILD_CROSS_PREFIX=${RABBIT_BUILD_CROSS_ROOT}/bin/x86_64-linux-android-
    else
        export ANDROID_ABI="x86"
        RABBIT_BUILD_CROSS_PREFIX=${RABBIT_BUILD_CROSS_ROOT}/bin/i686-linux-android-
    fi
    #交叉编译平台的 sysroot 
    RABBIT_BUILD_CROSS_SYSROOT=$ANDROID_NDK_ROOT/platforms/android-${RABBIT_BUILD_PLATFORMS_VERSION}/arch-${RABBIT_ARCH}
    ANDROID_NDK_ABI_NAME=${RABBIT_ARCH}
    if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
        if [ "${RABBIT_ARCH}" = "x86_64" ]; then
            RABBIT_BUILD_CROSS_HOST=x86_64-linux-android
        else
            RABBIT_BUILD_CROSS_HOST=i686-linux-android
        fi
    fi
elif [ "${RABBIT_ARCH}" = "arm" ]; then
    export ANDROID_ABI="armeabi-v7a with NEON"
    export ANDROID_TOOLCHAIN_NAME=arm-linux-androideabi-${RABBIT_BUILD_TOOLCHAIN_VERSION}
    RABBIT_BUILD_CROSS_ROOT=$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-${RABBIT_BUILD_TOOLCHAIN_VERSION}/prebuilt/${RABBIT_BUILD_HOST}
    #交叉编译前缀 
    RABBIT_BUILD_CROSS_PREFIX=${RABBIT_BUILD_CROSS_ROOT}/bin/arm-linux-androideabi-
    #交叉编译平台的 sysroot 
    RABBIT_BUILD_CROSS_SYSROOT=$ANDROID_NDK_ROOT/platforms/android-${RABBIT_BUILD_PLATFORMS_VERSION}/arch-${RABBIT_ARCH}
    ANDROID_NDK_ABI_NAME=armeabi
    if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
        RABBIT_BUILD_CROSS_HOST=arm-linux-androideabi
    fi
fi

RABBIT_BUILD_CROSS_STL=${ANDROID_NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/${RABBIT_BUILD_TOOLCHAIN_VERSION}
RABBIT_BUILD_CROSS_STL_INCLUDE=${RABBIT_BUILD_CROSS_STL}/include
RABBIT_BUILD_CROSS_STL_LIBS=${RABBIT_BUILD_CROSS_STL}/libs
RABBIT_BUILD_CROSS_STL_INCLUDE_FLAGS="-I${RABBIT_BUILD_CROSS_STL_INCLUDE} -I${RABBIT_BUILD_CROSS_STL_LIBS}/${ANDROID_NDK_ABI_NAME}/include"

export ANDROID_API_VERSION=android-${RABBIT_BUILD_PLATFORMS_VERSION}
export ANDROID_NATIVE_API_LEVEL=${ANDROID_API_VERSION}
export PATH=${QT_BIN}:$PATH
#pkg-config帮助文档：http://linux.die.net/man/1/pkg-config
if [ -z "$PKG_CONFIG" ]; then
    export PKG_CONFIG=pkg-config 
fi
export PKG_CONFIG_PATH=${RABBIT_BUILD_PREFIX}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH}
export PKG_CONFIG_SYSROOT_DIR=${RABBIT_BUILD_PREFIX}

echo "---------------------------------------------------------------------------"
echo "ANDROID_SDK:$ANDROID_SDK"
echo "ANDROID_SDK_ROOT:$ANDROID_SDK_ROOT"
echo "ANDROID_NDK:$ANDROID_NDK"
echo "ANDROID_NDK_ROOT:$ANDROID_NDK_ROOT"
echo "ANDROID_NDK_ABI_NAME:$ANDROID_NDK_ABI_NAME"
echo "RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "RABBIT_BUILD_TOOLCHAIN_VERSION:$RABBIT_BUILD_TOOLCHAIN_VERSION"
echo "RABBIT_BUILD_PLATFORMS_VERSION:$RABBIT_BUILD_PLATFORMS_VERSION"
echo "RABBIT_BUILD_CROSS_ROOT:$RABBIT_BUILD_CROSS_ROOT"
echo "RABBIT_BUILD_CROSS_STL:$RABBIT_BUILD_CROSS_STL"
echo "ANDROID_ABI:$ANDROID_ABI"
echo "ANDROID_TOOLCHAIN_NAME:$ANDROID_TOOLCHAIN_NAME"
echo "ANDROID_API_VERSION,ANDROID_NATIVE_API_LEVEL:$ANDROID_API_VERSION"
echo "QT_ROOT:$QT_ROOT"
echo "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "PKG_CONFIG_SYSROOT_DIR:$PKG_CONFIG_SYSROOT_DIR"
echo "---------------------------------------------------------------------------"
