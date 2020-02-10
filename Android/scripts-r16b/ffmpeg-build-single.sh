#!/bin/sh
NDK=~/ffmpeg/packages/android-ndk-r16b
# NDK=~/ffmpeg/packages/android-ndk-r10e
API=21
# HOST_PLATFORM=darwin-x86_64
HOST_PLATFORM=linux-x86_64

ARCHS="armeabi-v7a arm64-v8a x86"
# ARCHS="x86"

CWD=`pwd`
BUILD_SCRATCH=$CWD/"scratch-ffmpeg"

# 软件压缩包所在路径
PACKAGE_PATH=$CWD/packages
# 源码目录
SOURCE_VER=4.2
SOURCE_NAME=ffmpeg-$SOURCE_VER
SOURCE_EXT="tar.bz2"
SOURCE_PATH=$PACKAGE_PATH/$SOURCE_NAME
BUILD_LIB_PATH=$CWD/"libs/ffmpeg"
DOWNLOAD_URL="http://www.ffmpeg.org/releases/$SOURCE_NAME.$SOURCE_EXT"

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

preBuild() {
  echo "【$SOURCE_NAME】1. 准备..."
  # delFile $SOURCE_PATH
  delFile $BUILD_LIB_PATH
  delFile $BUILD_SCRATCH

  if [[  ! -f "$SOURCE_PATH.$SOURCE_EXT" ]]; then
    wget -P $PACKAGE_PATH $DOWNLOAD_URL || { echo "download error"; exit 1; }
  fi

  if [[  ! -d "$SOURCE_PATH" ]]; then
      echo "【$SOURCE_NAME】2. 解压..."
      if [[ "$SOURCE_EXT" == "tar.gz" ]];then
        tar -zxvf "$SOURCE_PATH.$SOURCE_EXT" -C  $PACKAGE_PATH/  || { echo "unzip error"; exit 1; }
      elif [[ "$SOURCE_EXT" == "tar.bz2" ]]; then
        tar -jxvf "$SOURCE_PATH.$SOURCE_EXT" -C  $PACKAGE_PATH/  || { echo "unzip error"; exit 1; }
      elif [[ "$SOURCE_EXT" == "zip" ]]; then
        unzip -d $PACKAGE_PATH/ "$SOURCE_PATH.$SOURCE_EXT"  || { echo "unzip error"; exit 1; }
      fi
  fi
}

postBuild() {
  # delFile $SOURCE_PATH
  delFile $BUILD_SCRATCH
}





EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""
PKG_CONFIG_HOST_BINARY=/usr/local/bin/pkg-config

configure()
{
    CPU=$1
    PREFIX=$BUILD_LIB_PATH/$CPU
    x264=$CWD/libs/x264/$CPU
    fdkaac=$CWD/libs/fdk-aac/$CPU
    HOST=""
    CROSS_PREFIX=""
    SYSROOT=""
    ARCH=""
    TOOLCHAIN=""
    ARCH2=""
    CC=""
    NM=""
    EXTRA_ENABLE_DISABLE=""
    echo "x264 lib: $x264"
    echo "fdk-aac lib: $fdkaac"
    if [ "$CPU" == "armeabi-v7a" ]
    then
        ARCH="arm"
        ARCH2="arm-linux-androideabi"
        HOST=arm-linux
        SYSROOT=$NDK/platforms/android-$API/arch-arm/
        TOOLCHAIN=$NDK/toolchains/$ARCH2-4.9/prebuilt/$HOST_PLATFORM
        CROSS_PREFIX=$TOOLCHAIN/bin/$ARCH2-
        EXTRA_CFLAGS="-I$NDK/sysroot/usr/include/arm-linux-androideabi"
        EXTRA_LDFLAGS="-marm"
        CC=${CROSS_PREFIX}gcc
        NM=${CROSS_PREFIX}nm
    elif [[ "$CPU" == "arm64-v8a" ]]; then
        ARCH="aarch64"
        ARCH2="aarch64-linux-android"
        HOST=aarch64-linux
        SYSROOT=$NDK/platforms/android-$API/arch-arm64/
        TOOLCHAIN=$NDK/toolchains/$ARCH2-4.9/prebuilt/$HOST_PLATFORM
        CROSS_PREFIX=$TOOLCHAIN/bin/$ARCH2-
        EXTRA_CFLAGS="-I$NDK/sysroot/usr/include/aarch64-linux-android"
        EXTRA_LDFLAGS=""
        CC=${CROSS_PREFIX}gcc
        NM=${CROSS_PREFIX}nm
    elif [[ "$CPU" == "x86" ]]; then
        ARCH="x86"
        ARCH2="i686-linux-android"
        HOST=i686-linux
        SYSROOT=$NDK/platforms/android-$API/arch-x86/
        TOOLCHAIN=$NDK/toolchains/$ARCH-4.9/prebuilt/$HOST_PLATFORM
        CROSS_PREFIX=$TOOLCHAIN/bin/$ARCH2-
        EXTRA_CFLAGS="-I$NDK/sysroot/usr/include/i686-linux-android"
        EXTRA_LDFLAGS="-lm"
        CC=${CROSS_PREFIX}gcc
        NM=${CROSS_PREFIX}nm
        # for x86: libffmpeg.so has text relocations
        EXTRA_ENABLE_DISABLE="--disable-asm"
    fi

    mkdir -p "$BUILD_SCRATCH/$ARCH"
    cd "$BUILD_SCRATCH/$ARCH"

  # --enable-nonfree: 64位必需，否则ffmpeg使用时提示：
  # libfdk_aac is incompatible with the gpl and --enable-nonfree is not specified.

    $SOURCE_PATH/configure \
    --prefix=$PREFIX \
    --target-os=android \
    --cross-prefix=$CROSS_PREFIX \
    --arch=$ARCH \
    --enable-cross-compile \
    --enable-jni \
    --sysroot=$SYSROOT \
    --extra-cflags="$EXTRA_CFLAGS -Os -fPIC -D__ANDROID_API__=$API -I$NDK/sysroot/usr/include -I$x264/include -I$fdkaac/include" \
    --extra-ldflags=" $EXTRA_LDFLAGS -L$x264/lib -L$fdkaac/lib" \
    --cc=$CC \
    --nm=$NM \
    --extra-libs=-ldl \
    --extra-libs=-lgcc \
    --disable-doc \
    --disable-ffplay \
    --disable-network \
    --disable-doc \
    --enable-ffmpeg \
    --enable-avresample \
    --disable-symver \
    --disable-encoders \
    --disable-decoders \
    --enable-avdevice \
    --enable-static \
    --disable-shared \
    --enable-neon \
    --enable-libx264 \
    --enable-libfdk-aac \
    --enable-gpl \
    --enable-pic \
    --enable-jni \
    --enable-nonfree \
    --enable-pthreads \
    --enable-mediacodec \
    --enable-encoder=aac \
    --enable-encoder=libmp3lame \
    --enable-encoder=libwavpack \
    --enable-encoder=libx264 \
    --enable-encoder=mpeg4 \
    --enable-encoder=pcm_s16le \
    --enable-encoder=text \
    --enable-decoder=aac \
    --enable-decoder=aac_latm \
    --enable-decoder=mp3 \
    --enable-decoder=mpeg4_mediacodec \
    --enable-decoder=pcm_s16le \
    --enable-decoder=vp8_mediacodec \
    --enable-decoder=h264_mediacodec \
    --enable-decoder=hevc_mediacodec \
    --enable-hwaccel=h264_mediacodec \
    --enable-hwaccel=mpeg4_mediacodec \
    --enable-bsf=aac_adtstoasc \
    --enable-bsf=h264_mp4toannexb \
    --enable-bsf=hevc_mp4toannexb \
    --enable-bsf=mpeg4_unpack_bframes \
    $EXTRA_ENABLE_DISABLE \
    $ADDITIONAL_CONFIGURE_FLAG
}

build()
{
    # make clean
    cpu=$1
    echo "build $cpu"
    
    configure $cpu || { echo "config error"; exit 1; }
    echo "$PREFIX"

    make clean
    make -j4   || { echo "compile error"; exit 1; }
    make install

    echo "编译完毕，将多个.a文件合并为一个so文件"
    ${CROSS_PREFIX}ld \
    -rpath-link=$SYSROOT/usr/lib \
    -L$SYSROOT/usr/lib \
    -L$PREFIX/lib \
    -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o \
    $PREFIX/libffmpeg.so \
    $x264/lib/libx264.a \
    $fdkaac/lib/libfdk-aac.a \
    $PREFIX/lib/libavcodec.a \
    $PREFIX/lib/libavfilter.a \
    $PREFIX/lib/libavformat.a \
    $PREFIX/lib/libavdevice.a \
    $PREFIX/lib/libavresample.a \
    $PREFIX/lib/libavutil.a \
    $PREFIX/lib/libpostproc.a \
    $PREFIX/lib/libswresample.a \
    $PREFIX/lib/libswscale.a \
    -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker \
    $TOOLCHAIN/lib/gcc/$ARCH2/4.9.x/libgcc.a
    # 注：4.9在更高ndk版本中变为4.9.x
}

preBuild
echo "【$SOURCE_NAME】3. 编译以下 架构"
FIRST_ARCH=""
BUILD_LIB_ALL_PATH="$BUILD_LIB_PATH/all"
for _ARCH in $ARCHS
do
    if [[ "$FIRST_ARCH" == "" ]]; then
        FIRST_ARCH=$_ARCH
    fi
    build $_ARCH
    mkdir -p $BUILD_LIB_ALL_PATH/lib/$_ARCH
    cp -af $BUILD_LIB_PATH/$_ARCH/libffmpeg.so $BUILD_LIB_ALL_PATH/lib/$_ARCH/
done

# 保存fftools
# libs
#  |_ ffmpeg
#       |_ include
#            |_ compat
#            |_ libavcodec
#            |_ ...
#       |_ lib
#       |    |_ armeabi-v7a
#       |         |_ libffmpeg.so
#       |    |_ ...
#       |_ fftools
#            |_ config.h
#            |_ ffmpeg.c
#            
echo "拷贝fftools"
cp -af $BUILD_LIB_PATH/$FIRST_ARCH/include $BUILD_LIB_ALL_PATH/include
cp -af $SOURCE_PATH/fftools $BUILD_LIB_ALL_PATH/fftools

if [[ -f "$BUILD_SCRATCH/aarch64/config.h" ]]; then
    cp -af $BUILD_SCRATCH/aarch64/config.h $BUILD_LIB_ALL_PATH/fftools/
elif [[ -f "$BUILD_SCRATCH/arm/config.h" ]]; then
    cp -af $BUILD_SCRATCH/arm/config.h $BUILD_LIB_ALL_PATH/fftools/
elif [[ -f "$BUILD_SCRATCH/x86/config.h" ]]; then
    cp -af $BUILD_SCRATCH/x86/config.h $BUILD_LIB_ALL_PATH/fftools/
fi
if [ ! -d "$BUILD_LIB_ALL_PATH/include/compat" ]; then
	mkdir -p $BUILD_LIB_ALL_PATH/include/compat
fi
cp -af $SOURCE_PATH/compat/va_copy.h $BUILD_LIB_ALL_PATH/include/compat/
cp -af $SOURCE_PATH/libavutil/libm.h $BUILD_LIB_ALL_PATH/include/libavutil/
cp -af $SOURCE_PATH/libavutil/thread.h $BUILD_LIB_ALL_PATH/include/libavutil/
cp -af $SOURCE_PATH/libavutil/internal.h $BUILD_LIB_ALL_PATH/include/libavutil/
cp -af $SOURCE_PATH/libavutil/timer.h $BUILD_LIB_ALL_PATH/include/libavutil/
if [ ! -d "$BUILD_LIB_ALL_PATH/include/libavutil/aarch64" ]; then
	mkdir $BUILD_LIB_ALL_PATH/include/libavutil/aarch64
fi
cp -af $SOURCE_PATH/libavutil/aarch64/timer.h $BUILD_LIB_ALL_PATH/include/libavutil/aarch64/
if [ ! -d "$BUILD_LIB_ALL_PATH/include/libavutil/arm" ]; then
	mkdir $BUILD_LIB_ALL_PATH/include/libavutil/arm
fi
cp -af $SOURCE_PATH/libavutil/arm/timer.h $BUILD_LIB_ALL_PATH/include/libavutil/arm/
if [ ! -d "$BUILD_LIB_ALL_PATH/include/libavutil/x86" ]; then
	mkdir $BUILD_LIB_ALL_PATH/include/libavutil/x86
fi
cp -af $SOURCE_PATH/libavutil/x86/timer.h $BUILD_LIB_ALL_PATH/include/libavutil/x86/
cp -af $SOURCE_PATH/libavcodec/mathops.h $BUILD_LIB_ALL_PATH/include/libavcodec/
cp -af $SOURCE_PATH/libavutil/reverse.h $BUILD_LIB_ALL_PATH/include/libavutil/
cp -af $SOURCE_PATH/libavformat/os_support.h $BUILD_LIB_ALL_PATH/include/libavformat/
cp -af $SOURCE_PATH/libavformat/network.h $BUILD_LIB_ALL_PATH/include/libavformat/
cp -af $SOURCE_PATH/libavformat/url.h $BUILD_LIB_ALL_PATH/include/libavformat/

# replace variable "class" in fftools/cmdutils.c
CMD_UTILS_C="$BUILD_LIB_ALL_PATH/fftools/cmdutils.c"
CMD_UTILS_H="$BUILD_LIB_ALL_PATH/fftools/cmdutils.h"
sed -i "s/class, int flags/_class, int flags/" $CMD_UTILS_C
sed -i "s/class->option/_class->option/" $CMD_UTILS_C
sed -i "s/class, NULL, flags/_class, NULL, flags/" $CMD_UTILS_C
sed -i "s/(class, child)/(_class, child)/" $CMD_UTILS_C
sed -i "s/class, int flags/_class, int flags/" $CMD_UTILS_H
sed -i "s/\"0x%\"PRIx64/\"0x%\" PRIx64/" $CMD_UTILS_H

FFMPEG_C="$BUILD_LIB_ALL_PATH/fftools/ffmpeg.c"
FFMPEG_H="$BUILD_LIB_ALL_PATH/fftools/ffmpeg.h"
sed -i "s/main(int argc/ffmpeg_main(int argc/" $FFMPEG_C
sed -i "667aint ffmpeg_main(int argc, char **argv);" $FFMPEG_H


echo "【$SOURCE_NAME】4. 清除工作..."
postBuild
