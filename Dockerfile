FROM ghcr.io/rgcgithub/regenie/regenie:v3.5.gz

ARG PLINK2_VERSION=avx2_20240302

RUN apt update && apt install -y wget && apt install -y unzip && apt install -y libgomp1 && \
	wget https://s3.amazonaws.com/plink2-assets/plink2_linux_$PLINK2_VERSION.zip && \
	unzip -d /usr/local/bin plink2_linux_$PLINK2_VERSION.zip plink2 && \
	rm plink2_linux_$PLINK2_VERSION.zip
