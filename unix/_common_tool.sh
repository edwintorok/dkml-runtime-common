#!/bin/sh
# ----------------------------
# Copyright 2021 Diskuv, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------
#
# @jonahbeckford: 2021-09-07
# - This file is licensed differently than the rest of the Diskuv OCaml distribution.
#   Keep the Apache License in this file since this file is part of the reproducible
#   build files.
#
#################################################
# _common_tool.sh
#
# Inputs:
#   DKMLDIR: The 'diskuv-ocaml' vendored directory containing '.dkmlroot'.
#   TOPDIR: Optional. The project top directory containing 'dune-project'. If
#     not specified it will be discovered from DKMLDIR.
#   PLATFORM: One of the PLATFORMS defined in TOPDIR/Makefile
#
#################################################

# Inputs:
# - env:PLATFORM
# Returns 0 (success) if the PLATFORM is `dev`
is_dev_platform() {
    if [ "$PLATFORM" = "dev" ]; then
        return 0
    fi
    return 1
}

# Checks whether the platform should be running in a reproducible Docker container.
#
# As of Oct 13, 2021 only Linux build hosts can run in Docker containers.
#
# Inputs:
# - env:PLATFORM
# Returns 0 (success) if the PLATFORM is not `dev` and is a Linux based platform.
is_reproducible_platform() {
    if [ "$PLATFORM" = "dev" ]; then
        return 1
    fi
    is_arg_linux_based_platform "$PLATFORM"
}

if [ ! -e "$DKMLDIR/.dkmlroot" ]; then echo "FATAL: Not embedded within or launched from a 'diskuv-ocaml' Local Project" >&2 ; exit 1; fi

# set $dkml_root_version
# shellcheck disable=SC1091
. "$DKMLDIR"/.dkmlroot
dkml_root_version=$(printf "%s" "$dkml_root_version" | PATH=/usr/bin:/bin tr -d '\r')

if [ -z "${TOPDIR:-}" ]; then
    # Check at most 10 ancestors
    if [ -n "${TOPDIR_CANDIDATE:-}" ]; then
        TOPDIR=$(cd "$TOPDIR_CANDIDATE" && PATH=/usr/bin:/bin pwd)
    else
        TOPDIR=$(cd "$DKMLDIR" && cd .. && PATH=/usr/bin:/bin pwd) # `cd ..` works if DKMLDIR is a Windows path
    fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ] && [ "$TOPDIR" != "/" ]; then TOPDIR=$(cd "$TOPDIR"/.. && PATH=/usr/bin:/bin pwd); fi
    if [ ! -e "$TOPDIR/dune-project" ]; then echo "FATAL: Not embedded in a Dune-based project with a 'dune-project' file" >&2 ; exit 1; fi
fi

# TOPDIR is sticky, so that platform-opam-exec.sh and any other scripts can be called as children and behave correctly.
export TOPDIR

if [ -x /usr/bin/cygpath ]; then
    OS_DIR_SEP="\\"
else
    # shellcheck disable=SC2034
    OS_DIR_SEP=/
fi

# Backwards compatible user mode
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    __USERMODE=OFF
else
    # shellcheck disable=SC2153
    __USERMODE="$USERMODE" # fails if USERMODE not set
fi

# Set OPAM_CACHE_SUBDIR and cache keys like WRAP_COMMANDS_KEY
# shellcheck disable=SC2034
OPAM_CACHE_SUBDIR=.dkml/opam-cache
# shellcheck disable=SC2034
WRAP_COMMANDS_CACHE_KEY=wrap-commands."$dkml_root_version"

# (Deprecated; modern version in _common_build.sh)
# The build root is where all the build files go (except _build for Dune in dev platform). Ordinarily it is a relative
# directory but can be overridden with DKML_BUILD_ROOT to be an absolute path.
# For Windows you want to use it so that you do not run into 260 character absolute path limits!
# Here is an example of a 260 character limit violation ... it is VERY HARD to see what the problem is!
#   $ (cd _build/default && D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\bin\ocamlc.opt.exe -w -40 -g -bin-annot -I expander/.ppx_sexp_conv_expander.objs/byte -I D:/a/diskuv-ocaml-starter-ghmirror/diskuv-ocaml-starter-ghmirror/build/windows_x86_64/Release/_opam/lib/ocaml\compiler-libs -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\base_internalhash_types -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\caml -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\base\shadow_stdlib -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-compiler-libs\common -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-compiler-libs\shadow -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ocaml-migrate-parsetree -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppx_derivers -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\ast -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\metaquot_lifters -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\print_diff -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\stdppx -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\ppxlib\traverse_builtins -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\sexplib0 -I D:\a\diskuv-ocaml-starter-ghmirror\diskuv-ocaml-starter-ghmirror\build\windows_x86_64\Release\_opam\lib\stdlib-shims -no-alias-deps -open Ppx_sexp_conv_expander__ -o expander/.ppx_sexp_conv_expander.objs/byte/ppx_sexp_conv_expander__Str_generate_sexp_grammar.cmi -c -intf expander/str_generate_sexp_grammar.pp.mli)
#   File "expander/str_generate_sexp_grammar.mli", line 1:
#   Error: I/O error: expander/.ppx_sexp_conv_expander.objs/byte\ppx_sexp_conv_expander__Str_generate_sexp_grammar.cmi9d73bb.tmp: No such file or directory
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    BUILD_ROOT_UNIX="${DKML_BUILD_ROOT:-build}"
    if [ -x /usr/bin/cygpath ]; then
        BUILD_ROOT_UNIX=$(/usr/bin/cygpath -u "$BUILD_ROOT_UNIX")
    fi
    case "$BUILD_ROOT_UNIX" in
    /* | ?:*) # /a/b/c or C:\Windows
        BUILD_BASEPATH=
        ;;
    *)
        # BUILD_BASEPATH will have a trailing slash
        if [ -x /usr/bin/cygpath ]; then
            BUILD_BASEPATH=$(/usr/bin/cygpath -u "$TOPDIR")/
        else
            BUILD_BASEPATH="$TOPDIR"/
        fi
        ;;
    esac
fi

# Temporary directory that needs to be accessible inside and outside of containers so shell scripts
# can be sent from the outside of a container into a container.
# So we make $WORK be a subdirectory of $TOPDIR.
# TODO: We could instead mount TMPPARENTDIR_BUILDHOST or WORK in sandbox so we can always use /tmp;
#       Cygwin in particular has absolute file path length limitations.
# Our use of mktemp needs to be portable; docs at:
# * BSD: https://www.freebsd.org/cgi/man.cgi?query=mktemp&sektion=1
# * GNU: https://www.gnu.org/software/autogen/mktemp.html
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    if [ -z "$BUILD_BASEPATH" ]; then
        # BUILD_ROOT_UNIX is absolute path
        TMPPARENTDIR_ABS_OR_RELTOP="$BUILD_ROOT_UNIX/_tmp"
        TMPPARENTDIR_BUILDHOST="${TMPPARENTDIR_BUILDHOST:-$TMPPARENTDIR_ABS_OR_RELTOP}"
    else
        TMPPARENTDIR_ABS_OR_RELTOP="build/_tmp"
        TMPPARENTDIR_BUILDHOST="${TMPPARENTDIR_BUILDHOST:-$BUILD_BASEPATH$TMPPARENTDIR_ABS_OR_RELTOP}"
    fi
else
    if [ "$__USERMODE" = OFF ]; then
        TMPPARENTDIR_ABS_OR_RELTOP="$STATEDIR/tmp"
    elif [ -n "${_CS_DARWIN_USER_TEMP_DIR:-}" ]; then # macOS (see `man mktemp`)
        TMPPARENTDIR_ABS_OR_RELTOP="$_CS_DARWIN_USER_TEMP_DIR"
    elif [ -n "${TMPDIR:-}" ]; then # macOS (see `man mktemp`)
        TMPPARENTDIR_ABS_OR_RELTOP=$(printf "%s" "$TMPDIR" | PATH=/usr/bin:/bin sed 's#/$##') # remove trailing slash on macOS
    elif [ -n "${TMP:-}" ]; then # MSYS2 (Windows), Linux
        TMPPARENTDIR_ABS_OR_RELTOP="$TMP"
    else
        TMPPARENTDIR_ABS_OR_RELTOP="/tmp"
    fi
    TMPPARENTDIR_BUILDHOST="${TMPPARENTDIR_BUILDHOST:-$TMPPARENTDIR_ABS_OR_RELTOP}"
fi
[ ! -e "$TMPPARENTDIR_BUILDHOST" ] && install -d "$TMPPARENTDIR_BUILDHOST"
WORK=$(PATH=/usr/bin:/bin mktemp -d "$TMPPARENTDIR_BUILDHOST"/dkmlw.XXXXX)
trap 'PATH=/usr/bin:/bin rm -rf "$WORK"' EXIT

# shellcheck disable=SC1091
. "$DKMLDIR/vendor/drc/unix/crossplatform-functions.sh"

#####
# BEGIN Opam
#
# Windows
# -------
#
# Terminology: "port" is msvc or mingw, and described in https://discuss.ocaml.org/t/ann-ocaml-opam-images-for-docker-for-windows/8179
#
# We want to consistently use MSVC compiled libraries and executables so we don't have to debug hard-to-resolve cross-compiler
# issues ... we are using MSVC elsewhere (especially CMake) since it is far more widely adopted; it has way more package support.
# The only exception is when we are trying to compile a native Windows opam.exe within Cygwin. When using our Cygwin setup and the
# 4.12.0+msvc64 variant the ./autoconf for the package `ocaml-variants` detects the MSVC compiler and the Cygwin ld.exe which causes
# the build to break. So for bootstrapping opam.exe we use MinGW. (We don't expect this to happen with MSYS2 since MSYS2 is tested
# for this common cross-compiling on Windows scenario).
#
# We are downloading (install-world.ps1 / moby-download-docker-image.sh) the Docker `amd64`
# architecture (https://hub.docker.com/r/ocaml/opam/tags?page=1&ordering=last_updated&name=windows)
# for our binaries.
# shellcheck disable=SC2034
OPAM_ARCH_IN_WINDOWS=amd64
#
# Which port we will use for all the switches in Windows.
#
# shellcheck disable=SC2034
OPAM_PORT_FOR_SWITCHES_IN_WINDOWS=msvc
#
# Which variant we will use for all the switches in Windows.
# Pick from a msys2 variant in $DiskuvOCamlHome/etc/repos/diskuv-opam-repository
# that aligns with the OPAM_PORT_FOR_SWITCHES_IN_WINDOWS.
set_ocaml_variant_for_windows_switches() {
    set_ocaml_variant_for_windows_switches_VERSION="$1"
    shift
    export OCAML_VARIANT_FOR_SWITCHES_IN_32BIT_WINDOWS="$set_ocaml_variant_for_windows_switches_VERSION"+options+dkml+msvc32
    export OCAML_VARIANT_FOR_SWITCHES_IN_64BIT_WINDOWS="$set_ocaml_variant_for_windows_switches_VERSION"+options+dkml+msvc64
}
#
# END
#####

# Execute a command either for the dev environment or for the
# reproducible sandbox corresponding to `$PLATFORM`
# which must be defined.
#
# When the optional `$BUILDTYPE` is non-empty the build type and
# corresponding environment variables (`DK_BUILD_TYPE`) will
# be available in the platform.
#
# Options:
#   -c                    - Optional. If enabled then compilation environment variables
#                           like CC will be added to the environment. This may be
#                           time-consuming, especially on Windows which needs to call
#                           VsDevCmd.bat
# Inputs:
#   env:PLATFORM          - (deprecated) optional. which platform to run in
#   env:BUILDTYPE         - optional
#   env:PLATFORM_EXEC_PRE_SINGLE - optional. acts as hook.
#                           the specified bash statements, if any, are 'eval'-d _before_ the
#                           command line arguments are executed.
#   env:PLATFORM_EXEC_PRE_DOUBLE - optional. acts as hook.
#                           the specified bash statements, if any, are executed
#                           and their standard output captured. that standard
#                           output is 'dos2unix'-d and 'eval'-d _before_ the
#                           command line arguments are executed.
#                           You can think of it behaving like:
#                             eval "$PLATFORM_EXEC_PRE_DOUBLE" | dos2unix > /tmp/eval.sh
#                             eval /tmp/eval.sh
#   $@                    - the command line arguments that will be executed
#
# (Deprecated functionality) The text of the arguments $@, PLATFORM_EXEC_PRE_SINGLE and
# PLATFORM_EXEC_PRE_DOUBLE have their macros expanded:
#
#   @@EXPAND_TOPDIR@@: The top project directory containing `dune-project`.
#     When running in MSYS2 the directory will be Windows style (ex. C:\)
exec_in_platform() {
    # option parsing
    if [ "$1" = "-c" ]; then
        _exec_dev_or_arch_helper_COMPILATION=ON
        shift
    else
        _exec_dev_or_arch_helper_COMPILATION=OFF
    fi
    _exec_dev_or_arch_helper_PLATFORM=${PLATFORM:-}
    if [ ! "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ] && [ "$_exec_dev_or_arch_helper_PLATFORM" = dev ]; then
        printf "FATAL: exec_in_platform() must not have PLATFORM=dev\n" >&2
        exit 107
    fi

    _exec_dev_or_arch_helper_CMDFILE="$WORK"/_exec_dev_or_arch_helper-cmdfile.sh
    _exec_dev_or_arch_helper_CMDARGS="$WORK"/_exec_dev_or_arch_helper-cmdfile.args
    true > "$_exec_dev_or_arch_helper_CMDARGS"
    if [ -n "${BUILDTYPE:-}" ]; then
        printf "  -b %s" "$BUILDTYPE" >> "$_exec_dev_or_arch_helper_CMDARGS"
    fi
    if [ "${_exec_dev_or_arch_helper_COMPILATION:-}" = ON ]; then
        printf "  -c" >> "$_exec_dev_or_arch_helper_CMDARGS"
    fi
    if [ ! "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ] || is_dev_platform || ! is_arg_linux_based_platform "$_exec_dev_or_arch_helper_PLATFORM"; then
        if [ -x /usr/bin/cygpath ]; then
            _exec_dev_or_arch_helper_ACTUALTOPDIR=$(/usr/bin/cygpath -aw "$TOPDIR")
        else
            _exec_dev_or_arch_helper_ACTUALTOPDIR="$TOPDIR"
        fi
        for _exec_dev_or_arch_helper_ARG in "$@"; do
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                _exec_dev_or_arch_helper_ARG=$(replace_all "${_exec_dev_or_arch_helper_ARG}" @@EXPAND_TOPDIR@@ "${_exec_dev_or_arch_helper_ACTUALTOPDIR}")
            fi
            printf "%s\n  '%s'" " \\" "$_exec_dev_or_arch_helper_ARG" >> "$_exec_dev_or_arch_helper_CMDARGS"
        done
        if [ -n "${PLATFORM_EXEC_PRE_SINGLE:-}" ]; then
            ACTUAL_PRE_HOOK_SINGLE="$PLATFORM_EXEC_PRE_SINGLE"
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                ACTUAL_PRE_HOOK_SINGLE=$(replace_all "${ACTUAL_PRE_HOOK_SINGLE}" @@EXPAND_TOPDIR@@ "${_exec_dev_or_arch_helper_ACTUALTOPDIR}")
            fi
        fi
        if [ -n "${PLATFORM_EXEC_PRE_DOUBLE:-}" ]; then
            ACTUAL_PRE_HOOK_DOUBLE="$PLATFORM_EXEC_PRE_DOUBLE"
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                ACTUAL_PRE_HOOK_DOUBLE=$(replace_all "${ACTUAL_PRE_HOOK_DOUBLE}" @@EXPAND_TOPDIR@@ "${_exec_dev_or_arch_helper_ACTUALTOPDIR}")
            fi
        fi
        if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
            printf "%s\n" "exec '$DKMLDIR'/vendor/drc/unix/_within_dev.sh -p '$_exec_dev_or_arch_helper_PLATFORM' -0 '${ACTUAL_PRE_HOOK_SINGLE:-}' -1 '${ACTUAL_PRE_HOOK_DOUBLE:-}' \\" > "$_exec_dev_or_arch_helper_CMDFILE"
        else
            printf "%s\n" "exec '$DKMLDIR'/vendor/drc/unix/_within_dev.sh -p '$_exec_dev_or_arch_helper_PLATFORM' -d '$STATEDIR' -u '$USERMODE' -0 '${ACTUAL_PRE_HOOK_SINGLE:-}' -1 '${ACTUAL_PRE_HOOK_DOUBLE:-}' \\" > "$_exec_dev_or_arch_helper_CMDFILE"
        fi
    else
        # TODO: within-sandbox.sh is deprecated. We can use CMake and ExternalProject through Docker or WSL2 to
        # do much of the same more cleanly.
        for _exec_dev_or_arch_helper_ARG in "$@"; do
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                _exec_dev_or_arch_helper_ARG=$(replace_all "${_exec_dev_or_arch_helper_ARG}" @@EXPAND_TOPDIR@@ "/work")
            fi
            printf "%s\n  '%s'" " \\" "$_exec_dev_or_arch_helper_ARG" >> "$_exec_dev_or_arch_helper_CMDARGS"
        done
        if [ -n "${PLATFORM_EXEC_PRE_SINGLE:-}" ]; then
            ACTUAL_PRE_HOOK_SINGLE="$PLATFORM_EXEC_PRE_SINGLE"
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                ACTUAL_PRE_HOOK_SINGLE=$(replace_all "${ACTUAL_PRE_HOOK_SINGLE}" @@EXPAND_TOPDIR@@ "/work")
            fi
        fi
        if [ -n "${PLATFORM_EXEC_PRE_DOUBLE:-}" ]; then
            ACTUAL_PRE_HOOK_DOUBLE="$PLATFORM_EXEC_PRE_DOUBLE"
            if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
                ACTUAL_PRE_HOOK_DOUBLE=$(replace_all "${ACTUAL_PRE_HOOK_DOUBLE}" @@EXPAND_TOPDIR@@ "/work")
            fi
        fi
        if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
            printf "%s\n" "exec '$DKMLDIR'/runtime/unix/within-sandbox.sh -p '$_exec_dev_or_arch_helper_PLATFORM' -0 '${ACTUAL_PRE_HOOK_SINGLE:-}' -1 '${ACTUAL_PRE_HOOK_DOUBLE:-}' \\" > "$_exec_dev_or_arch_helper_CMDFILE"
        else
            printf "%s\n" "exec '$DKMLDIR'/runtime/unix/within-sandbox.sh -p '$_exec_dev_or_arch_helper_PLATFORM' -d '$STATEDIR' -u '$USERMODE' -0 '${ACTUAL_PRE_HOOK_SINGLE:-}' -1 '${ACTUAL_PRE_HOOK_DOUBLE:-}' \\" > "$_exec_dev_or_arch_helper_CMDFILE"
        fi
    fi
    cat "$_exec_dev_or_arch_helper_CMDARGS" >> "$_exec_dev_or_arch_helper_CMDFILE"

    log_shell "$_exec_dev_or_arch_helper_CMDFILE"
}

# Outputs:
# - env:DKSDKCACHEDIR_BUILDHOST - The dksdk cache directory
set_dksdkcachedir() {
    if is_unixy_windows_build_machine; then
        DKSDKCACHEDIR_BUILDHOST="${LOCALAPPDATA}\\dksdk\\cache"
    else
        # shellcheck disable=SC2034
        DKSDKCACHEDIR_BUILDHOST="${XDG_CACHE_HOME:-$HOME/.cache}/dksdk"
    fi
}

# Sets the location of the opam executable.
# Prefers ~/opt/opam/bin/opam{.exe}; otherwise looks in the PATH.
#
# Inputs:
# - env:OPAMHOME - If specified, use <OPAMHOME>/bin/opam or <OPAMHOME>/bin/opam.exe
# Outputs:
# - env:OPAMEXE - The location of opam or opam.exe
# Return code: 0 if found; 1 if not found
set_opamexe() {
    if [ -n "${OPAMHOME:-}" ]; then
        if [ -e "$OPAMHOME/bin/opam.exe" ]; then
            OPAMEXE="$OPAMHOME/bin/opam.exe"
            return
        elif [ -e "$OPAMHOME/bin/opam" ]; then
            OPAMEXE="$OPAMHOME/bin/opam"
            return
        else
            printf "FATAL: OPAMHOME is %s yet %s/bin/opam{.exe} does not exist\n" "$OPAMHOME" "$OPAMHOME"
            exit 107
        fi
    fi
    if [ -e "$HOME/opt/opam/bin/opam.exe" ]; then
        OPAMEXE="$HOME/opt/opam/bin/opam.exe"
        return
    elif [ -e "$HOME/opt/opam/bin/opam" ]; then
        OPAMEXE="$HOME/opt/opam/bin/opam"
        return
    fi
    set_opamexe_EXE=$(command -v opam 2>/dev/null || true)
    if [ -n "$set_opamexe_EXE" ]; then
        # shellcheck disable=SC2034
        OPAMEXE="$set_opamexe_EXE"
        return 0
    fi
    # Not found
    printf "FATAL: Opam was not found. Please follow https://opam.ocaml.org/doc/Install.html\n"
    exit 107
}

# Finds the Opam root.
#
# A side-effect of this call is that `opam init` may be called.
#
# Inputs:
# - env:USERMODE - If 'OFF' uses STATEDIR. Otherwise uses default Opam 2.2 root
# - env:STATEDIR - If specified, uses <STATEDIR>/opam as the Opam root
# - env:OPAMHOME - If specified, use <OPAMHOME>/bin/opam or <OPAMHOME>/bin/opam.exe
# - env:PLATFORM - Deprecated. Only checked if DKML_FEATUREFLAG_CMAKE_PLATFORM is OFF or not defined.
# Outputs:
# - env:OPAMROOTDIR_BUILDHOST - The path to the Opam root directory that is usable only on the
#     build machine (not from within a container)
# - env:OPAMROOTDIR_EXPAND - The path to the Opam root directory switch that works as an
#     argument to `exec_in_platform`
# - env:DKMLPLUGIN_BUILDHOST - Plugin directory for config/installations connected to the Opam root
# - env:DKMLPLUGIN_EXPAND - The plugin directory that works as an argument to `exec_in_platform`
# - env:WITHDKMLEXE_BUILDHOST - The plugin binary 'with-dkml.exe'
# - env:WITHDKMLEXEDIIR_BUILDHOST - The directory containing the plugin binary 'with-dkml.exe'
set_opamrootdir() {
    set_opamexe
    if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
        printf "DKML_FEATUREFLAG_CMAKE_PLATFORM must be ON during its deprecation." >&2
        exit 107
    fi
    if [ "$__USERMODE" = OFF ] && [ -n "${STATEDIR:-}" ]; then
        OPAMROOTDIR_BUILDHOST="$STATEDIR/opam"
        if [ -x /usr/bin/cygpath ]; then OPAMROOTDIR_BUILDHOST=$(/usr/bin/cygpath -aw "$OPAMROOTDIR_BUILDHOST"); fi
        # shellcheck disable=SC2034
        DKMLPLUGIN_BUILDHOST="$OPAMROOTDIR_BUILDHOST${OS_DIR_SEP}plugins${OS_DIR_SEP}diskuvocaml"
        WITHDKMLEXEDIR_BUILDHOST="$DKMLPLUGIN_BUILDHOST${OS_DIR_SEP}with-dkml${OS_DIR_SEP}$dkml_root_version"
        # shellcheck disable=SC2034
        WITHDKMLEXE_BUILDHOST="$WITHDKMLEXEDIR_BUILDHOST${OS_DIR_SEP}with-dkml.exe"
    elif is_unixy_windows_build_machine; then
        if [ -n "${OPAMROOT:-}" ]; then
            # If the developer sets OPAMROOT with an environment variable, then we will respect that
            # just like `opam` would do.
            OPAMROOTDIR_BUILDHOST="$OPAMROOT"
        else
            # Conform to https://github.com/ocaml/opam/pull/4815#issuecomment-910137754
            OPAMROOTDIR_BUILDHOST="${LOCALAPPDATA}\\opam"
        fi
        DKMLPLUGIN_BUILDHOST="$OPAMROOTDIR_BUILDHOST\\plugins\\diskuvocaml"
        WITHDKMLEXEDIR_BUILDHOST="$DKMLPLUGIN_BUILDHOST\\with-dkml\\$dkml_root_version"
        WITHDKMLEXE_BUILDHOST="$WITHDKMLEXEDIR_BUILDHOST\\with-dkml.exe"
    else
        if [ -n "${OPAMROOT:-}" ]; then
            OPAMROOTDIR_BUILDHOST="$OPAMROOT"
        elif [ -z "${OPAMROOTDIR_BUILDHOST:-}" ]; then
            # Use existing Opam to know where the Opam root is
            OPAMROOTDIR_BUILDHOST=$($OPAMEXE var --global root 2>/dev/null || true)
            if [ -z "$OPAMROOTDIR_BUILDHOST" ]; then
                # Opam is not initialized. We probably got:
                #   [ERROR] Opam has not been initialised, please run `opam init'                
                # So conform to https://github.com/ocaml/opam/pull/4815#issuecomment-910137754
                set_opamrootdir_VER=$($OPAMEXE --version)
                case "$set_opamrootdir_VER" in
                    1*)
                        printf "FATAL: You will need to upgrade %s to Opam 2.0+\n" "$OPAMEXE"
                        exit 107
                        ;;
                    2.0.*|2.1.*)
                        OPAMROOTDIR_BUILDHOST="$HOME/.opam"
                        ;;
                    *)
                        OPAMROOTDIR_BUILDHOST="${XDG_CONFIG_HOME:-$HOME/.config}/opam"
                        ;;
                esac
            fi
        fi
        # shellcheck disable=SC2034
        DKMLPLUGIN_BUILDHOST="$OPAMROOTDIR_BUILDHOST/plugins/diskuvocaml"
        WITHDKMLEXEDIR_BUILDHOST="$DKMLPLUGIN_BUILDHOST/with-dkml/$dkml_root_version"
        # shellcheck disable=SC2034
        WITHDKMLEXE_BUILDHOST="$WITHDKMLEXEDIR_BUILDHOST/with-dkml.exe"
    fi
    # shellcheck disable=SC2034
    OPAMROOTDIR_EXPAND="$OPAMROOTDIR_BUILDHOST"
    # shellcheck disable=SC2034
    DKMLPLUGIN_EXPAND="$OPAMROOTDIR_EXPAND/plugins/diskuvocaml"
}

# Select the '(diskuv-)(host|dksdk)-tools' switch.
#
# On Windows (anything with a DiskuvOCamlHome environment variable) the system will be a local
# Opam switch inside DiskuvOCamlHome/dkml. Otherwise the system will be the global Opam switch
# `dkml`.
#
# Inputs:
# - env:DiskuvOCamlHome - Typically you get this from `autodetect_dkmlvars || true`. It will not set
#   the variable on non-Windows system, which is supported.
# - env:DKSDK_INVOCATION - Optional. Defaults to OFF. If ON the name of the switch will end in dksdk-${DKML_HOST_ABI}
#   rather than dkml. The DKSDK system switch uses a system compiler rather than a base compiler, so
#   the switches must be segregated.
# - env:USERMODE
# - env:STATEDIR
# Outputs:
# - env:OPAMSWITCHFINALDIR_BUILDHOST - Either:
#     The path to the switch that represents the build directory that is usable only on the
#     build machine (not from within a container). For an external (aka local) switch the returned path will be
#     a `.../_opam`` folder which is where the final contents of the switch live. Use OPAMSWITCHNAME_EXPAND
#     if you want an XXX argument for `opam --switch XXX` rather than this path which is not compatible.
# - env:OPAMSWITCHNAME_EXPAND - Either
#     The path to the switch **not including any _opam subfolder** that works as an argument to `exec_in_platform` -OR-
#     The name of a global switch that represents the build directory.
#     OPAMSWITCHNAME_EXPAND works inside or outside of a container.
set_opamswitchdir_of_system() {
    set_opamswitchdir_of_system_PLATFORM=$1
    shift

    # !!!!!!!!!!!!!
    # CHANGE NOTICE
    # !!!!!!!!!!!!!
    #
    # Do not change the behavior of this function without also
    # changing diskuv-sdk > 140-opam-switch-dkml > CMakeLists.txt.

    # Name the switch. Since there may be a zillion switches in the user's default
    # OPAMROOT (ie. USERMODE=ON), we have an unambiguous switch name that identifies
    # that the switch is for Diskuv (either through "dksdk-*" or "diskuv-*" or
    # a local switch that is part of DiskuvOCamlHome).
    if [ "${DKSDK_INVOCATION:-OFF}" = ON ]; then
        set_opamswitchdir_of_system_SWITCHBASE="dksdk-$set_opamswitchdir_of_system_PLATFORM"
        set_opamswitchdir_of_system_SWITCHBASE_UNAMBIGUOUS="$set_opamswitchdir_of_system_SWITCHBASE"
    else
        set_opamswitchdir_of_system_SWITCHBASE="dkml"
        set_opamswitchdir_of_system_SWITCHBASE_UNAMBIGUOUS="dkml"
    fi

    # Set OPAMROOTDIR_BUILDHOST
    set_opamrootdir
    # Set DKMLHOME_UNIX if available
    autodetect_dkmlvars || true
    # Set OPAMSWITCHFINALDIR_BUILDHOST and OPAMSWITCHNAME_EXPAND
    if cmake_flag_off "$USERMODE"; then
        OPAMSWITCHNAME_EXPAND="${set_opamswitchdir_of_system_SWITCHBASE}"
        OPAMSWITCHFINALDIR_BUILDHOST="$OPAMROOTDIR_BUILDHOST${OS_DIR_SEP}${set_opamswitchdir_of_system_SWITCHBASE}"
    else
        if [ -n "${DKMLHOME_BUILDHOST:-}" ]; then
            OPAMSWITCHNAME_EXPAND="$DKMLHOME_BUILDHOST${OS_DIR_SEP}${set_opamswitchdir_of_system_SWITCHBASE}"
            OPAMSWITCHFINALDIR_BUILDHOST="$OPAMSWITCHNAME_EXPAND${OS_DIR_SEP}_opam"
        else
            OPAMSWITCHNAME_EXPAND="${set_opamswitchdir_of_system_SWITCHBASE_UNAMBIGUOUS}"
            # shellcheck disable=SC2034
            OPAMSWITCHFINALDIR_BUILDHOST="$OPAMROOTDIR_BUILDHOST${OS_DIR_SEP}${set_opamswitchdir_of_system_SWITCHBASE_UNAMBIGUOUS}"
        fi
    fi
}

# is_empty_opam_switch_present SWITCHDIR
#
# SWITCHDIR - Must be the `_opam/` subfolder if the switch is an external (aka local)
#    switch. Otherwise the switch is a global switch and must be the subfolder of
#    the Opam root directory (ex. ~/.opam) that has the same name as the global switch.
#
# Returns: True (0) if and only if the switch exists and is at least an `opam switch create --empty` switch.
#          False (1) otherwise.
is_empty_opam_switch_present() {
    is_empty_opam_switch_present_switchdir_buildhost=$1
    shift
    if [ -s "$is_empty_opam_switch_present_switchdir_buildhost/.opam-switch/switch-config" ]
    then
        return 0
    else
        return 1
    fi
}

# is_minimal_opam_switch_present SWITCHDIR
#
# SWITCHDIR - Must be the `_opam/` subfolder if the switch is an external (aka local)
#    switch. Otherwise the switch is a global switch and must be the subfolder of
#    the Opam root directory (ex. ~/.opam) that has the same name as the global switch.
#
# Returns: True (0) if and only if the switch exists and has either an OCaml base compiler
#          or evidence of an OCaml system compiler.
#          False (1) otherwise.
is_minimal_opam_switch_present() {
    is_minimal_opam_switch_present_switchdir_buildhost=$1
    shift
    if
    [ -e "$is_minimal_opam_switch_present_switchdir_buildhost/.opam-switch/switch-config" ] ||
    [ -e "$is_minimal_opam_switch_present_switchdir_buildhost/.opam-switch/switch-state" ] ||
    # gen_ocaml_config.ml is evidence that a system compiler was configured;
    # see https://github.com/ocaml/opam-repository/blob/master/packages/ocaml-system/ocaml-system.4.12.1/files/gen_ocaml_config.ml.in
    [ -e "$is_minimal_opam_switch_present_switchdir_buildhost/share/ocaml-config/gen_ocaml_config.ml" ] ||
    [ -e "$is_minimal_opam_switch_present_switchdir_buildhost/bin/ocamlc" ] ||
    [ -e "$is_minimal_opam_switch_present_switchdir_buildhost/bin/ocamlc.exe" ]
    then
        return 0
    else
        return 1
    fi
}

# is_minimal_opam_root_present ROOTDIR
#
# ROOTDIR - The Opam root directory.
#
# Returns: True (0) if and only if the root exists and has an Opam configuration file.
#          False (1) otherwise.
is_minimal_opam_root_present() {
    is_minimal_opam_root_present_rootdir_buildhost=$1
    shift
    if [ -e "$is_minimal_opam_root_present_rootdir_buildhost/config" ]
    then
        return 0
    else
        return 1
    fi
}

# get_opam_switch_state_toplevelsection SWITCHDIR TOPLEVEL_SECTION_NAME
#
# Speedy way to grab sections from Opam. Opam is pretty speedy but
# `opam install utop` for example requires that `vcvars64.bat` is loaded
# on Windows which can take seconds.
#
# Inputs:
#
# SWITCHDIR - Must be the `_opam/` subfolder if the switch is an external (aka local)
#    switch. Otherwise the switch is a global switch and must be the subfolder of
#    the Opam root directory (ex. ~/.opam) that has the same name as the global switch.
# TOPLEVEL_SECTION_NAME - The name of the section. See Examples.
#
# Output: [stdout] The toplevel section of `switch-state` that
#   has the name TOPLEVEL_SECTION_NAME
#
# Examples:
#   If `~/_opam/.opam-switch/switch-state` contained:
#        compiler: ["ocaml-variants.4.12.0+msvc64+msys2"]
#        roots: [
#          "bigstringaf.0.8.0"
#          "digestif.1.0.1"
#          "dune-configurator.2.9.0"
#          "ocaml-lsp-server.1.8.2"
#          "ocaml-variants.4.12.0+msvc64+msys2"
#          "ocamlformat.0.18.0"
#          "ppx_expect.v0.14.1"
#          "utop.2.8.0"
#        ]
#   Then `get_opam_switch_state_toplevelsection ~/_opam compiler` would give:
#        compiler: ["ocaml-variants.4.12.0+msvc64+msys2"]
#   and `get_opam_switch_state_toplevelsection ~/_opam roots` would give:
#        roots: [
#          "bigstringaf.0.8.0"
#          "digestif.1.0.1"
#          "dune-configurator.2.9.0"
#          "ocaml-lsp-server.1.8.2"
#          "ocaml-variants.4.12.0+msvc64+msys2"
#          "ocamlformat.0.18.0"
#          "ppx_expect.v0.14.1"
#          "utop.2.8.0"
#        ]
get_opam_switch_state_toplevelsection() {
    get_opam_switch_state_toplevelsection_switchdir_buildhost=$1
    shift
    get_opam_switch_state_toplevelsection_toplevel_section_name=$1
    shift
    if [ ! -e "${get_opam_switch_state_toplevelsection_switchdir_buildhost}/.opam-switch/switch-state" ]; then
        echo "FATAL: There is no Opam switch at ${get_opam_switch_state_toplevelsection_switchdir_buildhost}" >&2
        exit 71
    fi
    awk -v section="$get_opam_switch_state_toplevelsection_toplevel_section_name" \
        '$1 ~ ":" {state=0} $1==(section ":") {state=1} state==1{print}' \
        "${get_opam_switch_state_toplevelsection_switchdir_buildhost}/.opam-switch/switch-state"
}

# delete_opam_switch_state_toplevelsection SWITCHDIR TOPLEVEL_SECTION_NAME
#
# Prints out the switch state with the specified toplevel section name removed.
# See get_opam_switch_state_toplevelsection for more details.
delete_opam_switch_state_toplevelsection() {
    delete_opam_switch_state_toplevelsection_switchdir_buildhost=$1
    shift
    delete_opam_switch_state_toplevelsection_toplevel_section_name=$1
    shift
    if [ ! -e "${delete_opam_switch_state_toplevelsection_switchdir_buildhost}/.opam-switch/switch-state" ]; then
        echo "FATAL: There is no Opam switch at ${delete_opam_switch_state_toplevelsection_switchdir_buildhost}" >&2
        exit 71
    fi
    awk -v section="$delete_opam_switch_state_toplevelsection_toplevel_section_name" \
        '$1 ~ ":" {state=0} $1==(section ":") {state=1} state==0{print}' \
        "${delete_opam_switch_state_toplevelsection_switchdir_buildhost}/.opam-switch/switch-state"
}

# [print_opam_logs_on_error CMD [ARGS...]] will execute `CMD [ARGS...]`. If the CMD fails _and_
# the environment variable `DKML_BUILD_PRINT_LOGS_ON_ERROR` is `ON` then print out Opam log files
# to the standard error.
print_opam_logs_on_error() {
    # save `set` state
    print_opam_logs_on_error_OLDSTATE=$(set +o)
    set +e # allow the next command to possibly fail
    "$@"
    print_opam_logs_on_error_EC=$?
    if [ "$print_opam_logs_on_error_EC" -ne 0 ]; then
        if [ "${DKML_BUILD_PRINT_LOGS_ON_ERROR:-}" = ON ]; then
            printf "\n\n========= [START OF TROUBLESHOOTING] ===========\n\n" >&2

            # print _one_ of the environment
            # shellcheck disable=SC2030
            find "$OPAMROOTDIR_BUILDHOST"/log -mindepth 1 -maxdepth 1 -name "*.env" ! -name "log-*.env" ! -name "ocaml-variants-*.env" | head -n1 | while read -r dump_on_error_LOG; do
                # shellcheck disable=SC2031
                dump_on_error_BLOG=$(basename "$dump_on_error_LOG")
                printf "\n\n========= [TROUBLESHOOTING] %s ===========\n# To save space, this is only one of the many similar Opam environment files that have been printed.\n\n" "$dump_on_error_BLOG" >&2
                cat "$dump_on_error_LOG" >&2
            done

            # print all output files (except ocaml-variants)
            find "$OPAMROOTDIR_BUILDHOST"/log -mindepth 1 -maxdepth 1 -name "*.out" ! -name "log-*.out" ! -name "ocaml-variants-*.out" | while read -r dump_on_error_LOG; do
                dump_on_error_BLOG=$(basename "$dump_on_error_LOG")
                printf "\n\n========= [TROUBLESHOOTING] %s ===========\n\n" "$dump_on_error_BLOG" >&2
                cat "$dump_on_error_LOG" >&2
            done

            # TODO: we could add other logs files from the switch, like
            # `$env:LOCALAPPDATA\Programs\DiskuvOCaml\0\system\_opam\.opam-switch\build\ocamlfind.1.9.1\ocargs.log`

            printf "The command %s failed with exit code $print_opam_logs_on_error_EC. Scroll up to see the [TROUBLESHOOTING] logs that begin at the [START OF TROUBLESHOOTING] line\n" "$*" >&2
        fi

        exit $print_opam_logs_on_error_EC
    fi
    # restore old state
    eval "$print_opam_logs_on_error_OLDSTATE"
}

# [has_rsync] checks if the machine has rsync.
has_rsync() {
    if command -v rsync >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# [spawn_rsync ARGS] runs an rsync with options selected for human readability or for CI.
# You do not need to specify the options:
# * --info=progress2
# * --human-readable
spawn_rsync() {
    spawn_rsync_TERMINAL=OFF
    # check if stdout is a terminal
    if [ -t 1 ]; then
        spawn_rsync_TERMINAL=ON
    fi
    if [ "$spawn_rsync_TERMINAL" = OFF ] || [ "${CI:-}" = true ]; then
        rsync "$@"
    else
        # test whether --info=progress2 works
        spawn_rsync_D1=$(mktemp -d "$WORK"/tmp.XXXXXXXXXX)
        spawn_rsync_D2=$(mktemp -d "$WORK"/tmp.XXXXXXXXXX)
        spawn_rsync_IP2=ON
        rsync -ap --info=progress2 "$spawn_rsync_D1"/ "$spawn_rsync_D2" 2>/dev/null >/dev/null || spawn_rsync_IP2=OFF
        rm -rf "$spawn_rsync_D2"
        rm -rf "$spawn_rsync_D1"

        if [ "$spawn_rsync_IP2" = ON ]; then
            rsync --info=progress2 --human-readable "$@"
        else
            rsync --human-readable "$@"
        fi
    fi
}

validate_and_explore_ocamlhome() {
    validate_and_explore_ocamlhome_HOME=$1
    shift
    # Set DKML_OCAMLHOME_BINDIR_UNIX. Validate
    if [ -x "$validate_and_explore_ocamlhome_HOME/usr/bin/ocaml" ] || [ -x "$validate_and_explore_ocamlhome_HOME/usr/bin/ocaml.exe" ]; then
        DKML_OCAMLHOME_BINDIR_UNIX=usr/bin
    elif [ -x "$validate_and_explore_ocamlhome_HOME/bin/ocaml" ] || [ -x "$validate_and_explore_ocamlhome_HOME/bin/ocaml.exe" ]; then
        # shellcheck disable=SC2034
        DKML_OCAMLHOME_BINDIR_UNIX=bin
    else
        unset DKML_OCAMLHOME_BINDIR_UNIX
        printf "FATAL: The OCAMLHOME='%s' does not have a usr/bin/ocaml, bin/ocaml, usr/bin/ocaml.exe or bin/ocaml.exe\n" "$validate_and_explore_ocamlhome_HOME" >&2
        exit 107
    fi
    # Set DKML_OCAMLHOME_UNIX and DKML_OCAMLHOME_ABSBINDIR_BUILDHOST
    if [ -x /usr/bin/cygpath ]; then
        DKML_OCAMLHOME_UNIX=$(/usr/bin/cygpath -au "$validate_and_explore_ocamlhome_HOME")
        DKML_OCAMLHOME_ABSBINDIR_BUILDHOST=$(/usr/bin/cygpath -aw "$validate_and_explore_ocamlhome_HOME/$DKML_OCAMLHOME_BINDIR_UNIX")
    else
        # shellcheck disable=SC2034
        DKML_OCAMLHOME_UNIX="$validate_and_explore_ocamlhome_HOME"
        # shellcheck disable=SC2034
        DKML_OCAMLHOME_ABSBINDIR_BUILDHOST="$validate_and_explore_ocamlhome_HOME/$DKML_OCAMLHOME_BINDIR_UNIX"
    fi
}
