
project('wget2', 'c')

# 预构建依赖库的路径 (请根据实际情况调整！)
xz_dir = 'dependencies/xz/build/install'
zstd_dir = 'dependencies/zstd/build/install'
zlib_ng_dir = 'dependencies/zlib-ng/build/install'
gmp_dir = 'dependencies/gmp/build/install'
libiconv_dir = 'dependencies/libiconv/build/install'
libunistring_dir = 'dependencies/libunistring/build/install'
libidn2_dir = 'dependencies/libidn2/build/install'
libtasn1_dir = 'dependencies/libtasn1/build/install'
pcre2_dir = 'dependencies/pcre2/build/install'
nghttp2_dir = 'dependencies/nghttp2/build/install'
dlfcn_dir = 'dependencies/dlfcn-win32/build/install'
libmicrohttpd_dir = 'dependencies/libmicrohttpd/build/install'
libpsl_dir = 'dependencies/libpsl/build/install'
nettle_dir = 'dependencies/nettle/build/install'
gnutls_dir = 'dependencies/gnutls/build/install'

# 交叉编译设置
cross_file = configuration_data()
cross_file.set('c_args', ['-mwindows'])
cross_file.set('cpp_args', ['-mwindows'])
cross_file.set('link_args', ['-static', '-s'])


# 声明依赖库
xz = dependency('xz', fallback : [include_directories: xz_dir, libraries: xz_dir])
zstd = dependency('zstd', fallback : [include_directories: zstd_dir, libraries: zstd_dir])
zlib_ng = dependency('zlib-ng', fallback : [include_directories: zlib_ng_dir, libraries: zlib_ng_dir])
gmp = dependency('gmp', fallback : [include_directories: gmp_dir, libraries: gmp_dir])
libiconv = dependency('libiconv', fallback : [include_directories: libiconv_dir, libraries: libiconv_dir])
libunistring = dependency('libunistring', fallback : [include_directories: libunistring_dir, libraries: libunistring_dir])
libidn2 = dependency('libidn2', fallback : [include_directories: libidn2_dir, libraries: libidn2_dir])
libtasn1 = dependency('libtasn1', fallback : [include_directories: libtasn1_dir, libraries: libtasn1_dir])
pcre2 = dependency('pcre2', fallback : [include_directories: pcre2_dir, libraries: pcre2_dir])
nghttp2 = dependency('nghttp2', fallback : [include_directories: nghttp2_dir, libraries: nghttp2_dir])
dlfcn = dependency('dlfcn', fallback : [include_directories: dlfcn_dir, libraries: dlfcn_dir])
libmicrohttpd = dependency('libmicrohttpd', fallback : [include_directories: libmicrohttpd_dir, libraries: libmicrohttpd_dir])
libpsl = dependency('libpsl', fallback : [include_directories: libpsl_dir, libraries: libpsl_dir])
nettle = dependency('nettle', fallback : [include_directories: nettle_dir, libraries: nettle_dir])
gnutls = dependency('gnutls', fallback : [include_directories: gnutls_dir, libraries: gnutls_dir])


# 定义wget2可执行文件
executable('wget2', 'wget2/src/wget2.c',
           dependencies: [libiconv, gnutls, libpsl, lzma, zstd, pcre2, nghttp2, dlfcn, libmicrohttpd, nettle],
           c_args: cross_file.get('c_args'),
           cpp_args: cross_file.get('cpp_args'),
           link_args: cross_file.get('link_args'))
