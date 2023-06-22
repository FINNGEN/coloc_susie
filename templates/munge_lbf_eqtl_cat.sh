#!/bin/bash

# take a lbf file of one dataset
# add a dataset column, truncate decimals from lbfs, and sort by chr, pos, ensg

bname=`basename !{fname} .lbf_variable.txt.gz`

cat \
    <(gunzip -c !{fname} | head -1 | awk '{print "#dataset\t"$0}') \
    <(gunzip -c !{fname} | awk -vbname=$bname '
NR>1 {
printf bname; for(i=1; i<=5; i++) printf "\t"$i
for (i=6; i<=NF; i++) if ($i==0) printf "\t"$i; else printf "\t%.!{params.num_decimals}f",$i
printf "\n"
}' | sort -k5,5V -k6,6g -k2,2 -T . || echo "1">err) | bgzip > `basename !{fname} .txt.gz`.munged.tsv.gz

tabix -s5 -b6 -e6 `basename !{fname} .txt.gz`.munged.tsv.gz

if [ -f err ]; then exit 1; fi
