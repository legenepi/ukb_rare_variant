# UK Biobank rare variant association testing pipeline
This pipeline runs single variant and gene-based collapsing analyses on the UK Biobank RAP

## Prerequisites
* A UK Biobank RAP project
* DNAnexus [dx toolkit](https://documentation.dnanexus.com/downloads)
* R with tidyverse and jsonlite packages

## Set up and running association tests
1. Edit *options.config* to define:
    - Your RAP project ID (`dx find projects`).
    - The path on the RAP to install the workflow to.
    - The output path on the RAP for results
    - The regenie format [phenotype](https://rgcgithub.github.io/regenie/options/#phenotype-file-format) and [covariate](https://rgcgithub.github.io/regenie/options/#covariate-file-format) files to upload.
    - Covariate specifications.
2. Run `install_workflows.sh` to install the WDL workflows to the RAP.
    - The first time *install_workflows.sh* is run it will create and upload the docker image to use that has regenie and plink2 installed.
3. Run `run_regenie_step1.sh` to run regenie step 1.
    - Log in to the RAP web interface to check this completes before proceeding.
5. Run `run_regenie_step2_SV.sh` to run single variant testing with the UK Biobank WES data.
6. Run `run_regenie_step2_collapsing.sh` to run gene-based collapsing analysis with the UK Biobank WES data.
7. When the association testing has run, download the results from the RAP output path you specified using `dx download`
