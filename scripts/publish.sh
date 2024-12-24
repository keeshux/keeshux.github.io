#!/bin/bash
set -e
rm -rf resume
cp -rp ../resumes/me resume
if git add . -A; then
    git commit -m "."
fi
git push github master
