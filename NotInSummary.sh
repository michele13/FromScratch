#!/bin/sh

# This program tells us which pages are not in SUMMARY.md


# REGEX EXPLAINATION


# (?<=\]\()[^)]*

# - (?<=\]\() → positive lookbehind: check that before text there's ](, the end of the link text and the beginning of the URL.
# - [^)]* → capture all characters until first )


# GNU grep

# -o only matching
# -P enable Perl Compatible Regular Expression, it is necessary for the lookbehind to work

grep -oP '(?<=\]\()[^)]*' SUMMARY.md | sort | uniq  > insummary.tmp

find * -type f -iname "*.md" | sort | uniq > allfiles.tmp

diff insummary.tmp allfiles.tmp

# rm insummary.tmp allfiles.tmp
