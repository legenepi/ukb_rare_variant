library(tidyverse)
library(SNPlocs.Hsapiens.dbSNP155.GRCh38)

results <- read_tsv("LF_sv_additive_long.tsv.gz")

results_long <- results %>%
  mutate(MAF=ifelse(A1FREQ < 0.5, A1FREQ, 1-A1FREQ),
         across(starts_with("LOG10P."), ~10^-.)) %>%
  select(-starts_with("CHISQ"), -TEST, -EXTRA) %>%
  rename_with(~sub("LOG10", "", .), starts_with("LOG10P.")) %>%
  pivot_longer(BETA.Y1:P.Y4) %>%
  separate(name, c("name", "pheno")) %>%
  rowwise %>%
  mutate(pheno=switch(pheno, Y1="FEV1", Y2="FVC", Y3="RATIO", Y4="PEF")) %>%
  ungroup %>%
  pivot_wider(names_from = name, values_from = value) 

top_hits <- results %>%
  filter(MAF < 0.01 & P < 5e-9) %>%
  group_by(ID) %>%
  filter(P == min(P)) %>%
  ungroup

write_tsv(top_hits, "top_hits.txt")
top_hits <- read_tsv("top_hits.txt")

oldsig <- scan("oldsig.txt", character())

missing <- setdiff(oldsig, top_hits$ID)

oldsig_lookup <- read_tsv("oldsig_lookup.txt")

oldsig_lookup %>% filter(ID %in% missing)

top_hits %>%
  filter(!ID %in% oldsig)

snps <- SNPlocs.Hsapiens.dbSNP155.GRCh38

snpsByOverlaps(snps, GRanges(c("1:50978222-50978222")))

top_hits %>%
  mutate(alleles=paste(ALLELE0, ALLELE1, sep="/"), strand=1) %>%
  dplyr::select(CHROM, GENPOS, alleles, strand) %>%
  write.table("", col.names = F, row.names = F, quote = F, sep="\t")
