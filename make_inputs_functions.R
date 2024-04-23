require(tidyverse)

get_file_id <- function(path, project) {
  paste0("ls -l --brief ", project, ":", path) %>%
    system2("dx", ., stdout=TRUE) %>%
    paste0("dx://", .)
}

get_genos <- function(base, project) {
  data.table::fread(cmd=paste0("dx ls -l '", project, ":", base, "'"),
                    header = FALSE) %>%
    as_tibble %>%
    select(filename=V6, dx=V7) %>%
    separate(filename, c("id", "chr", "b0", "v2", "ext")) %>%
    mutate(dx=str_replace(dx, "^\\(", "dx://") %>% str_remove("\\)$"),
           ext=factor(ext, levels=c("bed", "bim", "fam")),
           chr=str_remove(chr, "c")) %>%
    filter(chr %in% 1:22) %>%
    mutate(chr=chr %>% as.integer) %>%
    arrange(chr, ext) %>%
    pull(dx) %>%
    matrix(ncol = 3, byrow = TRUE)
}

get_loco <- function(predList, project) {
    cmd <- paste0("dx cat ", project, ":", predList,
                  " | cut -f 2 -d ' ' | while read f; do dx ls --brief $f; done")
    con <- pipe(cmd)
    loco <- scan(con, character())
    close(con)
    paste0("dx://", loco)
}
