version 1.0

workflow regenie_step2_collapsing {

	input {
		String output_prefix
		Array[Array[File]] genos
		Array[String] models = ["max"]
		File pheno
		File? covar
		File? exclude
		String? covarColList
		String? catCovarList
		File pred_list
		Array[File] loco
		Boolean bt
		File annot
		File setlist
		File mask
		Array[Float] aaf_bins = [0.01,0.001,0.0001,0.00001]
		String joint_tests = "acat,sbat"
		Float maxaff = 0.01
		String tests = "acatv,skato"
	}

	Array[Pair[String, Array[File]]] crossed = cross(models, genos)
	
	scatter (p in crossed) {
		call regenie_collapsing {
			input:
				model = p.left,
				bed = p.right[0],
				bim = p.right[1],
				fam = p.right[2],
				pheno = pheno,
				covar = covar,
				exclude = exclude,
				covarColList = covarColList,
				catCovarList = catCovarList,
				pred_list = pred_list,
				loco = loco,
				bt = bt,
				annot = annot,
				setlist = setlist,
				mask = mask,
				aaf_bins = aaf_bins,
				joint_tests = joint_tests,
				maxaff = maxaff,
				tests = tests
		}
	}

	scatter (m in models) {
		call merge_collapsing {
			input:
				prefix = output_prefix,
				model = m,
				results = regenie_collapsing.results,
				dict = regenie_collapsing.dict
		}
	}

	output {
		Array[File] collapsing_results = merge_collapsing.merged
	}
}

task regenie_collapsing {

	input {
		String model
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
		Boolean bt
		File annot
		File setlist
		File mask
		Array[Float] aaf_bins
		String joint_tests
		Float maxaff
		String tests
	}

	String out = "~{basename(bed, '.bed')}_~{model}"

	command <<<
		bed_path="~{bed}"
		ln -s ~{sep=" " loco} .
		regenie \
			--step 2 \
			--bed "${bed_path%.bed}" \
			~{"--exclude " + exclude } \
			~{"--covarFile " + covar} \
			~{"--covarColList " + covarColList} \
			~{"--catCovarList " + catCovarList} \
			--phenoFile "~{pheno}" \
			--pred "~{pred_list}" \
			~{true="--bt" false="--qt" bt} \
			--bsize 200 \
			--anno-file "~{annot}" \
			--set-list "~{setlist}" \
			--mask-def "~{mask}" \
			--build-mask "~{model}" \
			--nauto 23 \
			--aaf-bins "~{sep=',' aaf_bins}" \
			--joint "~{joint_tests}" \
			--vc-maxAAF "~{maxaff}" \
			--vc-tests "~{tests}" \
			--rgc-gene-p \
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
		String model
		Array[File] results
		Array[File] dict
	}

	String out = "~{prefix}_collapsing_~{model}.regenie.gz"

	command <<<
		awk 'NR == FNR {
			pheno[$1]=$2
			npheno++
			next
		}
		NR == npheno + 2 {
			for (i in pheno)
				gsub(i, pheno[i], $0)
			print
		}
		FNR > 2 { print }' "~{dict[0]}" `echo "~{sep=' ' results}" | grep -o "[^ ]*~{model}[^ ]*"` | gzip > ~{out}
	>>>
	
	output {
		File merged = out
	}

	runtime {
		cpu: 2
		memory: "16 GB"
	}
}
