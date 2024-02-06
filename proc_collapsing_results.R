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
  pivot_wider(names_from = coef, values_from = value)
