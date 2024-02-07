library(tidyverse)

results <- read_delim("LF_collapsing.regenie.gz", " ")

results_fmt <- results %>%
  separate(ID, c("GENE", "ENSEMBLE_ID", "model"), sep = "[()]") %>%
  mutate(model=sub("^\\.", "", model)) %>%
  separate(model, c("MASK", "THRESH"), sep="\\.", extra = "merge", fill = "right") %>%
  mutate(THRESH=sub("1e-05", "0.00001", THRESH))

results_long <- results_fmt %>%
  pivot_longer(ends_with("_zscore")) %>%
  separate(name, c("coef", "PHENO"), sep="\\.") %>%
  pivot_wider(names_from = coef, values_from = value) %>%
  mutate(P=10^-LOG10P) %>%
  select(-CHISQ, -LOG10P)

n_tests <- n_distinct(results_long$GENE)
P_THRESH <- 0.05/n_tests

all_genes <- scan("all_genes.txt", character())
priority_genes <- scan("priority_genes.txt", character())

top_hits <- results_long %>%
  filter(TEST == "GENE_P" & P < P_THRESH) %>%
  group_by(GENE) %>%
  filter(P == min(P)) %>%
  ungroup %>%
  arrange(P) %>%
  select(PHENO, CHROM, GENE, GENE_P=P) %>%
  mutate(all_genes = GENE %in% all_genes, priority_genes = GENE %in% priority_genes)

top_hits_specific <- top_hits %>%
  left_join(results_long, by=c("PHENO", "CHROM", "GENE")) %>%
  filter(!is.na(THRESH)) %>%
  arrange(P, THRESH) %>%
  group_by(GENE) %>%
  slice(1) %>%
  ungroup %>%
  select(-ALLELE0, -ALLELE1, -EXTRA)

write_tsv(top_hits_specific, "LF_collapsing_top_hits.tsv")
