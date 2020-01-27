#!/usr/bin/env bash

# For Travis-CI

set -ex

cd corpus-client

# per install.sh
ELM_INSTALL_PATH="."
env CI=travis PATH=$ELM_INSTALL_PATH:$PATH xvfb-run bundle exec rspec --format documentation

cd ..
