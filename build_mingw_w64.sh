#!/bin/bash
#
# Copyright (C) 2024 Kyle Schwarz <zeranoe@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#ROOT_PATH="${{ github.workspace }}/mingw-w64"

MINGW_W64_BRANCH="master"
BINUTILS_BRANCH="binutils-2_45-branch"
GCC_BRANCH="master"
#GCC_BRANCH="releases/gcc-14"

ENABLE_THREADS="--enable-threads=win32"

JOB_COUNT=$(($(getconf _NPROCESSORS_ONLN) + 2))

LINKED_RUNTIME="msvcrt"

show_help()
{
cat <<EOF
Usage:
  $0 [options] <arch>...

Archs:
  x86_64  Windows 64-bit

Options:
  -h, --help                   show help
  -j <count>, --jobs <count>   override make job count (default: $JOB_COUNT)
  -p <path>, --prefix <path>   install location (default: $ROOT_PATH/<arch>)
  -r <path>, --root <path>     location for sources, build artifacts and the resulting compiler (default: $ROOT_PATH)
  --keep-artifacts             don't remove source and build files after a successful build
  --disable-threads            disable pthreads and STL <thread>
  --cached-sources             use existing sources instead of downloading new ones
  --binutils-branch <branch>   set Binutils branch (default: $BINUTILS_BRANCH)
  --gcc-branch <branch>        set GCC branch (default: $GCC_BRANCH)
  --mingw-w64-branch <branch>  set MinGW-w64 branch (default: $MINGW_W64_BRANCH)
  --linked-runtime <runtime>   set MinGW Linked Runtime (default: $LINKED_RUNTIME)
EOF
}

error_exit()
{
    local error_msg="$1"
    shift 1

    if [ "$error_msg" ]; then
        printf "%s\n" "$error_msg" >&2
    else
        printf "an error occured\n" >&2
    fi
    exit 1
}

arg_error()
{
    local error_msg="$1"
    shift 1

    error_exit "$error_msg, see --help for options" "$error_msg"
}

execute() {
  local info_msg="$1"
  local error_msg="$2"
  shift 2

  if [ ! "$error_msg" ]; then
    error_msg="error"
  fi

  if [ "$info_msg" ]; then
    printf "(%d/%d): %s... " "$CURRENT_STEP" "$TOTAL_STEPS" "$info_msg"
    local start_time=$(date +%s%N)
    CURRENT_STEP=$((CURRENT_STEP + 1))
  fi

  "$@" >>"$LOG_FILE" 2>&1 || error_exit "$error_msg, check $LOG_FILE for details"

  if [ "$info_msg" ]; then
    local end_time=$(date +%s%N)
    local elapsed_time=$(( (end_time - start_time) / 1000000000 ))
    printf "(用时: %s s)\n" "$elapsed_time"
  fi
}

create_dir()
{
    local path="$1"
    shift 1

    execute "" "unable to create directory '$path'" \
        mkdir -p "$path"
}

remove_path()
{
    local path="$1"
    shift 1

    execute "" "unable to remove path '$path'" \
        rm -fr "$path"
}

change_dir()
{
    local path="$1"
    shift 1

    execute "" "unable to cd to directory '$path'" \
        cd "$path"
}

download_sources()
{
    remove_path "$SRC_PATH"
    create_dir "$SRC_PATH"
    change_dir "$SRC_PATH"

    execute "downloading MinGW-w64 source" "" git clone --depth 1 -b "$MINGW_W64_BRANCH" https://github.com/mingw-w64/mingw-w64.git mingw-w64 &
    execute "downloading Binutils source" "" git clone --depth 1 -b "$BINUTILS_BRANCH" https://sourceware.org/git/binutils-gdb.git binutils &
    execute "downloading GCC source" "" git clone --depth 1 -b "$GCC_BRANCH" https://gcc.gnu.org/git/gcc.git gcc &   
    wait
    #execute "initializing and setting up GCC repository" "failed to setup GCC repository" \
    #  bash -c "git init gcc && cd gcc && git remote add origin https://gcc.gnu.org/git/gcc.git && git fetch --depth 1 origin e97179bacd067ccd3ee765632e0c034df152ccb6 && git checkout e97179bacd067ccd3ee765632e0c034df152ccb6"
    # execute "downloading config.guess" "" curl -o config.guess "https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD" &
    execute "downloading config.guess" "" curl -o config.guess "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess" &   
    wait
    
}

build()
{
    local arch="$1"
    local prefix="$2"
    shift 2

    local bld_path="$BLD_PATH/$arch"
    local host="$arch-w64-mingw32"

    export PATH="$prefix/bin:$PATH"

    remove_path "$bld_path"
    # don't remove a user defined prefix (could be /usr/local)
    if [ ! "$PREFIX" ]; then
        remove_path "$prefix"
    fi
    
    local x86_dwarf2=""
    local crt_lib="--enable-lib64 --disable-lib32"

    create_dir "$bld_path/binutils"
    change_dir "$bld_path/binutils"
    execute "($arch): configuring Binutils" "" \
        "$SRC_PATH/binutils/configure" --prefix="$prefix" --disable-shared \
            --enable-static --with-sysroot="$prefix" --target="$host" \
            --disable-multilib --disable-nls --enable-lto --disable-gdb
    execute "($arch): building Binutils" "" \
        make -j $JOB_COUNT
    execute "($arch): installing Binutils" "" \
        make install
    
    create_dir "$bld_path/mingw-w64-headers"
    change_dir "$bld_path/mingw-w64-headers"
    execute "($arch): configuring MinGW-w64 headers" "" \
        "$SRC_PATH/mingw-w64/mingw-w64-headers/configure" --build="$BUILD" \
            --host="$host" --prefix="$prefix/$host" \
            --with-default-msvcrt=$LINKED_RUNTIME
    execute "($arch): installing MinGW-w64 headers" "" \
        make install
        
    create_dir "$bld_path/gcc"
    change_dir "$bld_path/gcc"
    execute "($arch): configuring GCC" "" \
            "$SRC_PATH/gcc/configure" --target="$host" --disable-shared \
            --enable-static --disable-multilib --prefix="$prefix" \
            --enable-languages=c,c++ --disable-nls $ENABLE_THREADS \
            $x86_dwarf2
    execute "($arch): building GCC (all-gcc)" "" \
        make -j $JOB_COUNT all-gcc
    execute "($arch): installing GCC (install-gcc)" "" \
        make install-gcc
    
    create_dir "$bld_path/mingw-w64-crt"
    change_dir "$bld_path/mingw-w64-crt"
    execute "($arch): configuring MinGW-w64 CRT" "" \
        "$SRC_PATH/mingw-w64/mingw-w64-crt/configure" --build="$BUILD" \
            --host="$host" --prefix="$prefix/$host" \
            --with-default-msvcrt=$LINKED_RUNTIME \
            --with-sysroot="$prefix/$host" $crt_lib
    execute "($arch): building MinGW-w64 CRT" "" \
        make -j $JOB_COUNT
    execute "($arch): installing MinGW-w64 CRT" "" \
        make install
    
    if [ "$ENABLE_THREADS" ]; then
        create_dir "$bld_path/mingw-w64-winpthreads"
        change_dir "$bld_path/mingw-w64-winpthreads"
        execute "($arch): configuring winpthreads" "" \
            "$SRC_PATH/mingw-w64/mingw-w64-libraries/winpthreads/configure" \
                --build="$BUILD" --host="$host" --disable-shared \
                --enable-static --prefix="$prefix/$host"
        execute "($arch): building winpthreads" "" \
            make -j $JOB_COUNT
        execute "($arch): installing winpthreads" "" \
            make install
    fi
    
    change_dir "$bld_path/gcc"
    execute "($arch): building GCC" "" \
        make -j $JOB_COUNT
    execute "($arch): installing GCC" "" \
        make install
}

while :; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -j|--jobs)
            if [ "$2" ]; then
                JOB_COUNT=$2
                shift
            else
                arg_error "'--jobs' requires a non-empty option argument"
            fi
            ;;
        -p|--prefix)
            if [ "$2" ]; then
                PREFIX="$2"
                shift
            else
                arg_error "'--prefix' requires a non-empty option argument"
            fi
            ;;
        --prefix=?*)
            PREFIX=${1#*=}
            ;;
        --prefix=)
            arg_error "'--prefix' requires a non-empty option argument"
            ;;
        -r|--root)
            if [ "$2" ]; then
                ROOT_PATH_ARG="$2"
                shift
            else
                arg_error "'--root' requires a non-empty option argument"
            fi
            ;;
        --root=?*)
            ROOT_PATH_ARG="${1#*=}"
            ;;
        --root=)
            arg_error "'--root' requires a non-empty option argument"
            ;;
        --keep-artifacts)
            KEEP_ARTIFACTS=1
            ;;
        --disable-threads)
            ENABLE_THREADS=""
            ;;
        --cached-sources)
            CACHED_SOURCES=1
            ;;
        --binutils-branch)
            if [ "$2" ]; then
                BINUTILS_BRANCH="$2"
                shift
            else
                arg_error "'--binutils-branch' requires a non-empty option argument"
            fi
            ;;
        --binutils-branch=?*)
            BINUTILS_BRANCH=${1#*=}
            ;;
        --binutils-branch=)
            arg_error "'--binutils-branch' requires a non-empty option argument"
            ;;
        --gcc-branch)
            if [ "$2" ]; then
                GCC_BRANCH="$2"
                shift
            else
                arg_error "'--gcc-branch' requires a non-empty option argument"
            fi
            ;;
        --gcc-branch=?*)
            GCC_BRANCH=${1#*=}
            ;;
        --gcc-branch=)
            arg_error "'--gcc-branch' requires a non-empty option argument"
            ;;
        --linked-runtime)
            if [ "$2" ]; then
                LINKED_RUNTIME="$2"
                shift
            else
                arg_error "'--linked-runtime' requires a non-empty option argument"
            fi
            ;;
        --linked-runtime=?*)
            LINKED_RUNTIME=${1#*=}
            ;;
        --linked-runtime=)
            arg_error "'--linked-runtime' requires a non-empty option argument"
            ;;
        --mingw-w64-branch)
            if [ "$2" ]; then
                MINGW_W64_BRANCH="$2"
                shift
            else
                arg_error "'--mingw-w64-branch' requires a non-empty option argument"
            fi
            ;;
        --mingw-w64-branch=?*)
            MINGW_W64_BRANCH=${1#*=}
            ;;
        --mingw-w64-branch=)
            arg_error "'--mingw-w64-branch' requires a non-empty option argument"
            ;;
        x86_64)
            BUILD_X86_64=1
            ;;
        --)
            shift
            break
            ;;
        -?*)
            arg_error "unknown option '$1'"
            ;;
        ?*)
            arg_error "unknown arch '$1'"
            ;;
        *)
            break
    esac

    shift
done

NUM_BUILDS=$((BUILD_X86_64))
if [ "$NUM_BUILDS" -eq 0 ]; then
    arg_error "no ARCH was specified"
fi

MISSING_EXECS=""
for exec in g++ flex bison git makeinfo m4 bzip2 curl make diff; do
    if ! command -v "$exec" >/dev/null; then
        MISSING_EXECS="$MISSING_EXECS $exec"
    fi
done
if [ "$MISSING_EXECS" ]; then
    error_exit "missing required executable(s):$MISSING_EXECS"
fi

TOTAL_STEPS=0

if [ ! "$CACHED_SOURCES" ]; then
    TOTAL_STEPS=$((TOTAL_STEPS + 4))
fi

if [ "$ENABLE_THREADS" ]; then
    THREADS_STEPS=3
else
    THREADS_STEPS=0
fi

THREADS_STEPS=$((THREADS_STEPS * NUM_BUILDS))
BUILD_STEPS=$((13 * NUM_BUILDS))

TOTAL_STEPS=$((TOTAL_STEPS + THREADS_STEPS + BUILD_STEPS))

if [ "$ROOT_PATH_ARG" ]; then
    ROOT_PATH=$(mkdir -p "$ROOT_PATH_ARG" && cd "$ROOT_PATH_ARG" && pwd)
fi

SRC_PATH="$ROOT_PATH/src"
BLD_PATH="$ROOT_PATH/bld"
LOG_FILE="$ROOT_PATH/build.log"

if [ "$PREFIX" ]; then
    X86_64_PREFIX="$PREFIX"
else
    X86_64_PREFIX="$ROOT_PATH/x86_64"
fi

CURRENT_STEP=1

# clean log file for execute()
mkdir -p "$ROOT_PATH"
rm -f "$LOG_FILE"
touch "$LOG_FILE"


if [ ! "$CACHED_SOURCES" ]; then
    download_sources
else
    if [ ! -f "$SRC_PATH/config.guess" ]; then
        arg_error "no sources found, run with --keep-artifacts first"
    fi
fi

BUILD=$(sh "$SRC_PATH/config.guess")

change_dir "$SRC_PATH/gcc"

execute "" "failed to download GCC dependencies" \
    ./contrib/download_prerequisites

for i in mpc isl mpfr gmp; do
    ln -s "$SRC_PATH/gcc/$i" "$SRC_PATH/binutils/$i"
done

export CFLAGS="-g0"
export CXXFLAGS="-g0"
export LDFLAGS="-s"

ADD_TO_PATH=()

if [ "$BUILD_X86_64" ]; then
    build x86_64 "$X86_64_PREFIX"
    ADD_TO_PATH+=("'$X86_64_PREFIX/bin'")
fi

if [ ! "$KEEP_ARTIFACTS" ]; then
    remove_path "$SRC_PATH"
    remove_path "$BLD_PATH"
    remove_path "$LOG_FILE"
fi

echo "complete, to use MinGW-w64 everywhere add these to your \$PATH:"
for add_to_path in "${ADD_TO_PATH[@]}"; do
    printf "\t%s\n" "$add_to_path"
done
exit 0
