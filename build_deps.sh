#!/bin/bash -e

export PREFIX="x86_64-w64-mingw32"
export INSTALLDIR="dependencies"

# Create cross-file.txt
cat <<EOF > cross_file.txt
[binaries]
c = 'x86_64-w64-mingw32-gcc'
cpp = 'x86_64-w64-mingw32-g++'
ar = 'x86_64-w64-mingw32-ar'
strip = 'x86_64-w64-mingw32-strip'
exe_wrapper = 'wine64'
[host_machine]
system = 'windows'
cpu_family = 'x86_64'
cpu = 'x86_64'
endian = 'little'
EOF

build_dep() {
  local dep="$1"
  local url="$2"
  local options="$3"
  local tmp_dir

  tmp_dir=$(mktemp -d)  # 创建临时目录

  echo "正在构建依赖库: $dep"

  if [[ "$url" == *.git ]]; then
    git clone --depth 1 "$url" "$tmp_dir"
  else
    wget -O "$tmp_dir/$dep.tar.gz" "$url"
    tar -xf "$tmp_dir/$dep.tar.gz" -C "$tmp_dir"
    rm "$tmp_dir/$dep.tar.gz"
  fi

  mkdir -p "dependencies/$dep"  # 创建最终的依赖库目录
  mv "$tmp_dir/*" "dependencies/$dep"  # 将内容移动到正确的位置
  rm -rf "$tmp_dir"  # 删除临时目录

  cd "dependencies/$dep"
  meson setup build --cross-file=../cross_file.txt --backend=ninja "$options"
  ninja -C build
  ninja -C build install
  cd ..
}

build_dep xz https://github.com/tukaani-project/xz.git "--prefix=$INSTALLDIR --enable-static --disable-shared"
build_dep zstd https://github.com/facebook/zstd.git "--prefix=$INSTALLDIR -Dbin_programs=true -Dstatic_runtime=true -Ddefault_library=static -Db_lto=true --optimization=2"
build_dep "zlib-ng" https://github.com/zlib-ng/zlib-ng.git "--prefix=$INSTALLDIR --static --64 --zlib-compat"
build_dep gmp https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz "--host=$PREFIX --disable-shared --prefix=$INSTALLDIR"
build_dep libiconv https://ftp.gnu.org/gnu/libiconv/libiconv-1.17.tar.gz "--build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --prefix=$INSTALLDIR"
build_dep libunistring https://ftp.gnu.org/gnu/libunistring/libunistring-1.3.tar.gz "CFLAGS=-O3 --build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --prefix=$INSTALLDIR"
build_dep libidn2 https://ftp.gnu.org/gnu/libidn/libidn2-2.3.7.tar.gz "--build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --disable-doc --disable-gcc-warnings --prefix=$INSTALLDIR"
build_dep libtasn1 https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.19.0.tar.gz "--host=$PREFIX --disable-shared --disable-doc --prefix=$INSTALLDIR"
build_dep pcre2 https://github.com/PCRE2Project/pcre2.git "--host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static"
build_dep nghttp2 https://github.com/nghttp2/nghttp2/releases/download/v1.63.0/nghttp2-1.63.0.tar.gz "--build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-shared --enable-static --disable-python-bindings --disable-examples --disable-app --disable-failmalloc --disable-hpack-tools"
build_dep "dlfcn-win32" https://github.com/dlfcn-win32/dlfcn-win32.git "--prefix=$PREFIX --cc=$PREFIX-gcc"
build_dep libmicrohttpd https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz "--build=x86_64-pc-linux-gnu --host=$PREFIX --prefix=$INSTALLDIR --disable-doc --disable-examples --disable-shared --enable-static"
build_dep libpsl https://github.com/rockdaboot/libpsl.git "--build=x86_64-pc-linux-gnu --host=$PREFIX --disable-shared --enable-static --enable-runtime=libidn2 --enable-builtin --prefix=$INSTALLDIR"
build_dep nettle https://github.com/sailfishos-mirror/nettle.git "--build=x86_64-pc-linux-gnu --host=$PREFIX --enable-mini-gmp --disable-shared --enable-static --disable-documentation --prefix=$INSTALLDIR"
build_dep gnutls https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.3.tar.xz "CFLAGS=-O3 --host=$PREFIX --prefix=$INSTALLDIR --disable-openssl-compatibility --disable-hardware-acceleration --disable-shared --enable-static --without-p11-kit --disable-doc --disable-tests --disable-full-test-suite --disable-tools --disable-cxx --disable-maintainer-mode --disable-libdane"
