#!/bin/bash -e

export PREFIX="x86_64-w64-mingw32"
export INSTALLDIR="dependencies"

# 创建 cross_file.txt (保持不变)
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

  tmp_dir=$(mktemp -d)
  echo "正在构建依赖: $dep 来自 $url"

  if [[ "$url" == *.git ]]; then
    git clone --depth 1 --progress "$url" "$tmp_dir" || exit 1
  else
    wget --progress=dot -O "$tmp_dir/$dep.tar.gz" "$url" || exit 1
    echo "正在解压文件: $tmp_dir/$dep.tar.gz 到目录: $tmp_dir"
    
    # 检查下载文件是否存在
    if [[ ! -f "$tmp_dir/$dep.tar.gz" ]]; then
        echo "下载文件不存在: $tmp_dir/$dep.tar.gz"
        exit 1
    fi

    tar -xf "$tmp_dir/$dep.tar.gz" -C "$tmp_dir" || exit 1
    echo "解压结果: $? 目录内容: $(ls $tmp_dir)"
    rm "$tmp_dir/$dep.tar.gz"
  fi

  # 检查解压后的目录（具体目录名可能需要根据依赖调整）
  if [[ ! -d "$tmp_dir/xz-5.6.3" ]]; then
      echo "错误: 克隆或解压 $dep 失败"
      exit 1
  fi

  mkdir -p "dependencies/$dep"
  mv "$tmp_dir/xz-5.6.3" "dependencies/$dep"
  rm -rf "$tmp_dir"

  cd "dependencies/$dep"
  echo "正在运行 meson setup..."
  meson setup build --cross-file=../cross_file.txt --backend=ninja "$options" || exit 1
  echo "Meson setup 输出: $? 目录内容: $(ls build)"
  echo "正在运行 ninja..."
  ninja -C build || exit 1
  echo "Ninja 输出: $? 目录内容: $(ls build)"
  echo "正在运行 ninja install..."
  ninja -C build install || exit 1
  echo "Ninja install 输出: $? 目录内容: $(ls ..)"
  cd ..
}

build_dep xz https://github.com/tukaani-project/xz/releases/download/v5.6.3/xz-5.6.3.tar.gz "--prefix=$INSTALLDIR --enable-static --disable-shared"
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
