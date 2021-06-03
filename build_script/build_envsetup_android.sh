#注意：修改后的本文件不要上传代码库中

#bash用法:
#   在用一sh进程中执行脚本script.sh:
#   source script.sh
#   . script.sh
#   注意这种用法，script.sh开头一行不能包含 #!/bin/sh
#   相当于包含关系

#   新建一个sh进程执行脚本script.sh:
#   sh script.sh
#   ./script.sh
#   注意这种用法，script.sh开头一行必须包含 #!/bin/sh

#ANDROID_ABI: 可取下列值： 目标 ABI。如果未指定目标 ABI，则 CMake 默认使用 armeabi-v7a
#有效的目标名称为：
#    armeabi：带软件浮点运算并基于 ARMv5TE 的 CPU。
#    armeabi-v7a：带硬件 FPU 指令 (VFPv3_D16) 并基于 ARMv7 的设备。
#    armeabi-v7a with NEON：与 armeabi-v7a 相同，但启用 NEON 浮点指令。这相当于设置 -DANDROID_ABI=armeabi-v7a 和 -DANDROID_ARM_NEON=ON。
#    arm64-v8a：ARMv8 AArch64 指令集。
#    x86：IA-32 指令集。
#    x86_64 - 用于 x86-64 架构的指令集。
#ANDROID_PLATFORM: 如需平台名称和对应 Android 系统映像的完整列表，请参阅 Android NDK 原生 API
#ANDROID_ARM_MODE
#ANDROID_ARM_NEON
#ANDROID_STL:指定 CMake 应使用的 STL。默认情况下，CMake 使用 c++_static。

# ANDROID_NDK_HOST:
# QT_ROOT:
# BUILD_ARCH:
# RABBIT_CLEAN:
# RABBIT_BUILD_STATIC:
# RABBIT_USE_REPOSITORIES:

#需要设置下面变量，也可以把它们设置在环境变量中：  
#export JAVA_HOME="/C/Program Files/Java/jdk1.7.0_51"        #指定 jdk 根目录  
#export ANDROID_SDK_ROOT=/D/software/android-sdk-windows     #指定 android sdk 根目录,在msys2下需要注意路径符号："/"  
#export ANDROID_NDK_ROOT=/D/software/android-ndk-r10e        #指定 android ndk 根目录  

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

if [ -z "$ANDROID_NDK_ROOT" -a -z "$ANDROID_NDK" ]; then
    export ANDROID_NDK_ROOT=/d/software/android-sdk/ndk-bundle
fi
if [ -z "$ANDROID_SDK_ROOT" -a -z "$ANDROID_SDK" ]; then
    export ANDROID_SDK_ROOT=/d/software/android-sdk
fi
if [ -n "$ANDROID_SDK" -a -z "$ANDROID_SDK_ROOT" ]; then
    export ANDROID_SDK_ROOT=$ANDROID_SDK
fi
if [ -n "$ANDROID_NDK" -a -z "$ANDROID_NDK_ROOT" ]; then
    export ANDROID_NDK_ROOT=$ANDROID_NDK
fi
export ANDROID_NDK=$ANDROID_NDK_ROOT     #指定 android ndk 根目录  
export ANDROID_SDK=$ANDROID_SDK_ROOT
export ANDROID_NDK_HOME=$ANDROID_NDK     #openssl需要  

if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=/C/android-studio/jre
fi

#设置ndk。32位的是windows；64位的是windows-x86_64
export ANDROID_NDK_HOST=windows-x86_64

#ANT=/usr/bin/ant         #ant 程序  

if [ -z "$RABBIT_CLEAN" ]; then
    RABBIT_CLEAN=TRUE #编译前清理  
fi
#RABBIT_BUILD_STATIC="static" #设置编译静态库，注释掉，则为编译动态库
#RABBIT_USE_REPOSITORIES="TRUE" #下载指定的压缩包。省略，则下载开发库。  
#TOOLCHAIN_VERSION=4.8   #工具链版本号,默认 4.9  
if [ -z "${BUILD_JOB_PARA}" ]; then
    BUILD_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$BUILD_JOB_PARA" = "-j1" ];then
        BUILD_JOB_PARA=
    fi
fi

if [ -z "$ANDROID_NDK_ROOT" -o -z "$ANDROID_NDK" -o -z "$ANDROID_SDK" -o -z "$ANDROID_SDK_ROOT"	-o -z "$JAVA_HOME" ]; then
    echo "Please set ANDROID_NDK_ROOT and ANDROID_NDK and ANDROID_SDK and ANDROID_SDK_ROOT and JAVA_HOME"
    exit 1
fi

if [ -z "${BUILD_ARCH}" ]; then
    BUILD_ARCH=arm #armv7,arm64,mips,mips64,x86,x86_64
fi

#需要设置下面变量：
if [ -z "$QT_ROOT" -a -z "$APPVEYOR" -a -z "$TRAVIS" ]; then
    QT_VERSION=5.12.11
    if [ "${BUILD_ARCH}" = "arm" ]; then
        if [ "`uname -s`" = "Linux" ]; then
            QT_ROOT=/opt/Qt${QT_VERSION}/${QT_VERSION}/android_armv7 #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/android/qt
        else
            QT_ROOT=/c/Qt/Qt${QT_VERSION}/${QT_VERSION}/android_armv7 #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/android/qt
        fi
    else
        if [ "`uname -s`" = "Linux" ]; then
            QT_ROOT=/opt/Qt${QT_VERSION}/${QT_VERSION}/android_${BUILD_ARCH} #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/android/qt
        else
            QT_ROOT=/c/Qt/Qt${QT_VERSION}/${QT_VERSION}/android_${BUILD_ARCH} #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/android/qt
        fi
    fi
fi

if [ -z "$RABBIT_CONFIG" ]; then
    RABBIT_CONFIG=Release
fi

if [ -z "${TOOLCHAIN_VERSION}" ]; then
    TOOLCHAIN_VERSION=4.9  #工具链版本号
fi

if [ -z "${ANDROID_API}" ]; then
    ANDROID_API=android-24
fi
ANDROID_NATIVE_API_LEVEL=`echo "$ANDROID_API"|awk -F '-' '{print $2}'` #android ndk api (平台)版本号, Qt5.9 支持最小平台版本
if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    RABBIT_BUILD_PREFIX=`pwd`/../${BUILD_TARGERT}    #修改这里为安装前缀  
    RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}${ANDROID_NATIVE_API_LEVEL}_${BUILD_ARCH}_${RABBIT_CONFIG}
    if [ -n "${QT_VERSION}" ]; then
        RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}_qt${QT_VERSION}
    fi
    if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
        RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}_static
    fi
fi
if [ ! -d ${RABBIT_BUILD_PREFIX} ]; then
    mkdir -p ${RABBIT_BUILD_PREFIX}
fi

if [ -z "$RABBIT_USE_REPOSITORIES" ]; then
    RABBIT_USE_REPOSITORIES="FALSE" #下载开发库。省略，则下载指定的压缩包  
fi

#设置qt安装位置
if [ -z "$QT_ROOT" -a -d "${RABBIT_BUILD_PREFIX}/qt" ]; then
    QT_ROOT=${RABBIT_BUILD_PREFIX}/qt
fi
QMAKE=qmake
if [ -n "${QT_ROOT}" ]; then
    QT_BIN=${QT_ROOT}/bin     #设置用于 android 平台编译的 qt bin 目录  
    QMAKE=${QT_BIN}/qmake     #设置用于 unix 平台编译的 QMAKE。
                              #这里设置的是自动编译时的配置，你需要修改为你本地qt编译环境的配置.
fi

MAKE="make" # ${BUILD_JOB_PARA}"
#自动判断主机类型，目前只做了linux、windows判断
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        if [ -z "$PKG_CONFIG" ]; then
            export PKG_CONFIG=/c/msys64/mingw32/bin/pkg-config.exe
        fi
        #ANDROID_NDK_HOST="windows-`uname -m`"
        ANDROID_NDK_HOST=windows-x86_64
        RABBIT_BUILD_HOST=$ANDROID_NDK_HOST
        if [ ! -d $ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST} ]; then
            ANDROID_NDK_HOST=windows
        fi
        RABBIT_CMAKE_MAKE_PROGRAM=$ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST}/bin/make #这个用不着，只有在windows命令行下才有用 
        YASM=$ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST}/bin/yasm.exe
        GENERATORS="Unix Makefiles"
        ;;
    Linux* | Unix*)
        ANDROID_NDK_HOST="linux-`uname -m`"    #windows、linux-x86_64
        RABBIT_BUILD_HOST=$ANDROID_NDK_HOST
        GENERATORS="Unix Makefiles" 
        YASM=$ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST}/bin/yasm
        ;;
    *)
    echo "Please set ANDROID_NDK_HOST. see build_envsetup_android.sh"
    return 2
    ;;
esac

#export PATH=$ANDROID_NDK/prebuilt/${ANDROID_NDK_HOST}/bin:$PATH
#if [ -z "$RABBIT_TOOL_CHAIN_ROOT" ]; then
#    RABBIT_TOOL_CHAIN_ROOT=${RABBIT_BUILD_PREFIX}/../android-toolchains-${BUILD_ARCH}-api${ANDROID_NATIVE_API_LEVEL}
#fi
##安装工具链
#if [ ! -d $RABBIT_TOOL_CHAIN_ROOT ]; then
#    python ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py \
#        --arch ${BUILD_ARCH} \
#        --api ${ANDROID_NATIVE_API_LEVEL} \
#        --install-dir ${RABBIT_TOOL_CHAIN_ROOT}
#    if [ ! $? = 0 ]; then
#        echo "Set windows's python to PATH in windows"
#        exit $?
#    fi
#fi

case ${BUILD_ARCH} in
    x86*)
        export ANDROID_TOOLCHAIN_NAME=${BUILD_ARCH}-${TOOLCHAIN_VERSION}
        if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
            if [ "${BUILD_ARCH}" = "x86_64" ]; then
                RABBIT_BUILD_CROSS_HOST=x86_64-linux-android
            else
                RABBIT_BUILD_CROSS_HOST=i686-linux-android
            fi
            RABBIT_BUILD_CROSS_HOST_CC=$RABBIT_BUILD_CROSS_HOST
        fi
        #交叉编译前缀
        if [ -z "$ANDROID_ABI" ]; then
            if [ "${BUILD_ARCH}" = "x86_64" ]; then
                export ANDROID_ABI="x86_64"
            else
                export ANDROID_ABI="x86"
            fi
        fi
        ANDROID_NDK_ABI_NAME=${ANDROID_ABI}
        ;;
    arm*)
        if [ -z "$ANDROID_ABI" ]; then
            if [ "${BUILD_ARCH}" = "arm64" ]; then
                export ANDROID_ABI="arm64-v8a"
            else
                export ANDROID_ABI="armeabi-v7a with NEON"
                export RABBIT_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
                export ANDROID_NDK_ABI_NAME="armeabi-v7a"
            fi

            export ANDROID_ARM_NEON=ON
        fi
        if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
            RABBIT_BUILD_CROSS_HOST=arm-linux-androideabi
            RABBIT_BUILD_CROSS_HOST_CC=armv7a-linux-androideabi
        fi
        export ANDROID_TOOLCHAIN_NAME=${RABBIT_BUILD_CROSS_HOST}-${TOOLCHAIN_VERSION}
        ;;
esac

#TODO:现在用clang，如果ndk<11，则注释下列行
export ANDROID_TOOLCHAIN_NAME=llvm

export RABBIT_BUILD_CROSS_PREFIX=$ANDROID_NDK/toolchains/$ANDROID_TOOLCHAIN_NAME/prebuilt/$ANDROID_NDK_HOST/bin/${RABBIT_BUILD_CROSS_HOST}-
export CC=$ANDROID_NDK/toolchains/$ANDROID_TOOLCHAIN_NAME/prebuilt/$ANDROID_NDK_HOST/bin/${RABBIT_BUILD_CROSS_HOST_CC}${ANDROID_NATIVE_API_LEVEL}-clang 
export CXX=$ANDROID_NDK/toolchains/$ANDROID_TOOLCHAIN_NAME/prebuilt/$ANDROID_NDK_HOST/bin/${RABBIT_BUILD_CROSS_HOST_CC}${ANDROID_NATIVE_API_LEVEL}-clang++
export AR=${RABBIT_BUILD_CROSS_PREFIX}ar
export LD=${RABBIT_BUILD_CROSS_PREFIX}ld
export AS=${RABBIT_BUILD_CROSS_PREFIX}as
export STRIP=${RABBIT_BUILD_CROSS_PREFIX}strip
export NM=${RABBIT_BUILD_CROSS_PREFIX}nm
if [ -z "$ANDROID_PLATFORM" ]; then
    ANDROID_PLATFORM=android-${ANDROID_NATIVE_API_LEVEL}
fi

# get version code
MAJOR=$(echo __GNUC__ | $CC -E -xc - | tail -n 1)
MINOR=$(echo __GNUC_MINOR__ | $CC -E -xc - | tail -n 1)
PATCHLEVEL=$(echo __GNUC_PATCHLEVEL__ | $CC -E -xc - | tail -n 1)
GCC_VERSION=${MAJOR}.${MINOR}.${PATCHLEVEL}
echo "gcc version:${GCC_VERSION}"

#交叉编译前缀
#export RABBIT_BUILD_CROSS_PREFIX=${RABBIT_TOOL_CHAIN_ROOT}/bin/${RABBIT_BUILD_CROSS_HOST}-
export RABBIT_TOOL_CHAIN_ROOT=$ANDROID_NDK/toolchains/$ANDROID_TOOLCHAIN_NAME/prebuilt/$ANDROID_NDK_HOST

#交叉编译平台的 sysroot
RABBIT_BUILD_CROSS_SYSROOT=$RABBIT_TOOL_CHAIN_ROOT/sysroot
RABBIT_BUILD_CROSS_SYSROOT_LIB=$RABBIT_BUILD_CROSS_SYSROOT

#RABBIT_BUILD_CROSS_SYSROOT=$ANDROID_NDK/sysroot
#RABBIT_BUILD_CROSS_SYSROOT_LIB=$ANDROID_NDK/platforms/android-$ANDROID_NATIVE_API_LEVEL/arch-${BUILD_ARCH}

RABBIT_BUILD_CROSS_STL=${ANDROID_NDK_ROOT}/sources/cxx-stl/gnu-libstdc++/${TOOLCHAIN_VERSION}
RABBIT_BUILD_CROSS_STL_INCLUDE=${RABBIT_BUILD_CROSS_STL}/include
RABBIT_BUILD_CROSS_STL_LIBS=${RABBIT_BUILD_CROSS_STL}/libs/${ANDROID_NDK_ABI_NAME}
RABBIT_BUILD_CROSS_STL_INCLUDE_FLAGS="-I${RABBIT_BUILD_CROSS_STL_INCLUDE} -I${RABBIT_BUILD_CROSS_STL_LIBS}/include"

if [ $ANDROID_NATIVE_API_LEVEL -lt 21 ]; then
    RABBIT_CMAKE_CFLAGS="-D_FILE_OFFSET_BITS=32"
    RABBIT_CFLAGS="$RABBIT_CFLAGS -D_FILE_OFFSET_BITS=32"
fi
RABBIT_CFLAGS="$RABBIT_CFLAGS -DANDROID -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL} -I${RABBIT_BUILD_PREFIX}/include"
RABBIT_CFLAGS="$RABBIT_CFLAGS --sysroot=${RABBIT_BUILD_CROSS_SYSROOT} -I$RABBIT_BUILD_CROSS_SYSROOT/usr/include/$RABBIT_BUILD_CROSS_HOST"
RABBIT_CPPFLAGS="$RABBIT_CFLAGS $RABBIT_BUILD_CROSS_STL_INCLUDE_FLAGS"
RABBIT_LDFLAGS="--sysroot=${RABBIT_BUILD_CROSS_SYSROOT_LIB} -L${RABBIT_BUILD_CROSS_STL_LIBS} -L${RABBIT_BUILD_PREFIX}/lib -L$RABBIT_BUILD_CROSS_SYSROOT_LIB"

export PATH=${RABBIT_TOOL_CHAIN_ROOT}/bin:${QT_BIN}:$PATH
#pkg-config帮助文档：http://linux.die.net/man/1/pkg-config
if [ -z "$PKG_CONFIG" ]; then
    export PKG_CONFIG=pkg-config 
fi
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    export PKG_CONFIG="${PKG_CONFIG} --static"
fi
export PKG_CONFIG_PATH=${RABBIT_BUILD_PREFIX}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH}
#export PKG_CONFIG_SYSROOT_DIR=${RABBIT_BUILD_PREFIX}

echo "---------------------------------------------------------------------------"
echo "==== ANDROID_SDK:$ANDROID_SDK"
echo "==== ANDROID_SDK_ROOT:$ANDROID_SDK_ROOT"
echo "==== ANDROID_NDK:$ANDROID_NDK"
echo "==== ANDROID_NDK_ROOT:$ANDROID_NDK_ROOT"
echo "==== ANDROID_ABI:$ANDROID_ABI"
echo "==== RABBIT_TOOL_CHAIN_ROOT:$RABBIT_TOOL_CHAIN_ROOT"
echo "==== ANDROID_TOOLCHAIN_NAME:$ANDROID_TOOLCHAIN_NAME"
echo "==== ANDROID_NATIVE_API_LEVEL:$ANDROID_NATIVE_API_LEVEL"
echo "==== ANDROID_API:$ANDROID_API"
echo "==== ANDROID_STL:$ANDROID_STL"
echo "==== RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "==== RABBIT_BUILD_CROSS_HOST：$RABBIT_BUILD_CROSS_HOST"
echo "==== TOOLCHAIN_VERSION:$TOOLCHAIN_VERSION"
echo "==== RABBIT_BUILD_CROSS_ROOT:$RABBIT_BUILD_CROSS_ROOT"
echo "==== RABBIT_BUILD_CROSS_STL:$RABBIT_BUILD_CROSS_STL"
echo "==== RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "==== RABBIT_CFLAGS:$RABBIT_CFLAGS"
echo "==== RABBIT_CPPFLAGS:$RABBIT_CPPFLAGS"
echo "==== RABBIT_LDFLAGS:$RABBIT_LDFLAGS"
echo "==== QT_ROOT:$QT_ROOT"
echo "==== PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
#echo "==== PKG_CONFIG_SYSROOT_DIR:$PKG_CONFIG_SYSROOT_DIR"
echo "==== PATH:$PATH"
echo "---------------------------------------------------------------------------"
