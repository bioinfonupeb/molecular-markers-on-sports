#! /bin/bash

# Set Forward and Reverse fastq files
PHRED=$1
MINLEN=$2
FORWARD=$3
REVERSE=$4

# Put .fastq.gz files in ./data/raw and .fastq files in ./data/interim
RAW_PATH="$(pwd)/data/raw"
INTERIM_PATH="$(pwd)/data/interim"
ROOT_PATH="/mnt/nupeb/molecular-markers-on-sports"

# FastQC reports will be on reports folder (./reports/fastqc)
REPORTS_PATH="$(pwd)/reports"
FASTQC_REPORTS_PATH="${REPORTS_PATH}/fastqc"
FASTQC_REPORTS_PATH="/mnt/nupeb/molecular-markers-on-sports/reports/fastqc"
FASTQC_REPORTS_PATH="."
mkdir -p ${FASTQC_REPORTS_PATH}

# Set local variables with tools commands on Docker images
CMD_FASTQC="docker run -v $(pwd):/data biocontainers/fastqc:v0.11.9_cv8 fastqc"
CMD_PRINSEQ="docker run dceoy/prinseq prinseq-lite"
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

#FASTQC_REPORTS_PATH="/mnt/nupeb/molecular-markers-on-sports/reports/fastqc"
# Iterate over each file
FASTQ_RAW=($FORWARD $REVERSE)
for f in "${FASTQ_RAW[@]}"; do
	# Extract if compressed and get fastq path
	if [ "${f: -3}" == ".gz" ]; then
		# gzip -d $f
		FASTQ="${f:: -3}"
	else
		FASTQ="${f}"
	fi

	# ################################### #
	# STEP 01 - Quality Analysis: fastqc  #
	# ################################### #

	# - Execute FastQC Analysis
	${CMD_FASTQC} ${FASTQ} --outdir ${FASTQC_REPORTS_PATH} --threads 20

	# - Move output FastQC data (.html, .zip) to `./reports/fastqc`
	mv *fastqc.html ${FASTQC_REPORTS_PATH}
	mv *fastqc.zip ${FASTQC_REPORTS_PATH}

	# ################################### #
	# STEP 02 - Quality Control: prinseq  #
	# ################################### #

	# - Define namespace for prinqseq quality filter
	BASE_NAME="${FASTQ:: -10}"
	OUT_GOOD="${BASE_NAME}_Q${PHRED}_${MINLEN}_GOOD"
	OUT_BAD="${BASE_NAME}_Q${PHRED}_${MINLEN}_BAD"

	# # - Execute the prinseq quality filtering
	# ${CMD_PRINSEQ} -verbose -fastq ${FORWARD} \
	# 			-out_good ${OUT_GOOD} -out_bad {OUT_BAD} \
	# 			-trim_qual_right ${PHRED} -trim_qual_window 5 \
	# 			-trim_qual_step 1 -trim_qual_type min \
	# 			-min_len ${MINLEN} -out_format 3
done
