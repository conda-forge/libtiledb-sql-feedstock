#!/bin/sh
set -exo pipefail

original_dir=$PWD
export MARIADB_VERSION="mariadb-10.5.13"
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
export CMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}

if [[ $CONDA_BUILD_CROSS_COMPILATION -eq 1 ]]; then
  # cross-compiling on macOS
  export EXTRA_XC_ARGS="-DSTACK_DIRECTION=1"

  if [[ $target_platform =~ osx.* ]]; then
    EXTRA_XC_ARGS="${EXTRA_XC_ARGS} -DHAVE_IB_GCC_ATOMIC_BUILTINS=1"
  fi
fi

echo "CMAKE_ARGS is: " "'${CMAKE_ARGS}'"
echo "EXTRA_XC_ARGS is: " "'${EXTRA_XC_ARGS}'"

#tar xf ${MARIADB_VERSION}.tar.gz \
# Copy LICENSE File
cp ${MARIADB_VERSION}/COPYING .
mv tmp ${MARIADB_VERSION}/storage/mytile
cd ${MARIADB_VERSION}
mkdir builddir
cd builddir
cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
         ${CMAKE_ARGS} \
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
         ..
make -j ${CPU_COUNT} || true # TODO REMOVE ME - debuggin
make -j1 # TODO REMOVE ME - debuggin
make install
