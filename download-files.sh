FILENAMES=(
OMNI-22-MV_S2_L002_R2_001.fastq.gz
)

FILEURLS=(
"https://drive.google.com/file/d/1he__euBsD7Y-eMCVAfXZxLBxmuPkxbwW/view?usp=sharing"
)

for i in ${!FILENAMES[@]}; do
	# Extract info and set parameters
	FILENAME=${FILENAMES[i]};
	URL=${FILEURLS[i]};
	FILEID=$(echo ${URL} | tr "/" " " | awk '{print $5}';)

	echo "Downloading file ${FILENAME} with ID ${FILEID}";

	# Download a large file
	wget --wait 10 --random-wait --continue --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=${FILEID}' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=${FILEID}&key=AIzaSyD9AGm-E41y57R-VBh_LOFVgZ-4pD9AK1g" -O ${FILENAME} && rm -rf /tmp/cookies.txt
	gzip -d ${FILENAME}

done

