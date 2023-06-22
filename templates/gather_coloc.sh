#!/bin/bash

set -eux

echo "`date` concatenating *.coloc.tsv.gz"
zcat *.coloc.tsv.gz | awk 'NR==1 {for(i=1;i<=NF;i++) h[$i]=i;} $h["PP.H4.abf"]!="NA"' | bgzip > !{outfile}
echo "`date` done"
