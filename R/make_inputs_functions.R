require(tidyverse)

CHROMS <- c(1:22)

get_config <- function(x, prefix=NULL) {
    str_split_1(x, " ") %>%
        Sys.getenv(., names=TRUE) %>%
        set_names(~paste(prefix, ., sep=ifelse(is.null(prefix), "", "."))) %>%
        discard(. == "")
}

get_file_id <- function(path) {
  paste0("ls -l --brief '", path, "'") %>%
    system2("dx", ., stdout=TRUE) %>%
    paste0("dx://", .)
}

get_genos <- function(base, extract="", chroms="") {
    if (extract != "") { 
        chroms <- scan(extract, character(), quiet=TRUE) %>%
            str_remove(":.+") %>%
            unique
    } else if (chroms != "") {
        chroms <- str_split_1(chroms, " ")
    } else {
        chroms <- CHROMS
    }
    data.table::fread(cmd=paste0("dx ls -l '", base, "'"), header = FALSE) %>%
    as_tibble %>%
    select(filename=V6, dx=V7) %>%
    separate(filename, c("id", "chr", "b0", "v2", "ext")) %>%
    mutate(dx=str_replace(dx, "^\\(", "dx://") %>% str_remove("\\)$"),
           ext=factor(ext, levels=c("bed", "bim", "fam")),
           chr=str_remove(chr, "c")) %>%
    filter(chr %in% chroms) %>%
    mutate(chr=factor(chr, levels=CHROMS)) %>%
    arrange(chr, ext) %>%
    pull(dx) %>%
    matrix(ncol = 3, byrow = TRUE)
}

get_loco <- function(predList, results_dir) {
    cmd <- paste0("dx cat ", predList,
                  " | awk '{ print \"", results_dir, "/\"$2 }' | while read f; do dx ls --brief $f; done")
    con <- pipe(cmd)
    loco <- scan(con, character(), quiet=TRUE)
    close(con)
    paste0("dx://", loco) %>%
        as.list
}

get_upload_id <- function(file, path) {
    cmd <- paste0("ls '", path, "/", file, "'")
    if (system2("dx", cmd, stdout=FALSE, stderr=FALSE) == 0)
        system2("dx", cmd %>% str_replace("ls", "rm -a"))
    upload_cmd <- paste0("upload --brief --no-progress --destination '", path, "/' '", file, "'")
    system2("dx", upload_cmd, stdout=TRUE) %>%
        paste0("dx://", .)
}
