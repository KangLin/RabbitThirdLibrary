#!/bin/bash 
#下载工具  

set -e

SOURCE_DIR=../..
if [ -n "$1" ]; then
    SOURCE_DIR=$1
fi
echo $SOURCE_DIR
TOOLS_DIR=${SOURCE_DIR}/Tools

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
    
    # Qt qt安装参见：https://github.com/benlau/qtci  
    if [ "$DOWNLOAD_QT" = "TRUE" ]; then
        QT_DIR=`pwd`/Qt/${QT_VERSION}
        if [ ! -d "${QT_DIR}" ]; then
            if [ "${QT_VERSION}" = "5.6.3" ]; then
                wget -c --no-check-certificate -nv http://download.qt.io/official_releases/qt/${QT_VERSION_DIR}/${QT_VERSION}/qt-opensource-linux-x64-android-${QT_VERSION}.run
                bash ${SOURCE_DIR}/build_script/ci/qt-installer.sh qt-opensource-linux-x64-android-${QT_VERSION}.run ${QT_DIR}
                rm qt-opensource-linux-x64-android-${QT_VERSION}.run
            else
                wget -c --no-check-certificate -nv http://download.qt.io/official_releases/qt/${QT_VERSION_DIR}/${QT_VERSION}/qt-opensource-linux-x64-${QT_VERSION}.run
                bash ${SOURCE_DIR}/build_script/ci/qt-installer.sh qt-opensource-linux-x64-${QT_VERSION}.run ${QT_DIR}
                rm qt-opensource-linux-x64-${QT_VERSION}.run
            fi
        fi
    fi
}

function install_android()
{
    cd ${TOOLS_DIR}
    if [ ! -d "`pwd`/android-sdk" ]; then
        ANDROID_STUDIO_VERSION=191.5900203
        wget -c -nv https://dl.google.com/dl/android/studio/ide-zips/3.5.1.0/android-studio-ide-${ANDROID_STUDIO_VERSION}-linux.tar.gz
        tar xzf android-studio-ide-${ANDROID_STUDIO_VERSION}-linux.tar.gz
        export JAVA_HOME=`pwd`/android-studio/jre
        export PATH=${JAVA_HOME}/bin:$PATH
        wget -c -nv https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
        mkdir android-sdk
        cd android-sdk
        cp ../sdk-tools-linux-4333796.zip .
        unzip -q sdk-tools-linux-4333796.zip
        echo "Install sdk and ndk ......"
        if [ -n "${ANDROID_API}" ]; then
            PLATFORMS="platforms;${ANDROID_API}"
        else
            PLATFORMS="platforms"
        fi
        if [ -z "${BUILD_TOOS_VERSION}" ]; then
            BUILD_TOOS_VERSION="28.0.3"
        fi
        (sleep 5 ; num=0 ; while [ $num -le 5 ] ; do sleep 1 ; num=$(($num+1)) ; printf 'y\r\n' ; done ) \
        | ./tools/bin/sdkmanager "platform-tools" "build-tools;${BUILD_TOOS_VERSION}" "${PLATFORMS}" "ndk-bundle"
        if [ ! -d ${TOOLS_DIR}/android-ndk ]; then
            ln -s ${TOOLS_DIR}/android-sdk/ndk-bundle ${TOOLS_DIR}/android-ndk
        fi
    fi
}

function function_android()
{
    cd ${TOOLS_DIR}
    
    sudo apt-get update -y -qq

    install_android
    
    sudo apt-get install ant -qq -y
    
    function_common
    cd ${SOURCE_DIR}
}

function function_unix()
{
    #汇编工具yasm
    #function_install_yasm
    sudo apt-get install -qq -y yasm
    
#    if [ "$DOWNLOAD_QT" != "TRUE" ]; then
#        #See: https://launchpad.net/~beineri
#        sudo add-apt-repository ppa:beineri/opt-qt-${QT_VERSION}-`lsb_release -c|awk '{print $2}'` -y
#        sudo apt-get install -y -qq qt${QT_VERSION_DIR}base \
#            qt${QT_VERSION_DIR}tools \
#            qt${QT_VERSION_DIR}multimedia
#    fi
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
