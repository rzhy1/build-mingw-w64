project('aria2', 'c')

# 依赖库路径 (直接指向库文件和头文件)
zlib_inc = 'dependencies/zlib/include'
zlib_lib = 'dependencies/zlib/lib/libzlib.a'
zlib_ng_inc = 'dependencies/zlib-ng/include' #如果需要zlib-ng
zlib_ng_lib = 'dependencies/zlib-ng/lib/libz.a' #如果需要zlib-ng
libxml2_inc = 'dependencies/libxml2/include'
libxml2_lib = 'dependencies/libxml2/lib/libxml2.a'
cares_inc = 'dependencies/c-ares/include'
cares_lib = 'dependencies/c-ares/lib/libcares.a'
sqlite_inc = 'dependencies/sqlite/include'
sqlite_lib = 'dependencies/sqlite/lib/libsqlite3.a'


# 声明依赖库，直接使用预编译库，避免系统查找
zlib = declare_dependency(
    include_directories : zlib_inc,
    libraries : zlib_lib
)

zlib_ng = declare_dependency(
    include_directories : zlib_ng_inc,
    libraries : zlib_ng_lib
) #如果需要zlib-ng

libxml2 = declare_dependency(
    include_directories : libxml2_inc,
    libraries : libxml2_lib
)

cares = declare_dependency(
    include_directories : cares_inc,
    libraries : cares_lib
)

sqlite = declare_dependency(
    include_directories : sqlite_inc,
    libraries : sqlite_lib
)


# 定义 aria2c 可执行文件
executable('aria2c', 'aria2-src/src/aria2c.c',
           include_directories : 'aria2-src/src',
           dependencies : [zlib, libxml2, cares, sqlite],  # OpenSSL 已移除
           c_args : ['-mwindows'],
           link_args: ['-static', '-s'])
