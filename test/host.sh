#!/bin/bash
set -u

binary=${1:?usage: host.sh <aeroplace binary>}
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
failures=0

report() {
  local name=$1 status=$2 expected_status=$3 output=$4 expected_output=$5
  if [[ $status -ne $expected_status || $output != *"$expected_output"* ]]; then
    printf 'FAIL: %s (status %s, output %q)\n' "$name" "$status" "$output"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$name"
  fi
}

check() {
  local name=$1 expected_status=$2 expected_output=$3 script=$4
  shift 4
  mkdir -p "$fixture/$name"
  printf '%s\n' "$script" >"$fixture/$name/main.lua"
  local output status
  output=$(AEROPLACE_LUA="$fixture/$name" "$binary" "$@" 2>&1)
  status=$?
  report "$name" "$status" "$expected_status" "$output" "$expected_output"
}

check exit-code 7 '' 'return 7' run
check nil-is-success 0 '' 'return nil' run
check argv-is-varargs 0 'run|a b' 'io.write(table.concat({...}, "|"))' run 'a b'
check arg-zero-is-absolute 0 '/' 'io.write(arg[0]:sub(1, 1))' run
check string-error 1 'boom' 'error("boom")' run
check non-string-error 1 'non-string Lua error' 'error({})' run
check syntax-error 1 'main.lua' 'return +' run
check non-integer-result 1 'non-integer' 'return "x"' run

output=$(AEROPLACE_LUA="$fixture/missing" "$binary" run 2>&1)
report missing-scripts $? 1 "$output" 'main.lua'

output=$(env -u AEROPLACE_LUA "$binary" run 2>&1)
report default-scripts-dir $? 1 "$output" 'share/aeroplace/main.lua'

output=$(AEROPLACE_LUA= "$binary" run 2>&1)
report empty-override-uses-default $? 1 "$output" 'share/aeroplace/main.lua'

mkdir -p "$fixture/lookup"
printf '%s\n' 'io.write(assert(aeroplace.aerospace("--version")))' >"$fixture/lookup/main.lua"
fake_path="$(dirname "$0")/bin:/usr/bin:/bin"
output=$(PATH="$fake_path" AEROPLACE_LUA="$fixture/lookup" "$binary" run 2>&1)
report aerospace-from-path $? 0 "$output" 'version fake'

scripts="$(dirname "$0")/../lua"
output=$(AEROPLACE_LUA="$scripts" "$binary" --version 2>/dev/null)
report version $? 0 "$output" 'aeroplace 0.1.0'
output=$(AEROPLACE_LUA="$scripts" "$binary" --help 2>/dev/null)
report help $? 0 "$output" 'usage: aeroplace'
output=$(AEROPLACE_LUA="$scripts" "$binary" unknown 2>&1 >/dev/null)
report unknown-verb $? 2 "$output" 'usage: aeroplace'

exit $((failures > 0))
