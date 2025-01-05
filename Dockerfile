FROM ghcr.io/rgcgithub/regenie/regenie:v3.5.gz

RUN apt update && apt install -y wget && apt install -y unzip && apt install -y libgomp1 && apt install -y plink2 
