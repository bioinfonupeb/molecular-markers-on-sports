FILENAMES=(
OMNI-21-LSS_S1_L002_R1_001.fastq.gz
OMNI-21-LSS_S1_L002_R2_001.fastq.gz 
OMNI-21-LSS_S1_L003_R1_001.fastq.gz 
OMNI-21-LSS_S1_L003_R2_001.fastq.gz 
OMNI-21-LSS_S1_L004_R1_001.fastq.gz 
OMNI-21-LSS_S1_L004_R2_001.fastq.gz 
)

FILEURLS=(
"https://drive.google.com/file/d/1wSa04PEYe_SNjjKP3SYeQhwQJGLHDzyI/view?usp=sharing"
"https://drive.google.com/file/d/1ivD7B4GdFQlwlC2XoyhvAChyoIrMuiqE/view?usp=sharing"
"https://drive.google.com/file/d/1ukKTZ8Yz6K_y8DOmiGfb8oEz9jFtJk6o/view?usp=sharing"
"https://drive.google.com/file/d/1_d0Y7CMZBFQWfpEH4xTpJfhcafw61Xdb/view?usp=sharing"
"https://drive.google.com/file/d/1MFqdKFxR_bTuHZiIBuBUxN7xQ3QEc4Pq/view?usp=sharing"
"https://drive.google.com/file/d/1bnT5Wrn7ubPqbJOm3fYLD3y_5KMRwYIx/view?usp=sharing"
)

for i in ${!FILENAMES[@]}; do
	# Extract info and set parameters
	FILENAME=${FILENAMES[i]};
	URL=${FILEURLS[i]};
	FILEID=$(echo ${URL} | tr "/" " " | awk '{print $5}';)

	echo "Downloading file ${FILENAME} with ID ${FILEID}";

	# Download a large file
	wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=${FILEID}' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${FILEID}" -O ${FILENAME} && rm -rf /tmp/cookies.txt

done

