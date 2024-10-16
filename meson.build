project('aria2', 'c')

# 依赖库路径
zlib_dir = 'dependencies/zlib/build/install'
zlib_ng_dir = 'dependencies/zlib-ng/build/install' #如果需要zlib-ng
libxml2_dir = 'dependencies/libxml2/build/install'
cares_dir = 'dependencies/c-ares/build/install'
openssl_dir = 'dependencies/openssl/build/install'
sqlite_dir = 'dependencies/sqlite/build/install'


# 声明依赖库
zlib = dependency('zlib', fallback : [include_directories : zlib_dir, libraries : zlib_dir])
zlib_ng = dependency('zlib-ng', fallback : [include_directories : zlib_ng_dir, libraries : zlib_ng_dir]) #如果需要zlib-ng
libxml2 = dependency('libxml2', fallback : [include_directories : libxml2_dir, libraries : libxml2_dir])
cares = dependency('c-ares', fallback : [include_directories : cares_dir, libraries : cares_dir])
openssl = dependency('openssl', fallback : [include_directories : openssl_dir, libraries : openssl_dir])
sqlite = dependency('sqlite3', fallback : [include_directories : sqlite_dir, libraries : sqlite_dir])


# 定义 aria2c 可执行文件
executable('aria2c', 'aria2-src/src/aria2c.c',
           include_directories : ['aria2-src/src', zlib_dir, libxml2_dir, cares_dir, openssl_dir, sqlite_dir], # 添加include_directories
           dependencies : [zlib, libxml2, cares, openssl, sqlite],
           c_args : ['-mwindows'],
           link_args: ['-static', '-s'])
