#!/bin/bash

git pull
make
make publish-version
make publish-latest
