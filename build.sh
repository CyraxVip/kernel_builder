#!/bin/bash
#
# idk lmao

maindir="$(pwd)"
outside="${maindir}/.."
zipper="${outside}/zipper"

zipper_repo=fukiame/AnyKernel3-niigo
zipper_branch=selene-old

pack() {
  if [[ ! -d ${zipper} ]]; then
    git clone https://github.com/${zipper_repo} -b ${zipper_branch} "${zipper}"
    cd "${zipper}"
  else
    cd "${zipper}"
    git reset --hard
    git checkout ${zipper_branch}
    git fetch origin ${zipper_branch}
    git reset --hard origin/${zipper_branch}
  fi
  cp -af "${maindir}/out/arch/arm64/boot/Image.gz-dtb" "${zipper}"
  zip -r9 "${maindir}/${toolchain}-${ZIP_KERNEL_VERSION}-${KERNEL_NAME}-${TIME}.zip" ./* -x .git README.md ./*placeholder
  cd "${maindir}"
}

# config
commit="$(git log --pretty=format:'%h' -1)"
export ARCH="arm64"
export SUBARCH="arm64"
export KBUILD_BUILD_USER="nijuugo-ji"
export KBUILD_BUILD_HOST="telegram-de"
defconfig="selene_defconfig"
KERNEL_NAME=$(cat "${maindir}/arch/arm64/configs/${defconfig}" | grep "CONFIG_LOCALVERSION=" | sed 's/CONFIG_LOCALVERSION="-*//g' | sed 's/"*//g' )
ZIP_KERNEL_VERSION="4.14.$(cat "${maindir}/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')$(cat "${maindir}/Makefile" | grep "EXTRAVERSION =" | sed 's/EXTRAVERSION = *//g')"
TIME=$(date +"%m%d%H%M")

# build
for toolchain in $1; do
  rm -rf out

  bash "${outside}/toolchains/${toolchain}.sh" setup

  BUILD_START=$(date +"%s")

  bash "${outside}/toolchains/${toolchain}.sh" build ${defconfig}

  if [ -e "${maindir}/out/arch/arm64/boot/Image.gz-dtb" ]; then
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    pack
    echo "build succeed in $((DIFF / 60))m, $((DIFF % 60))s"
  else
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    echo "build failed in $((DIFF / 60))m, $((DIFF % 60))s"
  fi
done