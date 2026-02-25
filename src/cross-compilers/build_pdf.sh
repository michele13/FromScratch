#!/bin/sh

pandoc --standalone \
  --toc=true \
  --number-sections=true \
  -f markdown+emoji -t pdf \
  --pdf-engine=typst \
  --metadata-file metadata.yaml \
  -o i686-linux-gnu.pdf   i686-linux-gnu.md 
