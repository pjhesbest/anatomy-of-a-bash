#!/usr/bin/env bash

# Help message
Help(){
    echo "qc-reads.illumina.sh
        Required:
            -f      path to forward/R1 FASTQ
            -r      path to reverse/R2 FASTQ
        Optional:
            -o      path to output directory (default : current directory)
            -t      number of threads (default : 4)
            -h      print this help message and exit
"
}

# Define arguments
while getopts f:r:o:t:Q:h option
do 
    case "${option}" in
        i)ID=${OPTARG};;
        f)forward=${OPTARG};;
        r)reverse=${OPTARG};;
        o)output=${OPTARG};;
        t)threads=${OPTARG};;
        q)minQval=${OPTARG};;
        h)Help; exit;;
    esac
done

# Error messages and defaults for input flags
if [[ -z ${forward} || -z ${reverse} ]]; then echo "ERROR: R1 or R2 missing"; Help; exit 1; fi

if [[ -z ${output} ]]; then output="$(pwd)/qc-reads"; fi
if [[ -z ${minQval} ]]; then minQval=30; fi

# activate virtual environment
eval "$(conda shell.bash hook)"
conda activate bbmap-env

# Make output directory if it doesnt already exist
mkdir -p ${output}

# Adaptor trimming - make sure the path to the Illumina adaptors is correct!

bbduk.sh -Xmx512m -da \
        in1=${forward} in2=${reverse} \
        out1=${output}/tmp-001.${ID}_R1.fastq.gz out2=${output}tmp-001.${ID}_R2.fastq.gz \
        ktrim=rl k=23 mink=11 hdist=1 qtrim=rl trimq=${minQval} \
        ref=/path/to/bbmap/resources/adapters.fa

# Quality filtering: This will discard reads with average quality below 10.
# If quality-trimming is enabled, the average quality will be calculated
# on the trimmed read.

bbduk.sh -Xmx512m -da \
        in1=${output}/tmp-001.${ID}_R1.fastq.gz in2=${output}/tmp-001.${ID}_R2.fastq.gz \
        out1=${output}/tmp-002.${ID}_R1.fastq.gz out2=${output}/tmp-002.${ID}_R2.fastq.gz maq=${minQval}

# Entropy filtering
bbduk.sh -Xmx512m -da \
        in1=${output}/tmp-002.${ID}_R1.fastq.gz in2=${output}/tmp-002.${ID}_R2.fastq.gz \
        out1=${output}/${ID}.qc_R1.fastq.gz out2=${output}/${ID}.qc_R2.fastq.gz \
        entropy=0.90

rm ${output}/tmp-001.${ID}_R1.fastq.gz ${output}/tmp-001.${ID}_R2.fastq.gz ${output}/tmp-002.${ID}_R1.fastq.gz ${output}/tmp-002.${ID}_R2.fastq.gz

# close conda environment
conda deactivate