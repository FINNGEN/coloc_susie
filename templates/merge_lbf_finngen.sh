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
-k5,5V -k6,6g -k7,8 \
| grep -Ev "^#") \
| bgzip -@$n_cpu > !{params.filename}

echo `date` tabix
tabix -s5 -b6 -e6 !{params.filename}

echo `date` end
