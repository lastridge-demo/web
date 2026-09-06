#!/usr/bin/env bash
# Unit-test stand-in for the observif.ai demo repos. Every check is real
# (schema validity of src/*.json, presence of required keys), and the
# storyline driver can make it fail honestly by committing .demo/break with
# the failure text the log should show. Removing the file is "the fix".
set -uo pipefail
fail=0; n=0
for f in $(find src -name '*.json' | sort); do
  n=$((n+1))
  if python3 -m json.tool "$f" >/dev/null 2>&1; then echo "ok   $f"; else echo "FAIL $f: invalid JSON"; fail=1; fi
done
req=src/config.json; n=$((n+1))
if python3 -c "import json,sys; d=json.load(open('$req')); sys.exit(0 if 'service' in d and 'version' in d else 1)" 2>/dev/null; then
  echo "ok   $req has service/version"
else echo "FAIL $req: missing service or version"; fail=1; fi
if [ -f .demo/break ]; then
  n=$((n+1)); echo "--- FAIL: $(cat .demo/break)"; fail=1
fi
echo "$n checks, $( [ $fail = 0 ] && echo all passed || echo FAILURES )"
exit $fail
