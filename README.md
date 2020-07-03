
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


      wget https://github.com/KangLin/RabbitThirdLibrary/releases/download/v0.2.9-27-g8e4e86d-27-g8e4e86d/windows_msvc15_x86_Qt5.12.8_v0.2.9-27-g8e4e86d-27-g8e4e86d.zip
      mkdir third_windows
      unzip windows_msvc15_x86_Qt5.12.8_v0.2.9-27-g8e4e86d-27-g8e4e86d.zip -O third_windows
      cd third_windows
      ./change_prefix.sh    #修改前缀为正确的目录
