version 1.0

workflow collapsing {

	input {
		String output_prefix
		Array[Array[File]] genos
		File pheno
		File? covar
		File? exclude
		String? covarColList
		String? catCovarList
		File pred_list
		Array[File] loco
		File annot
		File setlist
		File mask
		String aaf_bins = "0.01,0.001,0.0001,0.00001"
		String joint_tests = "acat,sbat"
		Float maxaaf = 0.01
		String tests = "acato,skato"
	}

  scatter (g in genos) {
		call regenie_collapsing {
			input:
				bed = g[0],
				bim = g[1],
				fam = g[2],
				pheno = pheno,
				exclude = exclude,
				covar = covar,
				covarColList = covarColList,
				catCovarList = catCovarList,
				pred_list = pred_list,
				loco = loco,
				annot = annot,
				setlist = setlist,
				mask = mask,
				aaf_bins = aaf_bins,
				joint_tests = joint_tests,
				maxaaf = maxaaf,
				tests = tests
		}
	}

	call merge_collapsing {
		input:
			prefix = output_prefix,
			results = regenie_collapsing.results,
			dict = regenie_collapsing.dict
	}

	output {
		File collapsing_results = merge_collapsing.merged
	}
}

task regenie_collapsing {

	input {
		File bed
		File bim
		File fam
		File pheno
		File? covar
		File? exclude
		String? covarColList
		String? catCovarList
		File pred_list
		Array[File] loco
		File annot
		File setlist
		File mask
		String aaf_bins
		String joint_tests
		Float maxaaf
		String tests
	}

	String out = "~{basename(bed, '.bed')}"

	command <<<
		bed_path="~{bed}"
		ln -s ~{sep=" " loco} .
		plink2 --bfile "${bed_path%.bed}" \
			--keep "~{pheno}" \
			--no-psam-pheno \
			--freq \
			--out "~{out}" &&
		awk 'NR > 1 { print $2, ($5 < 0.5 ? $5 : 1 - $5) }' "~{out}.afreq" > "~{out}.maf" &&
		regenie \
			--step 2 \
			--bed "${bed_path%.bed}" \
			--nauto 23 \
			~{"--exclude " + exclude} \
			~{"--covarFile " + covar} \
			~{"--covarColList " + covarColList} \
			~{"--catCovarList " + catCovarList} \
			--phenoFile "~{pheno}" \
			--pred "~{pred_list}" \
			--qt \
			--anno-file ~{annot} \
			--set-list ~{setlist} \
			--mask-def ~{mask} \
			--aaf-file "~{out}.maf" \
			--aaf-bins ~{aaf_bins} \
			--joint ~{joint_tests} \
			--vc-maxAAF ~{maxaaf} \
			--vc-tests ~{tests} \
			--rgc-gene-p \
			--bsize 200 \
			--threads=16 \
			--no-split \
			--out "~{out}"
	>>>

	output {
		File results = "~{out}.regenie"
		File dict = "~{out}.regenie.Ydict"
	}

	runtime {
		dx_instance_type: "mem3_ssd1_v2_x16"
	}
}

task merge_collapsing {

	input {
		String prefix
		Array[File] results
		Array[File] dict
	}

	String out = "~{prefix}_collapsing.regenie.gz"

	command <<<
		awk 'NR == FNR {
			pheno[$1]=$2
			next
		}
		FNR == 2 {
			for (i in pheno)
				gsub(i, pheno[i], $0)
			print
		}
		FNR > 2 { print }' "~{dict[0]}" `echo "~{sep=' ' results}"` | gzip > ~{out}
	>>>
	
	output {
		File merged = out
	}

	runtime {
		cpu: 2
		memory: "16 GB"
	}
}
