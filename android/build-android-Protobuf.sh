#!/bin/bash
set -e
set -x

# Set directory
SCRIPT_PATH=`realpath .`
export ANDROID_NDK_HOME=$HOME/android/sdk/ndk/22.1.7171670
LIB_NAME=protobuf
SRC_DIR=$HOME/repos/protobuf-3.6.1
OUTPUT_PATH=$SCRIPT_PATH/output/$LIB_NAME
PROTOC_PATH=/usr/bin/protoc

# Specify the toolchain path for your build machine
TOOLCHAIN_PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

# Add toolchains bin directory to PATH
export PATH=$TOOLCHAIN_PATH/bin:$PATH

# Set the Android API levels
ANDROID_API=22

# List arch for toolchain file name
TOOLCHAIN_LIST=( armv7a-linux-androideabi aarch64-linux-android i686-linux-android x86_64-linux-android )

# List all the target arch
ARCH_LIST=( armv7-a arm64v8-a i686 x86-64 )

# Also list the ABI names for output directory
ABI_LIST=( armeabi-v7a arm64-v8a x86 x86_64 )

# List built libraries
BUILT_LIBS=( protobuf protobuf-lite )

# Generate configure script
cd $SRC_DIR
bash $SRC_DIR/autogen.sh

# Build for each target platform
NUM_ARCH=${#ARCH_LIST[@]}
for ((i=0; i<NUM_ARCH; i++))
do
    # Set the target ARCH
    ARCH=${ARCH_LIST[i]}
    TOOLCHAIN_NAME=${TOOLCHAIN_LIST[i]}

    export SYSROOT=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot
    export CC="$TOOLCHAIN_NAME$ANDROID_API-clang --sysroot $SYSROOT"
    export CXX="$TOOLCHAIN_NAME$ANDROID_API-clang++ --sysroot $SYSROOT"
    
    # Create build directory
    [ -d $SRC_DIR/build ] && rm -r $SRC_DIR/build
    mkdir $SRC_DIR/build
    cd $SRC_DIR/build

	# Create make file
    PREFIX=$SRC_DIR/build/output/${ABI_LIST[i]}
    ../configure \
        --prefix=$PREFIX \
        --host=${TOOLCHAIN_LIST[i]} \
        --with-sysroot=$SYSROOT \
        --enable-shared \
        --enable-cross-compile \
        --with-protoc=$PROTOC_PATH \
        CFLAGS="-march=$ARCH -D__ANDROID_API__=$ANDROID_API" \
        CXXFLAGS="-fPIC -frtti -fexceptions -march=$ARCH -D__ANDROID_API__=$ANDROID_API" \
        LIBS="-llog -lz -lc++_static"
    
    # Build
    make -j32
    make install
    
    # Copy the outputs
    OUTPUT_INCLUDE=$OUTPUT_PATH/include
    OUTPUT_LIB=$OUTPUT_PATH/lib/${ABI_LIST[i]}
    [ ! -d $OUTPUT_INCLUDE ] && mkdir -p $OUTPUT_INCLUDE && cp -RL $PREFIX/include/google $OUTPUT_INCLUDE
    mkdir -p $OUTPUT_LIB
    for j in ${BUILT_LIBS[@]}
    do
        cp $PREFIX/lib/lib${j}.a $OUTPUT_LIB
        cp $PREFIX/lib/lib${j}.so $OUTPUT_LIB

        # Generate symbol table
        llvm-ranlib $OUTPUT_LIB/lib${j}.a
    done
done
