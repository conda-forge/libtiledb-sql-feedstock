#!/bin/sh
set -exo pipefail

export CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}

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

if [[ $target_platform == osx-arm64  ]]; then
  export CMAKE_SYSTEM_NAME_SETTING="-DCMAKE_SYSTEM_NAME=Darwin"
fi

# tools
mkdir host
cd host
cmake ${CMAKE_SYSTEM_NAME_SETTING} -DSTACK_DIRECTION=1 ..
make import_executables
cd ..


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
