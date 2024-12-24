#!/bin/bash
rm -rf resume
cp -rp ../resumes/me resume
git add . -A
git commit -m "."
git push github master
