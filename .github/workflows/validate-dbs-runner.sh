#!/usr/bin/env bash

if [ $# -lt 1 ]; then
  exit
fi

while IFS=$'\n' read -r dbfile; do
  echo "validating '$dbfile'"
  Rscript ${GITHUB_WORKSPACE}/.github/workflows/validate-dbs.R "$dbfile"
done < "$1"