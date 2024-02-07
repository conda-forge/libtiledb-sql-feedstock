#!/bin/sh
set -exo pipefail

original_dir=$PWD
export MARIADB_VERSION="mariadb-11.0.2"
mkdir tmp
shopt -s extglob
mv !(tmp) tmp # Move everything but tmp
git clone https://github.com/MariaDB/server.git -b ${MARIADB_VERSION} ${MARIADB_VERSION}

CFLAGS="${CFLAGS} -Wno-error=deprecated-declarations"
CXXFLAGS="${CXXFLAGS} -Wno-error=deprecated-declarations"
if [[ $target_platform =~ osx.* ]]; then
  export CFLAGS="${CFLAGS} -ULIBICONV_PLUG"
  export CXXFLAGS="${CXXFLAGS} -ULIBICONV_PLUG"
fi

#tar xf ${MARIADB_VERSION}.tar.gz \
# Copy LICENSE File
cp ${MARIADB_VERSION}/COPYING .
mv tmp ${MARIADB_VERSION}/storage/mytile
cd ${MARIADB_VERSION}

# Save current values of the variables
OLD_CC=$CC
OLD_CXX=$CXX
OLD_CPP=$CPP
OLD_CFLAGS=$CFLAGS
OLD_LDFLAGS=$LDFLAGS
OLD_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
OLD_AR=$AR
OLD_RANLIB=$RANLIB
OLD_LD=$LD

if [[ $target_platform == osx-arm64  ]]; then

  export CC=${CC_FOR_BUILD} \
              CXX=${CXX_FOR_BUILD} \
              CPP="${CC_FOR_BUILD} -E" \
              CFLAGS="-O2" \
  	          LDFLAGS=${LDFLAGS//${PREFIX}/${CONDA_PREFIX}} \
  	          PKG_CONFIG_PATH=${BUILD_PREFIX}/lib/pkgconfig \
              AR="$(${CC_FOR_BUILD} --print-prog-name=ar)" \
              RANLIB="$(${CC_FOR_BUILD} --print-prog-name=ranlib)" \
              LD="$(${CC_FOR_BUILD} --print-prog-name=ld)" && mkdir host && cd host && cmake -DCMAKE_PREFIX_PATH=$BUILD_PREFIX .. && make import_executables && cd ..

  export CMAKE_SYSTEM_NAME_SETTING="-DCMAKE_SYSTEM_NAME=Darwin"
fi

# Restore previous values of the variables
CC=$OLD_CC
CXX=$OLD_CXX
CPP=$OLD_CPP
CFLAGS=$OLD_CFLAGS
LDFLAGS=$OLD_LDFLAGS
PKG_CONFIG_PATH=$OLD_PKG_CONFIG_PATH
AR=$OLD_AR
RANLIB=$OLD_RANLIB
LD=$OLD_LD

export CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}

mkdir builddir
cd builddir
cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
         -DCMAKE_PREFIX_PATH=$PREFIX \
         -DPLUGIN_INNODB=NO \
         -DPLUGIN_INNOBASE=NO \
         -DPLUGIN_TOKUDB=NO \
         -DPLUGIN_ROCKSDB=NO \
         -DPLUGIN_MROONGA=NO \
         -DPLUGIN_SPIDER=NO \
         -DPLUGIN_SPHINX=NO \
         -DPLUGIN_FEDERATED=NO \
         -DPLUGIN_FEDERATEDX=NO \
         -DPLUGIN_CONNECT=NO \
         -DPLUGIN_PERFSCHEMA=NO \
         -DPLUGIN_AUTH_PAM=NO \
         -DPLUGIN_AUTH_PAM_V1=NO \
         -DPLUGIN_AUTH_GSSAPI=NO \
         -DWITH_SSL=system \
         -DCMAKE_BUILD_TYPE=Release \
         -SWITH_DEBUG=0 \
         -DWITH_EMBEDDED_SERVER=ON \
         -DWITH_UNIT_TESTS=OFF \
         -DINSTALL_MYSQLTESTDIR= \
         -DWITH_WSREP=OFF \
         -DIMPORT_EXECUTABLES=../host/import_executables.cmake \
         -DSTACK_DIRECTION=1 \
         -DHAVE_IB_GCC_ATOMIC_BUILTINS=1 \
         -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET} \
          ${CMAKE_SYSTEM_NAME_SETTING} \
         ..
make -j ${CPU_COUNT}
make install
