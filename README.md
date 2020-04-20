
* 自动编译状态: 
    1. linux、android、mac、ios [![Build Status](https://travis-ci.org/KangLin/RabbitThirdLibrary.svg)](https://travis-ci.org/KangLin/RabbitThirdLibrary)
    2. windows [![Build status](https://ci.appveyor.com/api/projects/status/avr0nsghpb87ddnf?svg=true)](https://ci.appveyor.com/project/KangLin/rabbitthirdlibrary)

* 各目标编译详细说明：
    1. [ubuntu](INSTALL_UBUNTU.md)
    2. [android](INSTALL_ANDROID.md)
    3. [windows](INSTALL_WINDOWS.md)

* 预编译库存放位置：  
  https://github.com/KangLin/RabbitThirdLibrary/releases  
  
  文件格式： $(平台)$(版本号)_$(架构)_$(QT 版本)_版本.zip

  - Unix
    + [x86_64](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/unix_x86_64_v0.2.9.tar.gz)
    
    使用：
    
        wget https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/unix_x86_64_v0.2.9.tar.gz
        mkdir third_unix
        tar xzvf unix_x86_64_v0.2.9.tar.gz -C third_unix
        cd third_unix
        ./change_prefix.sh    #修改前缀为正确的目录
        
  - windows
    + [VC2017 x86](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_msvc15_x86_v0.2.9.zip)
    + [VC2017 x86_64](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_msvc15_x64_v0.2.9.zip)
    + [VC2015 x86](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_msvc14_x86_v0.2.9.zip)
    + [VC2015 x86_64](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_msvc14_x64_v0.2.9.zip)
    + [mingw32 5.3.0](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_mingw530_32_x86_v0.2.9.zip)
    
    使用：
    
        wget https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/windows_msvc15_x86_v0.2.9.zip
        mkdir third_windows
        unzip windows_msvc15_x86_v0.2.9.zip -d third_windows
        cd third_windows
        ./change_prefix.sh    #修改前缀为正确的目录
　　　
  - Android
    + [arm_v7](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/android_arm_v0.2.9_in_linux.tar.gz)
    + [arm64_v8a](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/android_arm64_v0.2.9_in_linux.tar.gz)
    + [x86](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/android_x86_v0.2.9_in_linux.tar.gz)
    + [x86_64](https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/android_x86_64_v0.2.9_in_linux.tar.gz)

    使用：
    
        wget https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9/android_arm_v0.2.9_in_linux.tar.gz
        mkdir third_android
        tar xzvf android_arm_v0.2.9_in_linux.tar.gz -C third_android
        cd third_android
        ./change_prefix.sh    #修改前缀为正确的目录
