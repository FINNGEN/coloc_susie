set -eux

n_cpu=`grep -c ^processor /proc/cpuinfo`

echo `date` decompress
ls -1 *.tsv.gz | head -1 | xargs -I{} zcat {} | head -1 > header
ls -1 *.tsv.gz | xargs -P $n_cpu -I{} sh -c "gzip -cd --force {} | tail -n+2 > {}.tsv"
rm *.tsv.gz
ls -1 *.tsv | tr '\n' '\0' > merge_these

echo `date` merge
time \
cat \
header \
<(sort \
-m \
-T . \
--parallel=$n_cpu \
--compress-program=gzip \
--files0-from=merge_these \
--batch-size=!{params.batch_size} \
-k6,6V -k7,7g -k8,9 \
| grep -Ev "^#") \
| bgzip -@$n_cpu > !{outfile}

echo `date` tabix
tabix -s6 -b7 -e7 !{outfile}

echo `date` end
