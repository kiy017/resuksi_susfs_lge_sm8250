#!/usr/bin/env bash

set -e
TOOLCHAIN_BIN="/home/yuki/kernel/toolchains/clang-r563880c/bin" 

# Verify the toolchain path exists before continuing
if [ ! -d "$TOOLCHAIN_BIN" ]; then
    echo "Error: Toolchain directory not found at $TOOLCHAIN_BIN"
    exit 1
fi

export PATH="$TOOLCHAIN_BIN:$PATH"

export ARCH=arm64
export SUBARCH=arm64
OUT_DIR="$(pwd)/out"

# Build configuration variables
DEFCONFIG="timelm_defconfig"
CUSTOM_NAME="-kiyomitest"

echo "Using Clang version:"
clang --version

echo "--- Step 1: Initializing Defconfig ---"
make O=$OUT_DIR $DEFCONFIG \
    LLVM=1 \
    LLVM_IAS=1 \
    CLANG_TRIPLE=aarch64-linux-gnu-

echo "--- Step 2: Compiling Kernel ---"
make -j$(nproc --all) O=$OUT_DIR \
    LLVM=1 \
    LLVM_IAS=1 \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    LOCALVERSION=$CUSTOM_NAME \
    Image.gz dtbs

echo "--- Step 3: Verifying Build Outputs ---"
if [ -f "$OUT_DIR/arch/arm64/boot/Image.gz" ]; then
    echo "Success! Merging Image.gz and DTBs..."
    cat $OUT_DIR/arch/arm64/boot/Image.gz $(find $OUT_DIR/arch/arm64/boot/dts/ -name "*.dtb") > $OUT_DIR/arch/arm64/boot/Image.gz-dtb
    echo "Generated output: $OUT_DIR/arch/arm64/boot/Image.gz-dtb"
else
    echo "Build failed: Image.gz was not generated."
    exit 1
fi
