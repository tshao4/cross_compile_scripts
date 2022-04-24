#!/bin/bash

# build script for GameNetworkSockets by ValveSoftware
# checkout https://github.com/tshao4/GameNetworkSockets for a fork that adds support for building for Android

set -e
set -x

# Set directory
SCRIPT_PATH=`realpath .`
DEPENDENCY_LIB_DIR=$HOME/output
export ANDROID_NDK_HOME=$HOME/android/sdk/ndk/22.1.7171670
LIB_NAME=GameNetworkingSockets
SRC_DIR=$HOME/repos/GameNetworkingSockets-1.4.0
OUTPUT_PATH=$SCRIPT_PATH/output/$LIB_NAME
USE_WEBRTC=ON

# List of target ABIs
ABI_LIST=( armeabi-v7a arm64-v8a x86 x86_64 )

# Set the Android API levels
ANDROID_API=22

# Build for each target ABI
NUM_ABI=${#ABI_LIST[@]}
for ((i=0; i<NUM_ABI; i++))
do
	# Set the target ABI
    ABI=${ABI_LIST[i]}
	
	# Create build directory
    [ -d $SRC_DIR/build ] && rm -r $SRC_DIR/build
    mkdir $SRC_DIR/build
    cd $SRC_DIR/build

    # Create ninja build script
    PREFIX=$SRC_DIR/build/output/${ABI_LIST[i]}
    cmake . ../ \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
        -DProtobuf_INCLUDE_DIR=$DEPENDENCY_LIB_DIR/protobuf/include \
        -DProtobuf_LIBRARY=$DEPENDENCY_LIB_DIR/protobuf/lib/$ABI/libprotobuf.a \
        -DProtobuf_LITE_LIBRARY=$DEPENDENCY_LIB_DIR/protobuf/lib/$ABI/libprotobuf-lite.a \
        -DProtobuf_LIBRARIES=$DEPENDENCY_LIB_DIR/protobuf/lib/$ABI/libprotobuf.a \
        -DOPENSSL_INCLUDE_DIR=$DEPENDENCY_LIB_DIR/openssl/include \
        -DOPENSSL_SSL_LIBRARY=$DEPENDENCY_LIB_DIR/openssl/lib/$ABI/libssl.a \
        -DOPENSSL_CRYPTO_LIBRARY=$DEPENDENCY_LIB_DIR/openssl/lib/$ABI/libcrypto.a \
        -DCMAKE_SYSTEM_NAME=Android \
        -DOPENSSL_HAS_25519_RAW=on \
        -DCMAKE_CXX_FLAGS="-fPIC" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_ANDROID_ARCH_ABI=$ABI \
        -DANDROID_ABI=$ABI \
        -DCMAKE_SYSTEM_VERSION=$ANDROID_API \
        -DANDROID_PLATFORM=android-$ANDROID_API \
        -DUSE_STEAMWEBRTC=$USE_WEBRTC \
        -GNinja

	# Build
	ninja
    ninja install
    
    # Copy the outputs
    OUTPUT_INCLUDE=$OUTPUT_PATH/include
    OUTPUT_LIB=$OUTPUT_PATH/lib/${ABI_LIST[i]}
    [ ! -d $OUTPUT_INCLUDE ] && mkdir -p $OUTPUT_INCLUDE && cp -RL $PREFIX/include/GameNetworkingSockets $OUTPUT_INCLUDE
    mkdir -p $OUTPUT_LIB

	cp $PREFIX/lib/lib${LIB_NAME}_s.a $OUTPUT_LIB
	cp $PREFIX/lib/lib${LIB_NAME}.so $OUTPUT_LIB
done
