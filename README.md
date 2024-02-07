# ukb_rare_variant
Rare variant analysis on UKB RAP

1. *update_docker.sh* - creates a docker image from Dockerfile and creates extraOptions.json pointing to the docker image on the RAP for the workflow installation below
2. *install_XXX.sh scripts* - creates the required input .json files for each .wdl workflow (calls *make_XXX_inputs.sh*) and installs the workflow on the RAP 
3. Once the workflow is installed and you get a workflow ID returned from step 2, run the workflow as:
    dx run -f inputs_XXX.dx.json <workflow id>
