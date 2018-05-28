#!/bin/bash 
#下载工具  

set -e

SOURCE_DIR="`pwd`"
echo $SOURCE_DIR
TOOLS_DIR=${SOURCE_DIR}/Tools
if [ -d "${SOURCE_DIR}/ThirdLibrary" ]; then
    TOOLS_DIR=${SOURCE_DIR}/ThirdLibrary/Tools
fi
echo ${TOOLS_DIR}
SCRIPT_DIR=${SOURCE_DIR}/build_script
if [ -d ${SOURCE_DIR}/ThirdLibrary/build_script ]; then
    SCRIPT_DIR=${SOURCE_DIR}/ThirdLibrary/build_script
fi

if [ ! -f "${TOOLS_DIR}" ]; then
    mkdir -p ${TOOLS_DIR}
fi

function function_install_yasm()
{
    #安装 yasm
    mkdir -p ${TOOLS_DIR}/src
    cd ${TOOLS_DIR}/src
    wget -c -nv http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz 
    tar xzf yasm-1.3.0.tar.gz
    cd yasm-1.3.0/
    ./configure > /dev/null && sudo make install -j2 > /dev/null
    cd ${SOURCE_DIR}
}

function function_common()
{
    cd ${TOOLS_DIR}
    #下载最新cmake程序
    if [ "cmake" = "${QMAKE}" ]; then
        if [ ! -d "`pwd`/cmake" ]; then
            wget -nv --no-check-certificate http://www.cmake.org/files/v3.6/cmake-3.6.1-Linux-x86_64.tar.gz
            tar xzf cmake-3.6.1-Linux-x86_64.tar.gz
            mv cmake-3.6.1-Linux-x86_64 cmake
        fi
    fi
    
    # Qt qt安装参见：https://github.com/benlau/qtci  
    if [ -n "${QT_VERSION}" ]; then
        QT_DIR=`pwd`/Qt/${QT_VERSION}
        if [ ! -d "${QT_DIR}" ]; then
            wget -c --no-check-certificate -nv http://download.qt.io/official_releases/qt/${QT_VERSION_DIR}/${QT_VERSION}/qt-opensource-linux-x64-android-${QT_VERSION}.run
            bash ${SCRIPT_DIR}/ci/qt-installer.sh qt-opensource-linux-x64-android-${QT_VERSION}.run ${QT_DIR}
            rm qt-opensource-linux-x64-android-${QT_VERSION}.run
        fi
    fi
}

function function_android()
{
    cd ${TOOLS_DIR}

    #下载android ndk  
    if [ ! -d "`pwd`/android-ndk" ]; then
        wget -c -nv http://dl.google.com/android/ndk/android-ndk-r10e-linux-x86_64.bin
        chmod u+x android-ndk-r10e-linux-x86_64.bin
        ./android-ndk-r10e-linux-x86_64.bin > /dev/null
        mv android-ndk-r10e android-ndk
        rm android-ndk-r10e-linux-x86_64.bin
    fi

    cd ${TOOLS_DIR}
    
    #Download android sdk  
    if [ ! -d "`pwd`/android-sdk" ]; then
        wget -c -nv https://dl.google.com/android/android-sdk_r24.4.1-linux.tgz
        tar xf android-sdk_r24.4.1-linux.tgz 
        mv android-sdk-linux android-sdk
        rm android-sdk_r24.4.1-linux.tgz 
        (sleep 5 ; while true ; do sleep 1 ; printf 'y\r\n' ; done ) \
        | android-sdk/tools/android update sdk -u -t tool,android-18,android-24,extra,platform-tools,build-tools #platforms
    fi

    function_common
    cd ${SOURCE_DIR}
}

function function_unix()
{
    #汇编工具yasm
    #function_install_yasm

    function_common

    cd ${SOURCE_DIR}
}

function function_mingw()
{
    #汇编工具yasm
    #function_install_yasm

    if [ "true" == "$RABBIT_BUILD_THIRDLIBRARY" ]; then
        export RABBIT_BUILD_CROSS_HOST=i686-w64-mingw32 #i586-mingw32msvc
    fi

    function_common
    cd ${SOURCE_DIR}
}

case ${BUILD_TARGERT} in
    android)
        function_android
        ;;
    unix)
        function_unix
        ;;
    windows_mingw)
        function_mingw
        ;;
    *)
    echo "There aren't ${BUILD_TARGERT}"
        ;;
esac

cd ${SOURCE_DIR}
