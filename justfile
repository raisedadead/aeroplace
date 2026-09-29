default:
    @just --list

build:
    swift build -c release

check: build
    #!/usr/bin/env bash
    set -euo pipefail
    root="{{ justfile_directory() }}"
    export PATH="$root/test/bin:$PATH"
    bash "$root/test/host.sh" "$root/.build/release/aeroplace"
    AEROPLACE_LUA="$root/test" "$root/.build/release/aeroplace"
    AEROPLACE_LUA="$root/lua" "$root/.build/release/aeroplace" stages

install prefix=(home_directory() / ".local"): build
    install -d "{{ prefix }}/bin" "{{ prefix }}/share/aeroplace"
    install -m 755 .build/release/aeroplace "{{ prefix }}/bin/aeroplace"
    install -m 644 lua/*.lua "{{ prefix }}/share/aeroplace/"

clean:
    swift package clean
    rm -rf .build
