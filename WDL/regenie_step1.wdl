version 1.0

workflow regenie_step1 {

	input {
		Array[Array[File]] genos
		File pheno
		File? covar
		String? covarColList
		String? catCovarList
		Boolean bt
	}

	scatter(geno in genos) {
		call filter_genos {
			input:
				bed = geno[0],
				bim = geno[1],
				fam = geno[2],
				pheno = pheno
		}
	}

	call merge_genos {
		input:
			beds = filter_genos.out_bed,
			bims = filter_genos.out_bim,
			fams = filter_genos.out_fam
	}

	call filter_snps {
		input:
			bed = merge_genos.out_bed,
			bim = merge_genos.out_bim,
			fam = merge_genos.out_fam
	}

	call step1 {
		input:
			bed = merge_genos.out_bed,
			bim = merge_genos.out_bim,
			fam = merge_genos.out_fam,
			pheno = pheno,
			covar = covar,
			covarColList = covarColList,
			catCovarList = catCovarList,
			qc_id = filter_snps.out_id,
			qc_snplist = filter_snps.out_snplist,
			bt = bt
	}

	output {
		File genos_bed = merge_genos.out_bed
		File genos_bim = merge_genos.out_bim
		File genos_fam = merge_genos.out_fam
		File qc_id = filter_snps.out_id
		File qc_snplist = filter_snps.out_snplist
		File step1_pred_list = step1.pred_list
		Array[File] step1_loco = step1.loco
	}
}

task filter_genos {

	input {
		File bed
		File bim
		File fam
		File pheno
	}

	String out = basename(bed, ".bed")

	command <<<
		plink2 --bed "~{bed}" --bim "~{bim}" --fam "~{fam}" --keep "~{pheno}" --make-bed --out "~{out}_filt"
	>>>

	output {
		File out_bed = "~{out}_filt.bed"
		File out_bim = "~{out}_filt.bim"
		File out_fam = "~{out}_filt.fam"
	}

	runtime {
		cpu: 8
    memory: "64 GB"
	}
}

task merge_genos {

	input {
		Array[File] beds
		Array[File] bims
		Array[File] fams
	}

	String out = "ukb_cal_v2"

	command <<<
		cat "~{write_lines(beds)}" | sed -e 's/.bed//g' > merge_list.txt
		plink2 --pmerge-list merge_list.txt bfile --make-bed --out "~{out}"
	>>>

	output {
		File out_bed = "~{out}.bed"
		File out_bim = "~{out}.bim"
		File out_fam = "~{out}.fam"
	}

	runtime {
		cpu: 8
    memory: "100 GB"
	}
}

task filter_snps {

	input {
		File bed
		File bim
		File fam
	}

	command <<<
		plink2 --bed "~{bed}" --bim "~{bim}" --fam "~{fam}" \
			--geno 0.1 \
			--hwe 1e-15 \
			--mac 100 \
			--maf 0.01 \
			--mind 0.1 \
			--no-id-header \
			--out qc_pass \
			--write-samples \
			--write-snplist
	>>>

	output {
		File out_id = "qc_pass.id"
		File out_snplist = "qc_pass.snplist"
	}

	runtime {
		cpu: 2
		memory: "16 GB"
	}
}

task step1 {

	input {
		File bed
		File bim
		File fam
		File pheno
		File? covar
		File? qc_id
		File? qc_snplist
		String? covarColList
		String? catCovarList
		Boolean bt
	}

	String out = "fit_step1_out"

	command <<<
		bed_path="~{bed}"

		regenie\ 
			--step 1 \
			--bed "${bed_path%.bed}" \
			~{"--extract " + qc_snplist} \
			~{"--keep " + qc_id} \
			~{"--covarFile " + covar} \
			~{"--covarColList " + covarColList} \
			~{"--catCovarList " + catCovarList} \
			--phenoFile "~{pheno}" \
			--bsize 1000 \
			--lowmem \
			--lowmem-prefix . \
			~{true="--bt" false="--qt" bt} \
			--use-relative-path \
			--out "~{out}" \
			--threads 8
	>>>

	output {
		File pred_list = "~{out}_pred.list"
		Array[File] loco = glob("~{out}_*.loco")
	}

	runtime {
		cpu: 8
		memory: "64 GB"
	}
}
