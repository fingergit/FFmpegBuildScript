#!/bin/sh

# 源文件包
SRC_NAME="x264-stable"
SRC_ZIP="$SRC_NAME.tar.bz2"
# 脚本中的源文件夹名，需要将SRC_NAME改为此值
SRC_RENAME="x264"
# 构建脚本包
BUILD_NAME="x264-ios-master"
BUILD_ZIP="$BUILD_NAME.zip"
# 构建脚本名
BUILD_FILE="build-x264.sh"
# 生成的库所在路径名
BUILD_FAT_PATH="x264-iOS"
# 中间编译的临时文件路径
BUILD_SCRATCH_PATH="scratch-x264"
BUILD_THIN_PATH="thin-x264"

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

# 清除编译内容
doClean() {
	delFile $SRC_NAME
	delFile $SRC_RENAME
	delFile $BUILD_NAME
	delFile $BUILD_SCRATCH_PATH
	delFile $BUILD_THIN_PATH
	delFile $BUILD_FILE
}

# 在编译前的准备工作
preBuild() {
	doClean
	delFile $BUILD_FAT_PATH

	if [[ ! -f $CWD/$SRC_ZIP ]]; then
		echo "downloading $SRC_ZIP"
		curl -O "https://code.videolan.org/videolan/x264/-/archive/stable/$SRC_ZIP"
	fi
	if [[ ! -f $CWD/$BUILD_ZIP ]]; then
		echo "downloading $BUILD_ZIP"
		curl -o $BUILD_ZIP -O "https://codeload.github.com/fingergit/x264-ios/zip/master"
	fi
}

postBuild() {
	doClean
}

echo "准备编译..."

preBuild

echo "解压..."
tar -jxvf $SRC_ZIP
unzip $BUILD_ZIP

echo "改名..."
mv $SRC_NAME $SRC_RENAME
mv $BUILD_NAME/$BUILD_FILE ./$BUILD_FILE

echo "编译thin版本"
source $BUILD_FILE arm64 x86_64
echo "将thin变为fat"
source $BUILD_FILE lipo

echo "删除临时文件"
postBuild

echo "执行完毕"
