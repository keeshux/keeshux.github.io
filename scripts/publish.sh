#!/bin/bash
set -e
rm -rf resume
cp -rp ../resumes/me resume
git add . -A
git commit -m "."
git push -f github master
