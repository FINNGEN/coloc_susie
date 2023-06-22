#!/bin/bash

set -euxo pipefail

n_cpu=`grep -c ^processor /proc/cpuinfo`

function coloc() {

  >&2 echo "`date` running coloc on region/traits: $1"

  arr=(${1//\t/ })
  region=${arr[0]}
  traits=${arr[1]}

  # replace negative region start with 0 for tabix
  tabix_region=$(echo "$region" | sed -E 's/:-[0-9]+/:0/')

  tabix -h !{lbf1_file} !{chr_prefix1}${tabix_region} > !{lbf1_file}.${region}.tsv
  # get only the current region and traits fine-mapped on that exact region
  tabix -h !{lbf2_file} !{chr_prefix2}${tabix_region} | \
  awk -v region=$region -v traits=$traits '
  BEGIN {FS=OFS="\t"; split(traits,trait_arr,",");}
  NR==1 {for(i=1; i<=NF; i++) h[$i]=i; print $0;}
  NR >1 {sub("chr", "", $h["!{region_col}"]); for(i in trait_arr) if($h["!{region_col}"]==region && $h["!{trait2_col}"]=trait_arr[i]) print $0;}
  ' > !{lbf2_file}.${region}.tsv

  if test "$( wc -l < !{lbf2_file}.${region}.tsv )" -lt 2; then
    >&2 echo "no variants found from file !{lbf2_file} using region ${region}. Something's wrong";
    rm -f !{lbf1_file}.${region}.tsv
    rm -f !{lbf2_file}.${region}.tsv
    exit 1;
  fi

  if test "$( wc -l < !{lbf1_file}.${region}.tsv )" -gt 1; then
    coloc_bf.R \
    --lbf1 !{lbf1_file}.${region}.tsv --lbf2 !{lbf2_file}.${region}.tsv \
    --lbf1_trait_col "!{trait1_col}" --lbf1_variant_col "!{variant1_col}" \
    --lbf2_trait_col "!{trait2_col}" --lbf2_variant_col "!{variant2_col}" --lbf2_dataset_col "!{dataset2_col}"
  else
    >&2 echo "no variants found from file !{lbf1_file} using region ${region}";
  fi

  rm -f !{lbf1_file}.${region}.tsv
  rm -f !{lbf2_file}.${region}.tsv
}
export -f coloc

echo "`date` getting unique regions/traits from !{lbf2_file}"
zcat !{lbf2_file} | awk '
BEGIN {OFS="\t"}
NR==1 {for(i=1;i<=NF;i++) h[$i]=i;}
NR >1 {
  s=split($h["!{region_col}"],r,"_|-|:");
  sub("chr", "", r[1]);
  if(s == 4) reg=r[1]":-"r[3]"-"r[4]; # account for negative region start, e.g. chr11:-740504-1259496
  else if(s == 3) reg=r[1]":"r[2]"-"r[3];
  else { print "unexpected region: "$h["!{region_col}"] > "/dev/stderr"; exit 1; }
  print $h["!{trait2_col}"],reg;
}
' | sort -u | datamash -g 2 collapse 1 > regions

echo "`date` running coloc for `wc -l regions`/traits"
cat regions | parallel coloc | \
awk 'NR==1 || !($0~"^#")' | bgzip -@ $n_cpu > !{lbf1_file}.!{lbf2_file}.coloc.tsv.gz

echo "`date` done"
