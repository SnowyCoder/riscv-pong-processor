#!/bin/bash

if (( $# < 2 )); then
  echo "Usage ./compile.sh <file> <output>"
  exit 1
fi

tmp=".tmpcompilefile_plsdontuseme.hex"

rars a dump .text HexText "$tmp" "$1"

echo "v2.0 raw" > "$2"
cat "$tmp" >> "$2"

rm "$tmp"

