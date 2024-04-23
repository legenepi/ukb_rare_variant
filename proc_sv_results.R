library(tidyverse)
library(GenomicRanges)

THRESHOLD <- 5E-6

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

#
# V2G section
#

results_use <- results %>%
  filter(P < THRESHOLD & MAF < 0.01) %>%
  group_by(ID) %>%
  filter(P == min(P)) %>%
  ungroup

LF_1020 <- read_tsv("LF_1020_hg38.txt")

results_use.GRanges <- results_use %>%
  mutate(CHROM=as.character(CHROM) %>% sub("23", "X", .)) %>%
  makeGRangesFromDataFrame(seqnames.field = "CHROM", start.field = "GENPOS", end.field = "GENPOS",
                           keep.extra.columns = TRUE)

LF_1020.GRanges <- LF_1020 %>%
  makeGRangesFromDataFrame(seqnames.field = "chr", start.field = "pos", end.field = "pos",
                           keep.extra.columns = TRUE)

v2g <- mergeByOverlaps(LF_1020.GRanges, results_use.GRanges, maxgap = 5E5) %>%
  as.data.frame %>%
  as_tibble %>%
  dplyr::rename(CHROM=LF_1020.GRanges.seqnames,
                POS.LF_1020=LF_1020.GRanges.start,
                POS.ExWAS=results_use.GRanges.start) %>%
  select(-contains("GRanges")) %>%
  mutate(dist=abs(POS.LF_1020 - POS.ExWAS)) #%>%
  # arrange(dist, P) %>%
  # group_by(sentinel) %>%
  # dplyr::slice(1) %>%
  # ungroup %>%
  # arrange(CHROM, POS.ExWAS)

v2g.vep <- v2g %>%
  mutate(REF=ifelse(A1FREQ < 0.5, ALLELE0, ALLELE1),
         ALT=ifelse(A1FREQ < 0.5, ALLELE1, ALLELE0),
         INDEL=nchar(REF) + nchar(ALT) > 2,
         REF_fmt=ifelse(INDEL, str_replace(REF, "^.", ifelse(nchar(REF) > 1, "", "-")), REF),
         ALT_fmt=ifelse(INDEL, str_replace(ALT, "^.", ifelse(nchar(ALT) > 1, "", "-")), ALT),
         start=ifelse(!INDEL | REF_fmt != "-", POS.ExWAS, POS.ExWAS + 1),
         end=ifelse(INDEL & ALT_fmt == "-", POS.ExWAS + nchar(REF_fmt) - 1, POS.ExWAS), 
         alleles=paste(REF_fmt, ALT_fmt, sep="/"),
         strand="+") 
  
  
v2g.vep %>%
  dplyr::select(CHROM, start, end, alleles, strand, ID) %>%
  distinct %>%
  write.table("v2g.vep", col.names = F, row.names = F, quote = F, sep="\t")

vep <- read_tsv("results_cache.vep", na = "-", comment = "##")

# vep_single <- vep %>%
#   filter(grepl("missense", Consequence) | Consequence == "stop_gained") %>%
#   mutate(IMPACT=factor(IMPACT), levels=c("HIGH", "MODERATE", "LOW")) %>%
#   arrange(IMPACT, P) %>%
#   group_by(`#Uploaded_variation`) %>%
#   dplyr::slice(1) %>%
#   ungroup %>%
#   mutate(v2g = !is.na(SYMBOL) &
#       (grepl("missense_variant", Consequence) |
#          (!is.na(CADD_PHRED) & CADD_PHRED >= 20.0) |
#          grepl("deleterious", SIFT, ignore.case = TRUE) |
#          grepl("damaging", PolyPhen, ignore.case = TRUE)))



v2g_annot <- v2g %>%
  inner_join(vep, by=c("ID"="#Uploaded_variation"))

v2g_out <- v2g_annot %>%
  group_by(sentinel) %>%
  summarise(gene=paste(unique(SYMBOL), collapse="; "))

write_tsv(v2g_out, "V2G_ExWAS.txt")
