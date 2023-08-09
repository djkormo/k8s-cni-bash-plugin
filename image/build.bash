#!/bin/bash

git pull
make
make publish-version
make publisz-latest
