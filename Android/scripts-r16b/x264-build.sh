#!/bin/sh
NDK=~/ffmpeg/packages/android-ndk-r16b
# NDK=~/ffmpeg/packages/android-ndk-r10e
API=21 #最低支持Android版本
# HOST_PLATFORM=darwin-x86_64
HOST_PLATFORM=linux-x86_64

ARCHS="armeabi-v7a arm64-v8a x86"
# ARCHS="armeabi-v7a"

CWD=`pwd`
BUILD_SCRATCH=$CWD/"scratch-x264"

# 软件压缩包所在路径
PACKAGE_PATH=$CWD/packages
# 源码目录
SOURCE_VER=stable
SOURCE_NAME=x264-$SOURCE_VER
SOURCE_EXT="tar.gz"
SOURCE_PATH=$PACKAGE_PATH/$SOURCE_NAME
BUILD_LIB_PATH=$CWD/"libs/x264"
DOWNLOAD_URL="https://code.videolan.org/videolan/x264/-/archive/stable/$SOURCE_NAME.$SOURCE_EXT"

# 删除文件或文件夹
delFile() {
  if [ ! $1 ];then
    echo "参数不存在"
  elif [ ! -f $1 -a ! -d $1 ];then
    :
  elif [ "$1" == "/" -o "$1" == "" ];then 
    :
  else
    rm -rf $1
  fi
}

function preBuild {
  echo "【$SOURCE_NAME】1. 准备..."
  delFile $SOURCE_PATH
  delFile $BUILD_LIB_PATH
  delFile $BUILD_SCRATCH

  if [[  ! -f "$SOURCE_PATH.$SOURCE_EXT" ]]; then
    wget -P $PACKAGE_PATH $DOWNLOAD_URL 
  fi

  echo "【$SOURCE_NAME】2. 解压..."
  if [[ "$SOURCE_EXT" == "tar.gz" ]];then
    tar -zxvf "$SOURCE_PATH.$SOURCE_EXT" -C  $PACKAGE_PATH/
  elif [[ "$SOURCE_EXT" == "tar.bz2" ]]; then
    tar -jxvf "$SOURCE_PATH.$SOURCE_EXT" -C  $PACKAGE_PATH/
  elif [[ "$SOURCE_EXT" == "zip" ]]; then
    unzip -d $PACKAGE_PATH/ "$SOURCE_PATH.$SOURCE_EXT"
  fi
}

function postBuild {
  delFile $SOURCE_PATH
  delFile $BUILD_SCRATCH
}

function build_one { 
  mkdir -p "$BUILD_SCRATCH/$ARCH"
  cd "$BUILD_SCRATCH/$ARCH"
  # EXTRA_LDFLAGS="-arch $ARCH $EXTRA_LDFLAGS"

  # 以下行：在将libx264.a和libavcodec.a等文件合并为一个.so文件时，需要指定
  # 否则出现warning: cannot scan executable section 1 of libx264.a(dct-a-8.o) 
  # for Cortex-A8 erratum because it has no mapping symbols.
  export STRIP=${CROSS_PREFIX}strip

  echo "开始编译$ARCH"
  echo "ARCH = $ARCH "
  echo "OUTPUT = $OUTPUT "
  echo "CROSS_PREFIX = $CROSS_PREFIX "
  echo "SYSROOT = $SYSROOT "
  echo "EXTRA_CFLAGS = $EXTRA_CFLAGS "
  echo "EXTRA_LDFLAGS = $EXTRA_LDFLAGS "
  # $CWD/$SOURCE/configure \
  # --prefix="$BUILD_LIB_PATH/$ARCH" \
  # --cross-prefix=$CROSS_PREFIX \
  # --sysroot=$SYSROOT \
  # --host=$HOST \
  # --enable-static \
  # --enable-pic \
  # --disable-thread \
  # --enable-strip \
  # --extra-cflags="$EXTRA_CFLAGS" \
  # --extra-ldflags="$ADDI_LDFLAGS" \
  # $ADDITIONAL_CONFIGURE_FLAG

  $SOURCE_PATH/configure \
    --prefix="$BUILD_LIB_PATH/$ARCH" \
    --cross-prefix=$CROSS_PREFIX \
    --sysroot=$SYSROOT \
    --host=$HOST \
    --enable-static \
    --enable-pic \
    --enable-asm \
    --enable-thread \
    --enable-strip \
    --extra-cflags="$EXTRA_CFLAGS -Os -fpic -D__ANDROID_API__=$API -I$NDK/sysroot/usr/include" \
    --extra-ldflags="-L$SYSROOT/usr/lib $EXTRA_LDFLAGS" \
    $ADDITIONAL_CONFIGURE_FLAG


   make clean 
   make -j4
   make install
   echo "编译结束$ARCH"
}

preBuild

echo "【$SOURCE_NAME】3. 编译以下 架构 $ARCHS"

for CPU_TEMP in $ARCHS
do
     case $CPU_TEMP in 
          "armeabi-v7a")
               ARCH="armeabi-v7a"
               CROSS_PREFIX=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$HOST_PLATFORM/bin/arm-linux-androideabi-
               SYSROOT=$NDK/platforms/android-$API/arch-arm/

               # EXTRA_CFLAGS="-D__ANDROID_API__=$API -isysroot $NDK/sysroot -I$NDK/sysroot/usr/include/arm-linux-androideabi -Os -fPIC -marm"
               EXTRA_CFLAGS="-march=armv7-a  -mfloat-abi=softfp -mfpu=neon -I$NDK/sysroot/usr/include/arm-linux-androideabi -marm"
               EXTRA_LDFLAGS="-marm"
               # EXTRA_LDFLAGS=""
               HOST=arm-linux
               build_one
          ;;
          "arm64-v8a")
               ARCH="arm64-v8a"
               CROSS_PREFIX=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/$HOST_PLATFORM/bin/aarch64-linux-android-
               SYSROOT=$NDK/platforms/android-$API/arch-arm64/
               # EXTRA_CFLAGS="-D__ANDROID_API__=$API -isysroot $NDK/sysroot -I$NDK/sysroot/usr/include/aarch64-linux-android -Os -fPIC"
               EXTRA_CFLAGS="-I$NDK/sysroot/usr/include/aarch64-linux-android"
               EXTRA_LDFLAGS=""
               HOST=aarch64-linux
               build_one
          ;;
          "x86")
               ARCH="x86"
               CROSS_PREFIX=$NDK/toolchains/x86-4.9/prebuilt/$HOST_PLATFORM/bin/i686-linux-android-
               SYSROOT=$NDK/platforms/android-$API/arch-x86/
               EXTRA_CFLAGS="-I$NDK/sysroot/usr/include/i686-linux-android"
               EXTRA_LDFLAGS=""
               HOST=i686-linux
               build_one
          ;;
     esac
done

echo "【$SOURCE_NAME】4. 清除工作..."
postBuild
