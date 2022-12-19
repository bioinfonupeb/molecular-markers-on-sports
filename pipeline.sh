#! /bin/bash

# Set Forward and Reverse fastq files
PHRED=$1
MINLEN=$2
FORWARD=$3
REVERSE=$4

# Data paths
# Put .fastq.gz files in ./data/raw and .fastq files in ./data/interim
RAW_PATH="/host/data/raw"
INTERIM_PATH="/host/data/interim"
RAW_PATH="./data/raw"
INTERIM_PATH="./data/interim"

# Reports paths
# FastQC reports will be on reports folder (./reports/fastqc)
REPORTS_PATH="./reports"
FASTQC_REPORTS_PATH="${REPORTS_PATH}/fastqc"
#FASTQC_REPORTS_PATH="/mnt/nupeb/molecular-markers-on-sports/reports/fastqc"
#FASTQC_REPORTS_PATH="."
mkdir -p ${FASTQC_REPORTS_PATH}

# Set local variables with tools commands on Docker images
# --user $(id -u):$(id -g)
CMD_FASTQC="docker run --rm -v $(pwd):/data biocontainers/fastqc:v0.11.9_cv8 fastqc"
CMD_PRINSEQ="docker run --rm -v $(pwd):/data --workdir /data dceoy/prinseq"
CMD_PRINSEQ="docker run -it --rm -v $(pwd):/data --workdir /data quay.io/biocontainers/prinseq-plus-plus:1.2.4--h7ff8a90_2 prinseq++"
CMD_BCFTOOLS="docker run --rm -v $(pwd):/data biocontainers/bcftools:v1.9-1-deb_cv1 bcftools"
CMD_SAMTOOLS="docker run --rm -v $(pwd):/data biocontainers/samtools:v1.9-4-deb_cv1 samtools"
CMD_BAMTOOLS="docker run --rm -v $(pwd):/data biocontainers/bamtools:v2.5.1dfsg-3-deb_cv1 bamtools"

# Extract if compressed
if [ "${FORWARD: -3}" == ".gz" ]; then
	gzip -d $FORWARD
	FORWARD="${FORWARD:: -3}"
fi
if [ "${REVERSE: -3}" == ".gz" ]; then
	gzip -d $REVERSE
	REVERSE="${REVERSE:: -3}"
fi

# Iterate over each file
FASTQ_RAW=($FORWARD $REVERSE)
for f in "${FASTQ_RAW[@]}"; do

	# #################################### #
	# STEP 00 - Decompress gz files: gzip  #
	# #################################### #

	# Extract if compressed and get fastq path
	if [ "${f: -3}" == ".gz" ]; then
		FASTQ="${f:: -3}"
		echo "... Extracting file ${f} to ${FASTQ}"
		gzip -d $f
	else
		FASTQ="${f}"
	fi

	# Extract only the fastq file name
	BASENAME_FASTQ=${FASTQ##*/}
	# Extract file name without extension
	FILENAME=${BASENAME_FASTQ:: -6}

	# ##################################### #
	# STEP 01 - Quality Analysis A: fastqc  #
	# ##################################### #

	# Verifify if files alread exists
	FASTQC_PATH="${FASTQC_REPORTS_PATH}/${FILENAME}_fastqc.html"
	if test -f "${FASTQC_PATH}"; then
		echo "... Skipping step *Quality Analysis A*. ${FASTQC_PATH} already existis."
	else
		echo "... Executing step *Quality Analysis A*. Procesing ${FASTQ} to ${FASTQC_PATH}"
		# - Execute FastQC Analysis
		${CMD_FASTQC} ${FASTQ} --outdir ${FASTQC_REPORTS_PATH} --threads 20
	fi


	# ##################################### #
	# STEP 02 - Quality Control: prinseq++  #
	# ##################################### #

	# - Define namespace for prinqseq quality filter
	IN_PATH="${INTERIM_PATH}/${BASENAME_FASTQ}"
	OUT_GOOD_PATH="${INTERIM_PATH}/${FILENAME}_Q${PHRED}_${MINLEN}_GOOD"
	OUT_BAD_PATH="${INTERIM_PATH}/${FILENAME}_Q${PHRED}_${MINLEN}_BAD"

	# Verify if fastq already was filtered
	if test -f "${OUT_GOOD_PATH}.fastq"; then
		echo "... Skipping step *Quality Control*. File ${OUT_GOOD_PATH}.fastq already existis."
	else
		echo "... Executing step *Quality Control*. Processing ${IN_PATH}"

		# - Execute the prinseq quality filtering
		${CMD_PRINSEQ}	-fastq ${IN_PATH} \
						-out_good "${OUT_GOOD_PATH}.fastq" -out_bad "${OUT_BAD_PATH}.fastq" \
						-trim_qual_right ${PHRED} -trim_qual_window 5 \
						-trim_qual_step 1 -trim_qual_type min \
						-min_len ${MINLEN} -out_format 0 \
						-threads 20
	fi



	# ##################################### #
	# STEP 03 - Quality Analysis B: fastqc  #
	# ##################################### #

	# Verifify if files alread exists
	if test -f "${OUT_GOOD_PATH}_fastqc.html"; then
		echo "... Skipping step *Quality Analysis B*. ${OUT_GOOD_PATH}_fastqc.html already existis."
	else
		echo "... Executing step *Quality Analysis B*. Procesing ${OUT_GOOD_PATH}_fastqc.html"
		# - Execute FastQC Analysis
		${CMD_FASTQC} "${OUT_GOOD_PATH}.fastq" --outdir ${FASTQC_REPORTS_PATH} --threads 20
	fi

	# ############################################ #
	# STEP 03 - Align reads to reference : Bowtie2 #
	# ############################################ #

	# - Define namespace for bowtie2 sequence aligner
	REFBASE="GCF_000001405.40_GRCh38.p14_genomic_index_base"
	REFERENCE="${RAW_PATH}/reference/${REFBASE}"

	# Build reference: Already build
	# TODO: Verify to build
	# TODO: Test build
	#bowtie2-build -f /home/esther_verlane_lbcm/identifyofmolecularmarkes-project/reference/GCF_000001405.40_GRCh38.p14_genomic.fna GCF_reference_index_base

	# Align reads
	bowtie2 --very-sensitive 
			-x ${REFERENCE}
			-1 ~/identifyofmolecularmarkes-project/reads/filtered/OMNI-22-MV_S2_L001_R1_Q30_35.fastq 
			-2 ~/identifyofmolecularmarkes-project/reads/filtered/OMNI-22-MV_S2_L001_R2_Q30_35.fastq 
			-S OMNI-22-MV_S2_L001_bowtie2.sam



done