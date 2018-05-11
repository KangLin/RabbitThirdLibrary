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
if [ "$BUILD_TARGERT" = "android" ]; then
    export ANDROID_SDK_ROOT=${TOOLS_DIR}/android-sdk
    export ANDROID_NDK_ROOT=${TOOLS_DIR}/android-ndk
    export JAVA_HOME="/C/Program Files (x86)/Java/jdk1.8.0"
    export PATH=${TOOLS_DIR}/apache-ant/bin:$JAVA_HOME:$PATH
else
    exit 0
fi

if [ ! -d "${TOOLS_DIR}" ]; then
    mkdir ${TOOLS_DIR}
fi

cd ${TOOLS_DIR}

# Qt qt安装参见：https://github.com/benlau/qtci  
if [ "NO" != "${QT_VERSION}" ]; then
    QT_DIR=C:/projects/rabbitthirdlibrary/Tools/Qt/${QT_VERSION}
    if [ -d "C:/projects/rabbitim/ThirdLibrary/Tools" ]; then
        QT_DIR=C:/projects/rabbitim/ThirdLibrary/Tools/Qt/${QT_VERSION}
    fi
    if [ ! -d "${QT_DIR}" ]; then
        wget -c --no-check-certificate -nv http://download.qt.io/official_releases/qt/${QT_VERSION_DIR}/${QT_VERSION}/qt-opensource-windows-x86-android-${QT_VERSION}.exe
        bash ${SCRIPT_DIR}/ci/qt-installer.sh qt-opensource-windows-x86-android-${QT_VERSION}.exe ${QT_DIR}
        rm qt-opensource-windows-x86-android-${QT_VERSION}.exe
    fi
fi

#下载ANT
#wget -c -nv http://apache.fayea.com/ant/binaries/apache-ant-1.10.1-bin.tar.gz
ANT_VERSION=1.10.3
wget -c -nv https://www.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz
tar xzf apache-ant-${ANT_VERSION}-bin.tar.gz
rm -f apache-ant-${ANT_VERSION}-bin.tar.gz
mv apache-ant-${ANT_VERSION} apache-ant

#Download android sdk  
if [ ! -d "${TOOLS_DIR}/android-sdk" ]; then
    wget -c -nv https://dl.google.com/android/android-sdk_r24.4.1-windows.zip
    unzip -q android-sdk_r24.4.1-windows.zip
    mv android-sdk-windows android-sdk
    rm android-sdk_r24.4.1-windows.zip
    (sleep 5 ; while true ; do sleep 1 ; printf 'y\r\n' ; done ) \
    | android-sdk/tools/android.bat update sdk -u -t tool,android-18,extra,platform,platform-tools,build-tools
fi

#下载android ndk  
if [ ! -d "${TOOLS_DIR}/android-ndk" ]; then
    wget -c -nv https://dl.google.com/android/repository/android-ndk-r17-windows-x86_64.zip
    unzip -q android-ndk-r17-windows-x86_64.zip
    mv android-ndk-r17 android-ndk
    rm android-ndk-r17-windows-x86_64.zip
    #使用WINDOWS下的PYTHON
    cd android-ndk/build/tools
    if [ -z "${ANDROID_NATIVE_API_LEVEL}" ]; then
        ./make_standalone_toolchain.py \
            --arch ${RABBIT_ARCH} \
            --install-dir ${TOOLS_DIR}/android-ndk/android-toolchain-${RABBIT_ARCH}
    else
        ./make_standalone_toolchain.py \
            --arch ${RABBIT_ARCH} \
            --api ${ANDROID_NATIVE_API_LEVEL} \
            --install-dir ${TOOLS_DIR}/android-ndk/android-toolchain-${RABBIT_ARCH}
    fi
fi

cd ${SOURCE_DIR}
