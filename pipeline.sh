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

# Reports paths
# FastQC reports will be on reports folder (./reports/fastqc)
REPORTS_PATH="./reports"
FASTQC_REPORTS_PATH="${REPORTS_PATH}/fastqc"
#FASTQC_REPORTS_PATH="/mnt/nupeb/molecular-markers-on-sports/reports/fastqc"
#FASTQC_REPORTS_PATH="."
mkdir -p ${FASTQC_REPORTS_PATH}

# Set local variables with tools commands on Docker images
CMD_FASTQC="docker run -v $(pwd):/data biocontainers/fastqc:v0.11.9_cv8 fastqc"
CMD_PRINSEQ="docker run -v $(pwd):/host dceoy/prinseq"
CMD_BCFTOOLS="docker run -v $(pwd):/data biocontainers/bcftools:v1.9-1-deb_cv1 bcftools"
CMD_SAMTOOLS="docker run -v $(pwd):/data biocontainers/samtools:v1.9-4-deb_cv1 samtools"
CMD_BAMTOOLS="docker run -v $(pwd):/data biocontainers/bamtools:v2.5.1dfsg-3-deb_cv1 bamtools"

# Extract if compressed
if [ "${FORWARD: -3}" == ".gz" ]; then
	# gzip -d $FORWARD
	FORWARD="${FORWARD:: -3}"
fi
if [ "${REVERSE: -3}" == ".gz" ]; then
	# gzip -d $REVERSE
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

	# ##################################### #
	# STEP 01 - Quality Analysis A: fastqc  #
	# ##################################### #

	# Verifify if files alread exists
	if test -f "${FASTQ}"; then
		echo "... Skipping step *Quality Analysis A*. ${FASTQ} already existis."
	else
		echo "... Executing step *Quality Analysis A*. Procesing ${FASTQ}"
		# - Execute FastQC Analysis
		${CMD_FASTQC} ${FASTQ} --outdir ${FASTQC_REPORTS_PATH} --threads 20
	fi


	# ################################### #
	# STEP 02 - Quality Control: prinseq  #
	# ################################### #

	# - Define namespace for prinqseq quality filter
	BASE_NAME="${INTERIM_PATH}/${FASTQ##*/}"
	# BASE_NAME="${BASE_NAME:: -10}"
	OUT_GOOD_PATH="${BASE_NAME}_Q${PHRED}_${MINLEN}_GOOD"
	OUT_BAD_PATH="${BASE_NAME}_Q${PHRED}_${MINLEN}_BAD"
	OUT_GRAPH="/host/reports/prinseq-lite"

	mkdir -p "${REPORTS_PATH}/prinseq-lite"

	echo "... Executing step *Quality Control*. Generating ${OUT_GOOD_PATH}"

	IN_PATH="${INTERIM_PATH}/${FASTQ##*/}"
	echo ${IN_PATH}

	# - Execute the prinseq quality filtering
	${CMD_PRINSEQ} -verbose -fastq ${IN_PATH} \
				-out_good ${OUT_GOOD_PATH} -out_bad {OUT_BAD_PATH} \
				-trim_qual_right ${PHRED} -trim_qual_window 5 \
				-trim_qual_step 1 -trim_qual_type min \
				-min_len ${MINLEN} -out_format 3 


	# ##################################### #
	# STEP 03 - Quality Analysis B: fastqc  #
	# ##################################### #

	# # Verifify if files alread exists
	# if test -f "${FASTQ}"; then
	# 	echo "... Skipping step *Quality Analysis B*. ${FASTQ} already existis."
	# else
	# 	echo "... Executing step *Quality Analysis B*. Procesing ${FASTQ}"
	# 	# - Execute FastQC Analysis
	# 	${CMD_FASTQC} ${FASTQ} --outdir ${FASTQC_REPORTS_PATH} --threads 20
	# fi


done
