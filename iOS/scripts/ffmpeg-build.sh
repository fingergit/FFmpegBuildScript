#!/bin/sh

# 源文件包
SRC_NAME="ffmpeg-4.2"
SRC_ZIP=""
# 脚本中的源文件夹名，需要将SRC_NAME改为此值
SRC_RENAME="ffmpeg-4.2"
# 构建脚本包
BUILD_NAME="FFmpeg-iOS-build-script-master"
BUILD_ZIP="$BUILD_NAME.zip"
# 构建脚本名
BUILD_FILE="build-ffmpeg.sh"
# 生成的库所在路径名
BUILD_FAT_PATH="FFmpeg-iOS"
# 中间编译的临时文件路径
BUILD_SCRATCH_PATH="scratch"
BUILD_THIN_PATH="thin"

BUILD_X264_FILE="x264-autobuild.sh"
BUILD_AAC_FILE="fdk-aac-autobuild.sh"

# 删除文件或文件夹
delFile() {
	if [ ! $1 ];then
		echo "参数不存在"
	elif [ ! -f $1 -a ! -d $1 ];then
		echo "文件不存在"
	elif [ "$1" == "/" -o "$1" == "" ];then	
		echo "无效文件夹"
	else
		rm -rf $1
	fi
}

# 清除编译内容
doClean() {
	# delFile $SRC_NAME
	# delFile $SRC_RENAME
	delFile $BUILD_NAME
	# delFile $BUILD_SCRATCH_PATH
	delFile $BUILD_THIN_PATH
	delFile $BUILD_FILE
}

# 在编译前的准备工作
preBuild() {
	if [ ! -d "x264-iOS" ];then
		sh $BUILD_X264_FILE
	fi
	if [ ! -d "fdk-aac-ios" ];then
		sh $BUILD_AAC_FILE
	fi

	doClean
	delFile $BUILD_FAT_PATH
	delFile $BUILD_SCRATCH_PATH
}

postBuild() {
	doClean
}

echo "准备编译..."

preBuild

echo "解压..."
if [ "$SRC_ZIP" != "" ];then
	tar -jxvf $SRC_ZIP
fi
unzip $BUILD_ZIP

echo "改名..."
if [ $SRC_NAME != $SRC_RENAME ]; then
    mv $SRC_NAME $SRC_RENAME
fi
mv $BUILD_NAME/$BUILD_FILE ./$BUILD_FILE

echo "修改脚本内容"
sed -i '' '17c\
X264=`pwd`/x264-iOS
 ' $BUILD_FILE
sed -i '' '19c\
FDK_AAC=`pwd`/fdk-aac-ios
# ' $BUILD_FILE
# sed -i '' '23a\
# CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-network --disable-avdevice --disable-muxers --disable-filters --disable-postproc --enable-small"\
# CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-decoders --enable-decoder=h264 --enable-decoder=aac --enable-decoder=mpeg4 --enable-decoder=hevc --enable-decoder=mp3"\
# CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-encoders --enable-encoder=aac --enable-encoder=h264 --enable-encoder=mpeg4"\
# CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"\
# \
# ' $BUILD_FILE
sed -i '' '23a\
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-decoders --enable-decoder=h264 --enable-decoder=aac --enable-decoder=mpeg4 --enable-decoder=hevc --enable-decoder=mp3"\
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --disable-encoders --enable-encoder=aac --enable-encoder=h264 --enable-encoder=mpeg4"\
CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample --enable-small"\
\
' $BUILD_FILE

echo "编译thin版本"
source $BUILD_FILE arm64 x86_64
echo "将thin变为fat"
source $BUILD_FILE lipo

echo "拷贝fftools"
cp -af $SRC_RENAME/fftools $BUILD_FAT_PATH/fftools
cp -af $BUILD_SCRATCH_PATH/arm64/config.h $BUILD_FAT_PATH/fftools/
if [ ! -d "$BUILD_FAT_PATH/include/compat" ]; then
	mkdir $BUILD_FAT_PATH/include/compat
fi
cp -af $SRC_RENAME/compat/va_copy.h $BUILD_FAT_PATH/include/compat/
cp -af $SRC_RENAME/libavutil/libm.h $BUILD_FAT_PATH/include/libavutil/
cp -af $SRC_RENAME/libavutil/thread.h $BUILD_FAT_PATH/include/libavutil/
cp -af $SRC_RENAME/libavutil/internal.h $BUILD_FAT_PATH/include/libavutil/
cp -af $SRC_RENAME/libavutil/timer.h $BUILD_FAT_PATH/include/libavutil/
if [ ! -d "$BUILD_FAT_PATH/include/libavutil/aarch64" ]; then
	mkdir $BUILD_FAT_PATH/include/libavutil/aarch64
fi
cp -af $SRC_RENAME/libavutil/aarch64/timer.h $BUILD_FAT_PATH/include/libavutil/aarch64/
if [ ! -d "$BUILD_FAT_PATH/include/libavutil/arm" ]; then
	mkdir $BUILD_FAT_PATH/include/libavutil/arm
fi
cp -af $SRC_RENAME/libavutil/arm/timer.h $BUILD_FAT_PATH/include/libavutil/arm/
if [ ! -d "$BUILD_FAT_PATH/include/libavutil/x86" ]; then
	mkdir $BUILD_FAT_PATH/include/libavutil/x86
fi
cp -af $SRC_RENAME/libavutil/x86/timer.h $BUILD_FAT_PATH/include/libavutil/x86/
cp -af $SRC_RENAME/libavcodec/mathops.h $BUILD_FAT_PATH/include/libavcodec/
cp -af $SRC_RENAME/libavutil/reverse.h $BUILD_FAT_PATH/include/libavutil/
cp -af $SRC_RENAME/libavformat/os_support.h $BUILD_FAT_PATH/include/libavformat/
cp -af $SRC_RENAME/libavformat/network.h $BUILD_FAT_PATH/include/libavformat/
cp -af $SRC_RENAME/libavformat/url.h $BUILD_FAT_PATH/include/libavformat/

echo "删除临时文件"
postBuild

echo "执行完毕"
