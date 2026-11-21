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

CC_BIN="$CLANG_BIN/clang"
if command -v ccache >/dev/null 2>&1; then
  export CCACHE_DIR="${CCACHE_DIR:-$HOME/.ccache}"
  export CCACHE_MAXSIZE="${CCACHE_MAXSIZE:-1.5G}"
  export CCACHE_COMPRESS=1
  export CCACHE_COMPILERCHECK="string:clang-r383902"
  export CCACHE_BASEDIR="$ROOT_DIR"
  export CCACHE_SLOPPINESS=file_macro,time_macros
  ccache -z
  CC_WRAPPER="/tmp/ccache-clang-wrapper.sh"
  printf '#!/bin/sh\nexec ccache "%s" "$@"\n' "$CLANG_BIN/clang" > "$CC_WRAPPER"
  chmod +x "$CC_WRAPPER"
  CC_BIN="$CC_WRAPPER"
fi

MAKE_ARGS=(
  ARCH=arm64
  CC="$CC_BIN"
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

if command -v ccache >/dev/null 2>&1; then
  ccache -s || true
fi

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
