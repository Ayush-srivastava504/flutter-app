#!/usr/bin/env bash
# Checks that every 64-bit native library inside an .aab or .apk is built for 16 KB memory pages.
# Usage: bash tools/check_16kb.sh build/app/outputs/bundle/release/app-release.aab
# Needs: unzip, objdump (binutils). Exit code 0 = all OK, 1 = at least one library FAILS, 2 = usage/tool error.
#
# Rule used (Android docs, "Support 16 KB page sizes"): every LOAD segment of each arm64-v8a / x86_64
# library must be aligned to 2**14 (16384) or more. 32-bit ABIs are not covered by the Play requirement.
# This checks ELF alignment only. For an .apk also run:  zipalign -c -P 16 -v 4 <file>.apk   (Android SDK build-tools).
set -euo pipefail
f="${1:-}"
[ -f "$f" ] || { echo "usage: $0 <file.aab|file.apk>"; exit 2; }
command -v objdump >/dev/null || { echo "objdump not found (install binutils)"; exit 2; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
unzip -q -o "$f" '*lib/arm64-v8a/*.so' '*lib/x86_64/*.so' -d "$tmp" 2>/dev/null || true
fail=0; n=0
while IFS= read -r so; do
  n=$((n+1))
  # lowest alignment among LOAD segments, as an exponent ("2**14")
  min=$(objdump -p "$so" 2>/dev/null | awk '/^ *LOAD/ {for(i=1;i<=NF;i++) if($i=="align") {split($(i+1),a,"[*][*]"); print a[2]}}' | sort -n | head -1)
  if [ -z "${min:-}" ]; then echo "SKIP  $so (no LOAD segments / not ELF)"; continue; fi
  if [ "$min" -ge 14 ]; then echo "OK    2**$min  ${so#"$tmp"/}"; else echo "FAIL  2**$min  ${so#"$tmp"/}"; fail=1; fi
done < <(find "$tmp" -name '*.so' | sort)
[ "$n" -gt 0 ] || { echo "No arm64-v8a/x86_64 .so files found in $f"; exit 2; }
echo "---- checked $n libraries: $([ $fail -eq 0 ] && echo 'ALL OK' || echo 'SOME FAIL (see above)')"
exit $fail
