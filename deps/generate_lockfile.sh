#!/bin/bash

if [[ $(which uv) == "" ]]; then
  echo "Generating the python lockfile requires the \`uv\` tool."
  echo "Please install it here:"
  echo ""
  echo "  https://docs.astral.sh/uv/getting-started/installation/"
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)

pushd "${repo_root}/deps"
uv lock 
popd
