version 1.0

workflow regenie_step2 {

	input {
		String output_prefix
		Array[Array[File]] genos
		Array[String] models = ["additive", "dominant", "recessive"]
		File pheno
		File? covar
		String? covarColList
		String? catCovarList
		File pred_list
		Array[File] loco
		Boolean bt
	}

  Array[Pair[String, Array[File]]] crossed = cross(models, genos)
  
  scatter (p in crossed) {
		call regenie_sv {
			input:
				model = p.left,
				bed = p.right[0],
				bim = p.right[1],
				fam = p.right[2],
				pheno = pheno,
				covar = covar,
				covarColList = covarColList,
				catCovarList = catCovarList,
				pred_list = pred_list,
				loco = loco,
				bt = bt
		}
	}

	scatter (m in models) {
		call merge_sv {
			input:
				prefix = output_prefix,
				model = m,
				results = regenie_sv.results		
		}
	}

	output {
		Array[File] sv_results = merge_sv.merged
	}
}

task regenie_sv {

	input {
		String model
		File bed
		File bim
		File fam
		File pheno
		File? covar
		String? covarColList
		String? catCovarList
		File pred_list
		Array[File] loco
		Boolean bt
	}

	String out = "~{basename(bed, '.bed')}_~{model}"

	command <<<
		bed_path="~{bed}"
		ln -s ~{sep=" " loco} .
		regenie \
			--step 2 \
			--bed "${bed_path%.bed}" \
			~{"--covarFile " + covar} \
			~{"--covarColList " + covarColList} \
			~{"--catCovarList " + catCovarList} \
			--phenoFile "~{pheno}" \
			--pred "~{pred_list}" \
			~{true="--bt" false="--qt" bt} \
			--bsize 400 \
			--test "~{model}" \
			--minMAC 3 \
			--threads=16 \
			--no-split \
			--out "~{out}"
	>>>

	output {
		File results = "~{out}.regenie"
	}

	runtime {
		dx_instance_type: "mem3_ssd1_v2_x16"
	}
}

task merge_sv {

	input {
		String prefix
		String model
		Array[File] results
	}

	String out = "~{prefix}_sv_~{model}.regenie.gz"

	command <<<
		awk 'NR == 1 || FNR > 1' `echo "~{sep=' ' results}" | grep -o "[^ ]*~{model}[^ ]*"` | gzip > ~{out}
	>>>
	
	output {
		File merged = out
	}

	runtime {
		cpu: 2
		memory: "16 GB"
	}
}
