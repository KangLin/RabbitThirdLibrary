SOURCE_DIR="`pwd`"
echo $SOURCE_DIR
TOOLS_DIR=${SOURCE_DIR}/Tools
if [ -d "${SOURCE_DIR}/ThirdLibrary" ]; then
    TOOLS_DIR=${SOURCE_DIR}/ThirdLibrary/Tools
fi
cd ${TOOLS_DIR}

export PATH=${TOOLS_DIR}/cmake/bin:$PATH

if [ "${BUILD_TARGERT}" = "unix" ]; then
    QT_DIR=`pwd`/Qt/${QT_VERSION}
    export QT_ROOT=${QT_DIR}/${QT_VERSION_DIR}/gcc_64
    if [ "${QT_VERSION}" = "5.2.1" ]; then
        export QT_ROOT=${QT_DIR}/${QT_VERSION}/gcc_64
    fi
fi

if [ "${BUILD_TARGERT}" = "android" ]; then
    export ANDROID_NDK_ROOT=`pwd`/android-ndk
    export ANDROID_NDK=$ANDROID_NDK_ROOT

    export ANDROID_SDK_ROOT=`pwd`/android-sdk
    export ANDROID_SDK=$ANDROID_SDK_ROOT    
fi

if [ "${BUILD_TARGERT}" = "android" -o "${BUILD_TARGERT}" = "unix" ]; then
    QT_DIR=`pwd`/Qt/Qt${QT_VERSION}/${QT_VERSION}
    case $BUILD_ARCH in
        arm*)
            export QT_ROOT=${QT_DIR}/android_armv7
            ;;
        x86*)
            export QT_ROOT=${QT_DIR}/android_$BUILD_ARCH
            ;;
        unix)
            export QT_ROOT=${QT_DIR}/gcc_64
            ;;
           *)
           echo "Don't arch $BUILD_ARCH"
           ;;
    esac
fi
