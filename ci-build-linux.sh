#!/bin/bash

echo "hello world"

echo "artifakt: $BUILD_ARTIFACT tag: $APPVEYOR_REPO_TAG_NAME pwd: $(pwd)"

gcc --version

# https://redmine.bring.out.ba/issues/35387

# sudo dpkg --add-architecture i386
curl -LO https://dl.bintray.com/hernad/harbour/hb-linux-i386.tar.gz

if [ "$BUILD_ARCH" == "ia32" ] ; then
   curl -L https://dl.bintray.com/hernad/harbour/hb-linux-i386.tar.gz > l.tar.gz
else
   exit 1
fi

export HB_PLATFORM=linux
export HB_ROOT=$(pwd)/hb-linux-i386
#export HB_USER_CFLAGS=-m32
#export HB_USER_DFLAGS='-m32 -L/usr/lib32'
#export HB_USER_LDFLAGS='-m32 -L/usr/lib32'

apt-get update -y
apt install -y g++ gcc libc6 \
     libx11-dev libpcre3-dev libssl-dev \
     libncurses5 libstdc++6 lib32stdc++6  libpq-dev lib32z1

PATH=$HB_ROOT/bin:$PATH

echo $PATH

export F18_VER=${BUILD_BUILDNUMBER}
scripts/update_f18_ver_ch.sh $F18_VER

export LX_UBUNTU=1
#source scripts/set_envars.sh

export F18_POS=1
export F18_RNAL=0
export F18_GT_CONSOLE=1
hbmk2 -workdir=.h F18.hbp

#cp -av /usr/lib/i386-linux-gnu/libpq.so* .

zip F18_${BUILD_ARTIFACT}_${APPVEYOR_REPO_TAG_NAME}.zip F18
