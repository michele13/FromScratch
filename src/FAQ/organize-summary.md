# Organize SUMMARY.md

Answer to the question: which files are not present SUMMARY.md?

## Find all markdown files

```bash
   find . -iname '*.md' -type f | sort > filelist.tmp
```

## Check if this file is NOT present in SUMMARY

```bash
    while read line; do
     grep -o "$line" SUMMARY.md | sort
    done  < filelist.tmp > filelist2.tmp
```

## Check difference between the two file lists

```bash
   diff filelist.tmp filelist2.tmp
```   