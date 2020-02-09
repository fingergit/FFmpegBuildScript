#!/bin/sh

echo "Building fdk-aac..."
sh fdkaac-build.sh

echo "Building x264..."
sh x264-build.sh

echo "Building ffmpeg..."
sh ffmpeg-build.sh
