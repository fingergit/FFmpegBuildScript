#!/bin/sh

echo "Building fdk-aac..."
bash fdkaac-build.sh

echo "Building x264..."
bash x264-build.sh

echo "Building ffmpeg..."
bash ffmpeg-build-single.sh
