#!/bin/sh
NDK=~/ffmpeg/packages/android-ndk-r16b
# NDK=~/ffmpeg/packages/android-ndk-r10e
API=21
# HOST_PLATFORM=darwin-x86_64
HOST_PLATFORM=linux-x86_64

ARCHS="armeabi-v7a arm64-v8a x86"
# ARCHS="armeabi-v7a"

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

function preBuild {
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

function postBuild {
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
    --extra-cflags="$EXTRA_CFLAGS -Os -fpic -D__ANDROID_API__=$API -I$NDK/sysroot/usr/include -I$x264/include -I$fdkaac/include" \
    --extra-ldflags=" $EXTRA_LDFLAGS -L$x264/lib -L$fdkaac/lib" \
    --cc=$CC \
    --nm=$NM \
    --extra-libs=-ldl \
    --extra-libs=-lgcc \
    --disable-everything \
    --disable-encoders \
    --disable-decoders \
    --disable-avdevice \
    --enable-static \
    --disable-doc \
    --disable-ffplay \
    --disable-network \
    --disable-doc \
    --disable-symver \
    --enable-neon \
    --disable-shared \
    --enable-libx264 \
    --enable-libfdk-aac \
    --enable-gpl \
    --enable-pic \
    --enable-jni \
    --enable-nonfree \
    --enable-pthreads \
    --enable-mediacodec \
    --enable-encoder=aac \
    --enable-encoder=gif \
    --enable-encoder=libopenjpeg \
    --enable-encoder=libmp3lame \
    --enable-encoder=libwavpack \
    --enable-encoder=libx264 \
    --enable-encoder=mpeg4 \
    --enable-encoder=pcm_s16le \
    --enable-encoder=png \
    --enable-encoder=srt \
    --enable-encoder=subrip \
    --enable-encoder=yuv4 \
    --enable-encoder=text \
    --enable-decoder=aac \
    --enable-decoder=aac_latm \
    --enable-decoder=libopenjpeg \
    --enable-decoder=mp3 \
    --enable-decoder=mpeg4_mediacodec \
    --enable-decoder=pcm_s16le \
    --enable-decoder=flac \
    --enable-decoder=flv \
    --enable-decoder=gif \
    --enable-decoder=png \
    --enable-decoder=srt \
    --enable-decoder=xsub \
    --enable-decoder=yuv4 \
    --enable-decoder=vp8_mediacodec \
    --enable-decoder=h264_mediacodec \
    --enable-decoder=hevc_mediacodec \
    --enable-hwaccel=h264_mediacodec \
    --enable-hwaccel=mpeg4_mediacodec \
    --enable-ffmpeg \
    --enable-bsf=aac_adtstoasc \
    --enable-bsf=h264_mp4toannexb \
    --enable-bsf=hevc_mp4toannexb \
    --enable-bsf=mpeg4_unpack_bframes \
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
for ARCH in $ARCHS
do
    build $ARCH
done

echo "【$SOURCE_NAME】4. 清除工作..."
postBuild
