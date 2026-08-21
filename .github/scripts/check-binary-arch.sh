#!/bin/sh
# Fail if file(1)/readelf machine type and libc do not match the asset name.
set -eu

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <binary> <os_name> <arch> [libc]" >&2
  exit 2
fi

binary=$1
os_name=$2
arch=$3
libc=${4:-}

if [ ! -f "$binary" ]; then
  echo "error: binary not found: $binary" >&2
  exit 1
fi

file_out=$(file "$binary")
echo "$file_out"

info=$file_out
readelf_h=
if command -v readelf >/dev/null 2>&1; then
  readelf_h=$(readelf -h "$binary")
  readelf_l=$(readelf -l "$binary")
  echo "$readelf_h"
  info="$info
$readelf_h
$readelf_l"
fi

contains() {
  printf '%s\n' "$info" | grep -Ei "$1" >/dev/null
}

case "$arch" in
  x64)
    arch_pat='x86-64|x86_64'
    readelf_machine='X86-64'
    ;;
  arm64)
    arch_pat='aarch64|arm64'
    readelf_machine='AArch64'
    ;;
  *)
    echo "error: unsupported arch: $arch" >&2
    exit 1
    ;;
esac

if ! contains "$arch_pat"; then
  echo "error: expected arch $arch ($arch_pat) in file(1)/readelf output" >&2
  exit 1
fi

case "$os_name" in
  linux)
    if ! contains 'ELF'; then
      echo "error: expected ELF for linux" >&2
      exit 1
    fi
    case "$libc" in
      gnu)
        if ! contains 'ld-linux'; then
          echo "error: expected ld-linux interpreter for gnu libc" >&2
          exit 1
        fi
        if contains 'musl'; then
          echo "error: gnu binary must not be musl" >&2
          exit 1
        fi
        ;;
      musl)
        if contains 'ld-linux'; then
          echo "error: musl binary must not use ld-linux" >&2
          exit 1
        fi
        if ! contains 'ld-musl|musl|statically linked'; then
          echo "error: expected ld-musl or musl/static for musl libc" >&2
          exit 1
        fi
        ;;
      *)
        echo "error: unsupported linux libc: '${libc}'" >&2
        exit 1
        ;;
    esac
    if [ -n "$readelf_h" ]; then
      if ! printf '%s\n' "$readelf_h" | grep -Ei "Machine:.*${readelf_machine}" >/dev/null; then
        echo "error: readelf Machine did not match ${readelf_machine}" >&2
        exit 1
      fi
    fi
    ;;
  macos)
    if ! contains 'Mach-O'; then
      echo "error: expected Mach-O for macos" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: unsupported os_name: $os_name" >&2
    exit 1
    ;;
esac

echo "architecture check passed: ${os_name} ${arch} ${libc:-}"
