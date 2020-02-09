#!/bin/sh
NDK=~/ffmpeg/packages/android-ndk-r16b
API=21
# HOST_PLATFORM=darwin-x86_64
HOST_PLATFORM=linux-x86_64

ARCHS="armeabi-v7a arm64-v8a x86"
# ARCHS="x86"

CWD=`pwd`
BUILD_SCRATCH=$CWD/"scratch-fdk-aac"

# 软件压缩包所在路径
PACKAGE_PATH=$CWD/packages
# 源码目录
SOURCE_VER=2.0.1
SOURCE_NAME=fdk-aac-$SOURCE_VER
SOURCE_EXT="tar.gz"
SOURCE_PATH=$PACKAGE_PATH/$SOURCE_NAME
BUILD_LIB_PATH=$CWD/"libs/fdk-aac"
DOWNLOAD_URL="https://downloads.sourceforge.net/opencore-amr/$SOURCE_NAME.$SOURCE_EXT"

# 删除文件或文件夹
delFile() {
  if [[ ! $1 ]];then
    echo "参数不存在"
  elif [ ! -f $1 -a ! -d $1 ];then
    :
  elif [ "$1" == "/" -o "$1" == "" ];then 
    :
  else
    rm -rf $1
  fi
}

preBuild() {
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

postBuild() {
  delFile $SOURCE_PATH
  delFile $BUILD_SCRATCH
}

build_one() { 
	mkdir -p "$BUILD_SCRATCH/$ARCH"
	cd "$BUILD_SCRATCH/$ARCH"

	# SYSROOT=$NDK/platforms/android-$API/arch-arm64
	# CROSS_COMPILE=${ANDROID_BIN}/aarch64-linux-android-
	ARM_INC=$SYSROOT/usr/include
	ARM_LIB=$SYSROOT/usr/lib

	CFLAGS=$EXTRA_CFLAGS

	FLAGS="--enable-static -disable-shared --enable-nonfree --host=$HOST --target=android --disable-asm"

	export CXX="${CROSS_PREFIX}g++ --sysroot=${SYSROOT}"

	export LDFLAGS=" -L$SYSROOT/usr/lib  $CFLAGS -nostdlib "

	export CXXFLAGS=$CFLAGS

	export CFLAGS=$CFLAGS

	export CC="${CROSS_PREFIX}gcc --sysroot=${SYSROOT}"

	export AR="${CROSS_PREFIX}ar"

	export LD="${CROSS_PREFIX}ld"

	export AS="${CROSS_PREFIX}gcc"

	$SOURCE_PATH/configure $FLAGS \
	--enable-pic \
	--enable-strip \
	--prefix="$BUILD_LIB_PATH/$ARCH"

	make clean
	make -j4
	make install
  echo "编译结束$ARCH"
}


preBuild

# 如果aac版本为2.0.1
echo "【$SOURCE_NAME】3. 修改代码内容..."
if [[ "$SOURCE_VER" == "2.0.1" ]];then
  sed -i "s/#include \"log\/log.h\"/\/\/#include \"log\/log.h\"/" $SOURCE_PATH/libSBRdec/src/lpp_tran.cpp
  sed -i "s/android_errorWriteLog/\/\/android_errorWriteLog/" $SOURCE_PATH/libSBRdec/src/lpp_tran.cpp
fi

echo "【$SOURCE_NAME】4. 编译以下 架构 $ARCHS"
for CPU_TEMP in $ARCHS
do
     case $CPU_TEMP in 
          "armeabi-v7a")
               ARCH="armeabi-v7a"
               CROSS_PREFIX=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/$HOST_PLATFORM/bin/arm-linux-androideabi-
               SYSROOT=$NDK/platforms/android-$API/arch-arm/
               EXTRA_CFLAGS="-D__ANDROID_API__=$API -isysroot $NDK/sysroot -I$NDK/sysroot/usr/include -I$NDK/sysroot/usr/include/arm-linux-androideabi -Os -fPIC -marm"
               EXTRA_LDFLAGS="-marm"
               HOST=arm-linux
               build_one
          ;;
          "arm64-v8a")
               ARCH="arm64-v8a"
               CROSS_PREFIX=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/$HOST_PLATFORM/bin/aarch64-linux-android-
               SYSROOT=$NDK/platforms/android-$API/arch-arm64/
               EXTRA_CFLAGS="-D__ANDROID_API__=$API -isysroot $NDK/sysroot -I$NDK/sysroot/usr/include -I$NDK/sysroot/usr/include/aarch64-linux-android -Os -fPIC"
               EXTRA_LDFLAGS=""
               HOST=aarch64-linux
               build_one
          ;;
          "x86")
               ARCH="x86"
               CROSS_PREFIX=$NDK/toolchains/x86-4.9/prebuilt/$HOST_PLATFORM/bin/i686-linux-android-
               SYSROOT=$NDK/platforms/android-$API/arch-x86/
               EXTRA_CFLAGS="-D__ANDROID_API__=$API -isysroot $NDK/sysroot -I$NDK/sysroot/usr/include -I$NDK/sysroot/usr/include/i686-linux-android -Os -fPIC"
               EXTRA_LDFLAGS=""
               HOST=i686-linux
               build_one
          ;;
     esac
done

echo "【$SOURCE_NAME】5. 清除工作..."
# postBuild