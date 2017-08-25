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
if [ -z "$QT_ROOT" ]; then
    QT_ROOT=/c/Qt/Qt5.7.0_android/5.7/mingw53_32 #QT 安装根目录,默认为:${RABBITRoot}/ThirdLibrary/windows_mingw/qt
fi
JOM=nmake #设置 QT make 工具 JOM
if [ -z "$RABBIT_CLEAN" ]; then
    RABBIT_CLEAN=TRUE #编译前清理
fi
#RABBIT_BUILD_STATIC="static" #设置编译静态库，注释掉，则为编译动态库
#RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32  #编译工具链前缀,用于交叉编译
#RABBIT_USE_REPOSITORIES="FALSE" #下载指定的压缩包。省略，则下载开发库。
if [ -z "${RABBIT_MAKE_JOB_PARA}" ]; then
    RABBIT_MAKE_JOB_PARA="-j`cat /proc/cpuinfo |grep 'cpu cores' |wc -l`"  #make 同时工作进程参数
    if [ "$RABBIT_MAKE_JOB_PARA" = "-j1" ];then
        RABBIT_MAKE_JOB_PARA=
    fi
fi

#   RABBIT_BUILD_PREFIX=`pwd`/../${RABBIT_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBIT_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBIT_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

if [ -n "${RABBITRoot}" ]; then
    RABBIT_BUILD_PREFIX=${RABBITRoot}/ThirdLibrary/windows_mingw
else
    RABBIT_BUILD_PREFIX=`pwd`/../windows_mingw    #修改这里为安装前缀
fi
if [ "$RABBIT_BUILD_STATIC" = "static" ]; then
    RABBIT_BUILD_PREFIX=${RABBIT_BUILD_PREFIX}_static
fi
if [ ! -d ${RABBIT_BUILD_PREFIX} ]; then
    mkdir -p ${RABBIT_BUILD_PREFIX}
fi

MAKE="make ${RABBIT_MAKE_JOB_PARA}"
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
    export PKG_CONFIG="pkg-config --static"
fi

if [ -z "$RABBIT_USE_REPOSITORIES" ]; then
    RABBIT_USE_REPOSITORIES="TRUE" #下载开发库。省略，则下载指定的压缩包
fi

if [ -z "$QT_ROOT" -a -d "${RABBIT_BUILD_PREFIX}/qt" ]; then
    QT_ROOT=${RABBIT_BUILD_PREFIX}/qt
fi
QMAKE=qmake
if [ -n "${QT_ROOT}" ]; then
    QT_BIN=${QT_ROOT}/bin       #设置用于 android 平台编译的 qt bin 目录
    QMAKE=${QT_BIN}/qmake       #设置用于 unix 平台编译的 QMAKE。
                            #这里设置的是自动编译时的配置，你需要修改为你本地qt编译环境的配置.
fi

export PATH=${RABBIT_BUILD_PREFIX}/bin:${RABBIT_BUILD_PREFIX}/lib:${QT_BIN}:$PATH

if [ -z "${RABBIT_BUILD_CROSS_HOST}" ]; then
    RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32 #编译工具链前缀
fi
RABBIT_BUILD_CROSS_PREFIX=${RABBIT_BUILD_CROSS_HOST}-
