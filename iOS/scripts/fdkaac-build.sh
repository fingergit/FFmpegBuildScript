#!/bin/sh

# 源文件包
SRC_NAME="fdk-aac-2.0.1"
SRC_ZIP="$SRC_NAME.tar.gz"
# 脚本中的源文件夹名，需要将SRC_NAME改为此值
SRC_RENAME="fdk-aac-0.1.5"
# 构建脚本包
BUILD_NAME="fdk-aac-build-script-for-iOS-master"
BUILD_ZIP="$BUILD_NAME.zip"
# 构建脚本名
BUILD_FILE="build-fdk-aac.sh"
# 生成的库所在路径名
BUILD_FAT_PATH="fdk-aac-ios"
# 中间编译的临时文件路径
BUILD_SCRATCH_PATH="scratch"
BUILD_THIN_PATH="thin"
CWD=`pwd`

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
	delFile "$CWD/$SRC_NAME"
	delFile "$CWD/$SRC_RENAME"
	delFile "$CWD/$BUILD_NAME"
	delFile "$CWD/$BUILD_SCRATCH_PATH"
	delFile "$CWD/$BUILD_THIN_PATH"
	delFile "$CWD/$BUILD_FILE"
}

# 在编译前的准备工作
preBuild() {
	doClean
	delFile "$CWD/$BUILD_FAT_PATH"

	if [[ ! -f $CWD/$SRC_ZIP ]]; then
		echo "downloading $SRC_ZIP"
		curl -O "https://nchc.dl.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-2.0.1.tar.gz"
	fi
	if [[ ! -f $CWD/$BUILD_ZIP ]]; then
		echo "downloading $BUILD_ZIP"
		curl -o $BUILD_ZIP -O "https://codeload.github.com/fingergit/fdk-aac-build-script-for-iOS/zip/master"
	fi
}

postBuild() {
	doClean
}

echo "准备编译..."

preBuild

echo "解压..."
tar -zxvf $SRC_ZIP
unzip $BUILD_ZIP

echo "改名..."
mv $SRC_NAME $SRC_RENAME
mv $BUILD_NAME/$BUILD_FILE ./$BUILD_FILE

echo "编译thin版本"
source $BUILD_FILE arm64 x86_64

echo "删除临时文件"
postBuild

echo "执行完毕"
