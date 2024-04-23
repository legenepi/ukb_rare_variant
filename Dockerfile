FROM ubuntu:20.04

ENV PLINK2_VERSION=avx2_20240302
ENV REGENIE_VERSION=3.4.1

RUN apt update && apt install -y wget && apt install -y unzip && apt install -y libgomp1 && \
	wget https://s3.amazonaws.com/plink2-assets/plink2_linux_$PLINK2_VERSION.zip && \
	unzip -d /usr/local/bin plink2_linux_$PLINK2_VERSION.zip plink2 && \
	rm plink2_linux_$PLINK2_VERSION.zip && \
	wget https://github.com/rgcgithub/regenie/releases/download/v$REGENIE_VERSION/regenie_v$REGENIE_VERSION.gz_x86_64_Centos7_mkl.zip && \
	unzip -d /usr/local/bin regenie_v$REGENIE_VERSION.gz_x86_64_Centos7_mkl.zip regenie_v$REGENIE_VERSION.gz_x86_64_Centos7_mkl && \
	mv /usr/local/bin/regenie_v$REGENIE_VERSION.gz_x86_64_Centos7_mkl /usr/local/bin/regenie && \
	rm regenie_v$REGENIE_VERSION.gz_x86_64_Centos7_mkl.zip
