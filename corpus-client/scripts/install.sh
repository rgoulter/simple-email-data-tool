#!/usr/bin/env bash

# Install step for Travis-CI

set -ex

cd corpus-client

# per https://github.com/elm/compiler/blob/24d3a89469e75cf7aa579442ecaf5ddfdd192ab2/installers/linux/README.md
curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
gunzip elm.gz
chmod +x elm

curl -L -o geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.26.0/geckodriver-v0.26.0-linux64.tar.gz
tar -xvzf geckodriver.tar.gz
chmod +x geckodriver

./geckodriver --version

./elm make src/Main.elm

bundle install

cd ..
