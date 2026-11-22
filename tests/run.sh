#!/bin/sh
# Runs both suites under Lua 5.1: the matching corpus (pure, no client API) and
# the integration harness (loads every file against a client stand-in). Prefers a
# system interpreter, falls back to the embedded Lua 5.1 in the python "lupa"
# package so the suite runs without lua5.1 installed.
set -eu
cd "$(dirname "$0")/.."

SUITES="tests/parser.lua tests/integration.lua"

if command -v "${LUA:-lua5.1}" >/dev/null 2>&1; then
    for suite in $SUITES; do
        echo "== $suite"
        "${LUA:-lua5.1}" "$suite"
    done
    exit 0
fi

if python3 -c "import lupa.lua51" >/dev/null 2>&1; then
    echo "no lua5.1 on PATH; running under lupa's embedded Lua 5.1"
    for suite in $SUITES; do
        echo "== $suite"
        SUITE="$suite" python3 -c "
import os, sys
from lupa.lua51 import LuaRuntime
suite = os.environ['SUITE']
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().arg = lua.table_from({0: suite})
try:
    lua.execute(open(suite).read())
except Exception as error:
    print(error, file=sys.stderr); sys.exit(1)
"
    done
    exit 0
fi

echo "no Lua 5.1 available: install lua5.1, or pip install lupa" >&2
exit 1
