#/usr/bin/bash

dataset=$(basename !{cs2_file} .credible_sets.tsv.gz)

cat \
<(echo -e "#trait1\tdataset\ttrait2\tcs_id1\tcs_id2\tchr\tpos\tref\talt\tmlog10p1\tmlog10p2\tbeta1\tbeta2\tse1\tse2\tclpp_variant\tclpa_variant\tclpp_cs\tclpa_cs\tcs_size1\tcs_size2\tsize_isect") \
<(Rscript - <<EOF | awk '!($0~"^#")' | sort -k6,6V -k7,7g -k8,9
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(tidyverse))

data1 <- fread("zcat !{cs1_file}") %>%
  rename("#trait1"=trait, cs_id1=cs_id, cs_size1=cs_size, pip1=pip, mlog10p1=mlog10p, beta1=beta, se1=se) %>%
  select("#trait1", cs_id1, cs_size1, pip1, mlog10p1, beta1, se1, chr, pos, ref, alt)
data1[["variant"]] <- paste(paste0("chr", str_replace(data1[["chr"]], "chr", "")), data1[["pos"]], data1[["ref"]], data1[["alt"]], sep="_")
data1[["chr_"]] <- str_replace(data1[["chr"]], "chr", "")
data1[["chr_"]] <- str_replace(data1[["chr_"]], "X", "23")
data1[["chr_"]] <- as.numeric(data1[["chr_"]])
data1[["trait_csid"]] <- paste0(data1[["#trait1"]], "|", data1[["cs_id1"]])

data2 <- fread("zcat !{cs2_file}") %>%
  mutate(mlog10p2=-log10(pvalue)) %>%
  rename(trait2=molecular_trait_id, cs_id2=cs_id, cs_size2=cs_size, pip2=pip, beta2=beta, se2=se) %>%
  add_column(dataset="$dataset") %>%
  select(variant, pip2, region, trait2, cs_id2, cs_size2, dataset, mlog10p2, beta2, se2)

for (cs_id in unique(data2[["cs_id2"]])) {
  data2_cs <- unique(data2 %>% filter(cs_id2==cs_id))
  if (length(unique(data2_cs[["region"]])) > 1) {
    message(paste0(length(unique(data2_cs[["region"]])), " regions for cs id ", cs_id, ". This shouldn't happen, quitting."))
    quit(status = 1)
  }
  region <- unlist(unlist(strsplit(data2_cs[1][["region"]], ":|-|_")) %>%
                      map(\(x) str_replace(x, "chr", "")) %>%
                      map(\(x) str_replace(x, "X", "23")) %>%
                      map(as.numeric))
  data1_region <- data1 %>% filter(chr_==region[1] & pos >= region[2] & pos <= region[3])
  for (trait_csid1 in unique(data1_region[["trait_csid"]])) {
    data1_cs <- data1_region %>% filter(trait_csid==trait_csid1)
    comm <- data2_cs %>% inner_join(data1_cs, by="variant")
    if (nrow(comm) > 0) {
      comm <- comm %>% add_column(clpp_variant=comm[["pip1"]] * comm[["pip2"]],
                                  clpa_variant=ifelse(comm[["pip1"]] < comm[["pip2"]], comm[["pip1"]], comm[["pip2"]]),
                                  clpp_cs=sum(clpp_variant),
                                  clpa_cs=sum(clpa_variant),
                                  size_isect=nrow(comm))
      cat(format_tsv(comm %>% select("#trait1", dataset, trait2, cs_id1, cs_id2, chr, pos, ref, alt, mlog10p1, mlog10p2, beta1, beta2, se1, se2, clpp_variant, clpa_variant, clpp_cs, clpa_cs, cs_size1, cs_size2, size_isect)))
    }
  }
}
EOF) | uniq | bgzip > !{cs1_file}.!{cs2_file}.clp.tsv.gz
