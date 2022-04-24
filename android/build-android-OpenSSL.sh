#!/bin/bash
set -e
set -x

# Set directory
SCRIPT_PATH=`realpath .`
export ANDROID_NDK_HOME=$HOME/android/sdk/ndk/22.1.7171670
LIB_NAME=openssl
SRC_DIR=$HOME/repos/openssl-OpenSSL_1_1_1n
OUTPUT_PATH=$SCRIPT_PATH/output/$LIB_NAME

# Specify the toolchain path for your build machine
TOOLCHAIN_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

# Set compiler clang, instead of gcc by default
CC=clang

# Add toolchains bin directory to PATH
export PATH=$TOOLCHAIN_PATH/bin:$PATH

# Set the Android API levels
ANDROID_API=22

# List all the target arch
ARCH_LIST=( android-arm android-arm64 android-x86 android-x86_64 )

# Also list the ABI names for output directory
ABI_LIST=( armeabi-v7a arm64-v8a x86 x86_64 )

# List built libraries
BUILT_LIBS=( crypto ssl )

# Build for each target platform
NUM_ARCH=${#ARCH_LIST[@]}
for ((i=0; i<NUM_ARCH; i++))
do
    # Set the target ARCH
    ARCH=${ARCH_LIST[i]}
    
    # Create build directory
    [ -d $SRC_DIR/build ] && rm -r $SRC_DIR/build
    mkdir $SRC_DIR/build
    cd $SRC_DIR/build

	# Create make file
    ../Configure $ARCH -D__ANDROID_API__=$ANDROID_API
    
    # Build
    make -j32
    
    # Copy the outputs
    OUTPUT_INCLUDE=$OUTPUT_PATH/include
    OUTPUT_LIB=$OUTPUT_PATH/lib/${ABI_LIST[i]}
    [ ! -d $OUTPUT_INCLUDE ] && mkdir -p $OUTPUT_INCLUDE && cp -RL $SRC_DIR/include/openssl $OUTPUT_INCLUDE
    mkdir -p $OUTPUT_LIB
    for j in ${BUILT_LIBS[@]}
    do
        cp lib${j}.a $OUTPUT_LIB
		cp lib${j}.so $OUTPUT_LIB
    done
done
