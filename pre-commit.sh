#!/bin/sh
# Do ln -s ../../pre-commit.sh .git/hooks/pre-commit to make this git hook work.

xsltproc test.xml > test.html
git add test.html

xsltproc beekes_endings.xml > beekes_endings.html
git add beekes_endings.html

xsltproc beekes_ablauts.xml > beekes_ablauts.html
git add beekes_ablauts.html
