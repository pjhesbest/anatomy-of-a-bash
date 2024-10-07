#!/usr/bin/env bash

# Help message
Help(){
    echo "assembly.sh
        Required:
            -f      path to forward/R1 FASTQ
            -r      path to reverse/R2 FASTQ
        Optional:
            -o      path to output directory (default : current directory)
            -t      number of threads (default : 4)
            -Q      Disable SPAdes read error correction and just perform assembly (default : false)
            -h      print this help message and exit
"
}

# Define arguments
while getopts f:r:o:t:Q:h option
do 
    case "${option}" in 
        f)forward=${OPTARG};;
        o)reverse=${OPTARG};;
        o)output=${OPTARG};;
        t)threads=${OPTARG};;
        Q)QCSPAdes=false;;
        h)Help; exit;;
    esac
done

# Error messages and defaults for input flags
if [[ -z ${forward} || -z ${reverse} ]]; then echo "ERROR: R1 or R2 missing"; Help; exit 1; fi
if [[ -z ${output} ]]; then output=$(pwd); fi

# activate virtual environment
eval "$(conda shell.bash hook)"
conda activate spades-env

# Run spades either with or without error correction
if [[ QCSPADes == true ]]; then 
  spades.py -1 sample-1_R1.fastq.gz -2 sample-1_R2.fastq.gz -o sample-1_assembly-out --only-assembler
elif [[ QCSPADes == false ]]; then
  spades.py -1 sample-1_R1.fastq.gz -2 sample-1_R2.fastq.gz -o sample-1_assembly-out
fi

# close conda environment
conda deactivate