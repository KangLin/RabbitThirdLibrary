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

#需要设置下面变量：
if [ -z "$QT_ROOT" -a -z "$APPVEYOR" ]; then
    QT_VERSION=5.12.11
    QT_ROOT=/c/Qt/Qt${QT_VERSION}/${QT_VERSION}/mingw73_32 #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/windows_mingw/qt
    TOOLCHAIN_VERSION=730    
    set MSYSTEM=MINGW32
    RABBIT_TOOLCHAIN_ROOT=/c/Qt/Qt${QT_VERSION}/Tools/mingw${TOOLCHAIN_VERSION}_32
    export PATH=${RABBIT_TOOLCHAIN_ROOT}/bin:$PATH  #用与QT相同的工具链
fi
if [ -z "$RABBIT_CLEAN" ]; then
    RABBIT_CLEAN=TRUE #编译前清理
fi
#RABBIT_BUILD_STATIC="static" #设置编译静态库，注释掉，则为编译动态库
#RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32  #编译工具链前缀,用于交叉编译
#RABBIT_USE_REPOSITORIES="TRUE" #下载指定的压缩包。省略，则下载开发库。
if [ -z "${BUILD_JOB_PARA}" ]; then
    BUILD_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$BUILD_JOB_PARA" = "-j1" ];then
        BUILD_JOB_PARA=
    fi
fi

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

#   RABBIT_BUILD_PREFIX=`pwd`/../${BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot
if [ -z "${BUILD_ARCH}" ]; then
    case $MSYSTEM in
        MINGW32)
            BUILD_ARCH=x86
            ;;
        MINGW64)
            BUILD_ARCH=x64
            ;;
        *)
            echo "Error BUILD_ARCH=$MSYSTEM, set BUILD_ARCH=x86"
            BUILD_ARCH=x86
            ;;
    esac
    export BUILD_ARCH=$BUILD_ARCH
fi
case ${BUILD_ARCH} in
    x86)
        if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
            RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32 #编译工具链前缀
        fi
        ;;
    x64)
        if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
            RABBIT_BUILD_CROSS_HOST=x86_64-w64-mingw32 #编译工具链前缀
        fi
        ;;
    *)
        if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
            RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32 #编译工具链前缀
        fi
        ;;
esac

export RABBIT_BUILD_CROSS_HOST=$RABBIT_BUILD_CROSS_HOST
RABBIT_BUILD_CROSS_PREFIX=${RABBIT_BUILD_CROSS_HOST}-

if [ -z "$RABBIT_BUILD_CROSS_SYSROOT" -a -n "${RABBIT_TOOLCHAIN_ROOT}" ];then
    export RABBIT_BUILD_CROSS_SYSROOT=${RABBIT_TOOLCHAIN_ROOT}/${RABBIT_BUILD_CROSS_HOST}
fi

if [ -z "$RABBIT_CONFIG" ]; then
    RABBIT_CONFIG=Release
fi

if [ -z "${RABBIT_BUILD_PREFIX}" ]; then
    RABBIT_BUILD_PREFIX=`pwd`/../${BUILD_TARGERT}    #修改这里为安装前缀  
    RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}${TOOLCHAIN_VERSION}_${BUILD_ARCH}_${RABBIT_CONFIG}
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

MAKE="make ${BUILD_JOB_PARA}"
#自动判断主机类型，目前只做了linux、windows判断
TARGET_OS=`uname -s`
case $TARGET_OS in
    MINGW* | CYGWIN* | MSYS*)
        MAKE=make
        export PKG_CONFIG_PATH=${RABBIT_BUILD_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
        GENERATORS="MSYS Makefiles"
        ;;
    Linux* | Unix*)
        #pkg-config帮助文档：http://linux.die.net/man/1/pkg-config
        export PKG_CONFIG_PATH=${RABBIT_BUILD_PREFIX}/lib/pkgconfig
        export PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH}
        export PKG_CONFIG_SYSROOT_DIR=${RABBIT_BUILD_PREFIX}
        GENERATORS="Unix Makefiles"
        ;;
    *)
    echo "Please set RABBIT_BUILD_HOST. see build_envsetup_windows_mingw.sh"
    return 2
    ;;
esac

if [ -z "$PKG_CONFIG" ]; then
    export PKG_CONFIG=pkg-config 
fi
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    export PKG_CONFIG="${PKG_CONFIG} --static"
fi

if [ -z "$RABBIT_USE_REPOSITORIES" ]; then
    RABBIT_USE_REPOSITORIES="FALSE" #下载开发库。省略，则下载指定的压缩包
fi

if [ -z "$QT_ROOT" -a -d "${RABBIT_BUILD_PREFIX}/qt" ]; then
    QT_ROOT=${RABBIT_BUILD_PREFIX}/qt
fi
QMAKE=qmake
if [ -n "${QT_ROOT}" -a "${QT_ROOT}" != "NO" ]; then
    QT_BIN=${QT_ROOT}/bin       #设置用于 android 平台编译的 qt bin 目录
    QMAKE=${QT_BIN}/qmake       #设置用于 unix 平台编译的 QMAKE。
                        #这里设置的是自动编译时的配置，你需要修改为你本地qt编译环境的配置.
fi

#export PATH=${RABBIT_BUILD_PREFIX}/bin:${RABBIT_BUILD_PREFIX}/lib:${QT_BIN}:$PATH

export PKG_CONFIG_PATH=${RABBIT_BUILD_PREFIX}/lib/pkgconfig
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_PATH}
if [ -n "$RABBIT_BUILD_CROSS_SYSROOT" ]; then
    export RABBIT_CFLAGS="--sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
    export RABBIT_CPPFLAGS="--sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
    export RABBIT_LDFLAGS="--sysroot=${RABBIT_BUILD_CROSS_SYSROOT}"
    
    RABBIT_BUILD_CROSS_STL=${RABBIT_BUILD_CROSS_SYSROOT}
    RABBIT_BUILD_CROSS_STL_INCLUDE=${RABBIT_BUILD_CROSS_STL}/include/c++
    #RABBIT_BUILD_CROSS_STL_LIBS=${RABBIT_BUILD_CROSS_STL}/libs
    RABBIT_BUILD_CROSS_STL_INCLUDE_FLAGS="-I${RABBIT_BUILD_CROSS_STL_INCLUDE}" # -I${RABBIT_BUILD_CROSS_STL_LIBS}/include"
    export RABBIT_CPPFLAGS="$RABBIT_CFLAGS $RABBIT_BUILD_CROSS_STL_INCLUDE_FLAGS"    
fi

# configure C compiler
export compiler=$(which gcc)
# get version code
MAJOR=$(echo __GNUC__ | $compiler -E -xc - | tail -n 1)
MINOR=$(echo __GNUC_MINOR__ | $compiler -E -xc - | tail -n 1)
PATCHLEVEL=$(echo __GNUC_PATCHLEVEL__ | $compiler -E -xc - | tail -n 1)
GCC_VERSION=${MAJOR}.${MINOR}.${PATCHLEVEL}
echo "gcc version:${GCC_VERSION}"

echo "---------------------------------------------------------------------------"
echo "==== RABBIT_BUILD_PREFIX:$RABBIT_BUILD_PREFIX"
echo "==== QT_BIN:$QT_BIN"
echo "==== QT_ROOT:$QT_ROOT"
echo "==== PKG_CONFIG_PATH:$PKG_CONFIG_PATH"
echo "==== PKG_CONFIG_SYSROOT_DIR:$PKG_CONFIG_SYSROOT_DIR"
echo "==== RABBIT_BUILD_CROSS_HOST:$RABBIT_BUILD_CROSS_HOST"
echo "==== RABBIT_BUILD_CROSS_SYSROOT:$RABBIT_BUILD_CROSS_SYSROOT"
echo "==== RABBIT_TOOLCHAIN_ROOT:$RABBIT_TOOLCHAIN_ROOT"
echo "==== RABBIT_BUILD_CROSS_STL:$RABBIT_BUILD_CROSS_STL"
echo "==== RABBIT_BUILD_CROSS_STL_INCLUDE:$RABBIT_BUILD_CROSS_STL_INCLUDE"
echo "==== PATH:$PATH"
echo "---------------------------------------------------------------------------"
