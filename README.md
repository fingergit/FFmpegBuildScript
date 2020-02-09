# FFmpegBuildScript
Build FFmpeg scripts for iOS and Android with x264 and fdk-aac.

## Build for Android

### Prepair

- Launch Ubuntu. (Test version: [ubuntu-18.04.3-live-server-amd64.iso](http://releases.ubuntu.com/18.04.3/ubuntu-18.04.3-live-server-amd64.iso?_ga=2.166730430.1634624385.1581214309-378137246.1579744325))

- Download NDK: Build suppport:
  - [android-ndk-r10e-linux-x86_64.zip](https://dl.google.com/android/repository/android-ndk-r10e-linux-x86_64.zip)
  - [android-ndk-r16b-linux-x86_64.zip](https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip)

- Unzip `android-ndk-r10e-linux-x86_64.zip` or `android-ndk-r16b-linux-x86_64.zip` to `~/ffmpeg/packages/` folder.

  ```text
  $ sudo apt install unzip
  $ sudo apt-get install make
  $ sudo apt-get install build-essential
  $ sudo apt-get install nasm
  $ cd ~
  $ mkdir ffmpeg
  $ cd ffmpeg
  $ mkdir packages
  $ cd packages
  $ wget https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
  ```

- Copy Android scripts to `~/ffmpeg`, Result:

  ```shell
  ffmpeg
    |_ packages
    | |_ android-ndk-r10e
    |_ scripts
       |_ fdkaac-build.sh
       |_ ffmpeg-build-single.sh
       |_ full-build.sh
       |_ x264-build.sh
  ```

  - Run: `bash full-build.sh`
  
## Build for iOS

- Go to `iOS/scripts` folder.
- Run `sh full-build.sh`.
