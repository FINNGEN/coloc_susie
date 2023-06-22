#!/bin/bash

# take a snp (lbf) file of one dataset
# truncate decimals from lbfs and sort by chr, pos, alleles

cat \
    <(gunzip -c !{fname} | head -1 | awk '
    {printf "#"$1; for(i=2; i<=8; i++) printf "\t"$i; for (i=57; i<=NF; i++) printf "\t"$i; printf "\n";}') \
    <(gunzip -c !{fname} | awk '
NR>1 {
printf $1; for(i=2; i<=8; i++) printf "\t"$i;
for (i=57; i<=NF; i++) if ($i==0) printf "\t"$i; else printf "\t%.!{params.num_decimals}f",$i;
printf "\n";
}' | sort -k5,5V -k6,6g -k7,8 -T . || echo "1">err) | bgzip > `basename !{fname} .bgz`.munged.tsv.gz

tabix -s5 -b6 -e6 `basename !{fname} .bgz`.munged.tsv.gz

if [ -f err ]; then exit 1; fi
