#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export ARCH=arm64
export SUBARCH=arm64
export PLATFORM_VERSION=14
export ANDROID_MAJOR_VERSION=u

if [ ! -e drivers/kernelsu/Kconfig ]; then
  rm -rf KernelSU drivers/kernelsu
  git clone --depth=1 https://github.com/rsuntk/KernelSU.git KernelSU
  ln -sf ../KernelSU/kernel drivers/kernelsu
fi

CLANG_BIN="$ROOT_DIR/toolchain/clang/host/linux-x86/clang-r383902/bin"
export PATH="$CLANG_BIN:$PATH"

MAKE_ARGS=(
  ARCH=arm64
  CC="$CLANG_BIN/clang"
  CLANG_TRIPLE=aarch64-linux-gnu-
  CROSS_COMPILE=aarch64-linux-gnu-
  LD=ld.lld
  AR=llvm-ar
  NM=llvm-nm
  OBJCOPY=llvm-objcopy
  OBJDUMP=llvm-objdump
  STRIP=llvm-strip
)

make "${MAKE_ARGS[@]}" physwizz_defconfig
make "${MAKE_ARGS[@]}" -j"$(nproc)" Image dtbs

if [ ! -f arch/arm64/boot/Image ]; then
  echo "ERROR: arch/arm64/boot/Image was not generated!"
  exit 1
fi

cp -f arch/arm64/boot/Image AnyKernel3/Image
mkdir -p out
cp -f arch/arm64/boot/Image out/Image
cp -f arch/arm64/boot/dts/exynos/exynos3830.dtb out/exynos3830.dtb || true

(
  cd AnyKernel3
  rm -f ../out/physwizz-A135-OC-Max.zip
  zip -r9 ../out/physwizz-A135-OC-Max.zip . -x "*.git*"
)

echo "Build complete: out/physwizz-A135-OC-Max.zip"
