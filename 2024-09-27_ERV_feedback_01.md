# Script Feedback 2024-09-26
## Main issues:
1. Currently this script can only be run from the same directory as the input and the output, this might be personal preference, but I find that very restrictive.
2. The script conducts both single-genome analysis and comparative genome analysis. While there is nothing wrong with taking this approach, greating a generic script that can be used on a single genome means you can submit lots of genomes to the HPC to be pre-prossesed and assembled at once, leaving the comparative analysis to its own script:
    - This script does relatively heavy processing jobs (de novo assembly of genomes) as a loop. This will take a long time. If this script was run like below, you would have flexibility to assemble any genome internally pretty smoothly, as you could submit all your genomes to process rather than wait for a single script to do all of them... eventualy
    ```{sh}
    ERV.assembly.sh -f ${SAMPLEID}_R1-fastq.gz -r ${SAMPLEID}_R1-fastq.gz -n ${SAMPLEID}
    ```
    - In the current format if something goes wrong with one genome, you won't know till the end of your script and re-running from the beginning means re-running everything (even stuff that that did work as expected)
3. Comparative analysis is something that you really do want more flexibility and control over the parameters being applies, and possibly incorporating some additional processing so that the final output of the script is a dataframe that works for importing directly to R, or even a few preliminary plots generated to help you understand if the analysis worked as expected. This is why i would have your final section as its own script (though this is personal preferences.)

Ultimately what you have written will work (there are a few broken paths I think that would need to be fixed), but it would only really be advisable to be run on a small dataset and would produce a very disordely output directory, and must be run in the same location as your raw data - which means you end up mixing clean data, with intermediate files and final results... very messy workspace.

## Breakdown
### The start of your script 

This is the place to begin defining a lot of features of how your script will run. Printing timestamps, outputing the run to a log file, defining variables... all will allow you to create complex and multifunctional scripts.

Currently you have a very simple script structure that will run uninterrupted, using a lot of wildcards (* - which can get risky), relies on a lot of loops (can make things really slow), and has not designated input or output except for whatever exists in the directory. This is not really a problem for a functioning version of the script, but while you are still writing and troubleshooting, can cause issues with identifying where you script is groing wrong.

Lots of additional BASH functions can be utilised to halt the script when big error occur.

1. <code>set -euxo pipefail</code>: this causes the script to halt when errors are encountered to aid with troubleshooting (you can remove when you are happy with how the script runs)
2. This script has not variables that add flexibility to it (such as input/output)
    - I use the while argument: <code>while getopts</code> (see example below)
3. IF argument to ensure that when the script is run certain flags are defined
4. Scripts that print out logs are also really valuable if you are running it locally
    - in this example I am using a variable called <code>${logstamp}</code> that has the date and time and thats used make the log-file unique to each run - you could expand this to be even more specific, such as using the variables defined from the input (i.e. sample name or project ID)
5. The working environment is only here defined by letting BASH access conda through shell : <code>eval "$(conda shell.bash hook)"</code>
    - improvement to this might be defining a working directory (i.e. can use one of the argument flags to request a path to a working directory).
    - Can also define some fixed variables (i.e. where to find specific databases for some tools, reference genomes ect.) - or chage them into optional flags with defaults.

So a better defined start of your script might look something like this:

```{sh}
#!/usr/bin/env bash
set -euxo pipefail             # (1) pipefail flag

################################################################################

# Help message                 # (2) to collect all the input arguments and the help message
Help()
{
echo -e "YOUR HELP MESSAGE"
echo -e "Required flags:"
echo -e "   -a  The A thing"
echo -e "   -b  The B thing"
echo -e "Optional flags:"
echo -e "   -c  The C thing (default : -c 2)"
echo -e "   -h  Print this help message and exit."
echo -e "Example:"
echo -e "e.g. bash myscript.sh -a /path/to/A.thing -b "The B thing" -c 5 "
}

# Define flags/arguments/parameters
#   let me know if this confuses you
while getopts a:b:c:h option
do 
    case "${option}" in 
        a)A=${OPTARG};;
        b)B=${OPTARG};;
        c)C=${OPTARG};;
        h)Help; exit;;
    esac
done

################################################################################

# Check argument flags              # (3) IF argument to check script can proceed
## REQUIRED arguments
if [[ -z "${A}" || -z "${B}" ]];            # incase both -a and -b are missed
        then echo -e "ERROR: -a and -b are missing"; Help, exit 1; 
    elif [[ -z "${A}" ]]; then              # only -a is missed
        echo -e "ERROR: -a is missing"; Help, exit 1; 
    elif [[ -z "${B}" ]]; then              # only -b is missed
        echo -e "ERROR: -b is missing"; Help, exit 1; 
fi

## OPTIONAL arguments
if [[ -z "${C}" ]]; then C=2; fi      # if -c is not defined, then make C the default value

################################################################################

# Logfile generation                   # (4) Print a .log file of the outputs of the script
logstamp=$(date '+%Y%m%d%H%M%S') # Define the log file with the timestamp in its name
logfile="my-script_${logstamp}.log" # Redirect both stdout and stderr to the log file
exec > >(tee -a "${logfile}") 2>&1

################################################################################

# Set up environment                # (5) Working enviornment set up
eval "$(conda shell.bash hook)"

WD=${A}; cd ${WD}       # lets say in this example, the flag -a defines the path to the 
                        #   working directory running the script

# Define paths to databases, references, whatever you need! 
# (Or these can all be made optional flags with default paths as an alternative way!)
BARCODES=/path/to/illumina/barcodes.fasta
KAIJU=/path/to/kaiju/database/

################################################################################
################################################################################
```

### Main Modules

So now your script is composed of multiple 'modules' - what I would call the litle chunks of analysis that move from one to the next (often dependent on the output from the previous module). 

Now that there are variables defined for the script to run such as a working directory // <code>${WD}</code>, you have a lot more flexibiliy in where you can run the script from as the script can recall full paths to outputs/inputs rather than relative paths.

#### 1. QC before trimming

In your original version you were using a wildcard (\*) to find all the R1/R2 files. In this example its fine, and will work. If the script was to only look and apply the wildcard speficically to <code>*.fastq.gz</code> it is limited to what it can run on. Where possible I encourage you to make your use of wildcards *very very* specific (see the two examples below).

```{sh}
################################################################################

######### MAIN #########

################################################################################

# 1. QC before trimming
# (1) Printing our progress text to show where the script is when you chech
#           the log files - can also be used identify where yours script failed
echo -e "Quality control of Illumina reads"        

conda activate fastqc

mkdir -p ${WD}/fastqc               # use more specific path names for the outputs
                                    #   -p just tells mkdir that if the directory exists dont create a new one
cd ${WD}/fastqc

## Example 1.                             # in this example here we can use ${B} as the sample name that 
fastqc -o ${WD}/fastqc ${B}_R*.fastq.gz   #   prefixes sample ID, so you can still use a wildcard (for the R1 
                                          #   and R2), but theres more control in what will be searched for.

## Example 2.
RAW_FASTQ=${B}                                   # In this example ${B} couold be the path to a 
fastqc -o ${WD}/fastqc ${RAW_FASTQ}/*.fastq.gz   #   directory that contains all the raw data

multiqc ${WD}/fastqc                      # This way you can define where you want multiQC to 

conda deactivate

cd ${WD}                                   # return to the WD for the next module

################################################################################
```

#### 2. Adapter trimming

Here you use a loop and wildcards to run trimmomatic, again, this is fine, but has limited flexibility.
Your original version was good, I would just make similar changes as in the fastqc module, with adding absolute paths to improve the efficiency of using a wildcard.

Personal choices do come into this a lot, so you dont have to take everything I do onboard - like I frequently capitalise variables, just so it stands out clearly in the code. Same as with adding <code>echo -e "Performing XXXX"</code>, to mark each process running. Its not necessary but create code other people can use as things are very clearly marked at both user and developer end.

```{sh}
################################################################################

# 2. Adapter trimming
conda activate trimmomatic
mkdir -p ${WD}/trimmomatic

for FILE in ${RAW_FASTQ}/*_R1_001.fastq.gz ; do
    ID=$(basename "${FILE}" _R1_001.fastq.gz)
    echo "running trimmomatic on ${ID}"
    trimmomatic PE "${ID}_R1_001.fastq.gz" "${ID}_R2_001.fastq.gz" \
                "${WD}/trimmomatic/${ID}_R1_001_paired.fastq.gz" "${WD}/trimmomatic/${ID}_R1_001_unpaired.fastq.gz" \
                "${WD}/trimmomatic/${ID}_R2_001_paired.fastq.gz" "${WD}/trimmomatic/${ID}_R2_001_unpaired.fastq.gz" \
                ILLUMINACLIP:/home/seqadmin/miniconda3/envs/trimmomatic/bin/adapters/TruSeq3-PE.fa:2:30:10 \
                LEADING:3 TRAILING:3 SLIDINGWINDOW:5:25 MINLEN:60
    echo "trimming on ${ID} finished"
done

conda deactivate

################################################################################
```

#### 3. QC after trimming

Same modifications as before, using complete paths when running tools (with the help of variables), this also means that you are not moving about through the directories in a script (this can cause issue if you loose the position the script is being run from).

```{sh}
################################################################################

# 3. QC after trimming
conde activate fastqc

mkdir -p  ${WD}/trimmomatic/fastqc; cd ${WD}/trimmomatic/fastqc

fastqc -o ${WD}/trimmomatic/fastqc ${WD}/trimmomatic/*.fastq.gz
multiqc ${WD}/trimmomatic/fastqc -o 

################################################################################
```

#### 4. De novo assembly using SKESA

Same changes as previous edits. Pretty minor.

```{sh}
################################################################################

# 4. De novo assembly using SKESA
conda activate SKESA

mkdir skesa

for FILE in ${WD}/trimmomatic/*_R1_001_paired.fastq.gz ; do
    ID=$(basename "${FILE}" _R1_001_paired.fastq.gz)
    echo "running skesa assembly on ${ID}"
    skesa --fastq "trimmomatic/${ID}_R1_001_paired.fastq.gz","trimmomatic/${ID}_R2_001_paired.fastq.gz" --contigs_out "skesa/${ID}.skesa.fa"
    echo -e "skesa assembly on ${ID} finished"
done

conda deactivate

################################################################################
```

#### 5. Annotate genomes with prokka

```{sh}
################################################################################

# 5. Annotate genomes with prokka
conda activate prokka

mkdir prokka_annotations
for FILE in ${WD}/trimmomatic/*_R1_001_paired.fastq.gz ; do
    ID=$(basename "${FILE}" _R1_001.fastq.gz)
    echo "running prokka on skesa/${ID}.skesa.fa"
    prokka --outdir "prokka_annotations/$id" --prefix "$ID" "skesa/${ID}.skesa.fa"
    echo -e "prokka on ${ID}.skesa.fa finished"
done

conda deactivate

################################################################################
```

#### 6. Alingment of core genomes using Roary

This is fine too. Just clearer paths to reduce wildcard.

```{sh}
################################################################################

conda activate roary

mkdir roary
roary -e --mafft -p 8 ${WD}/prokka_annotations/*/*.gff

conda deactivate

################################################################################
```

#### 7. Calculate SNP distances for clustering

It is not clear where <core>core_gene_alignment.aln</core> is coming from, just make sure that it is the output of something previously.

```{sh}
################################################################################

# 7. Calculate SNP distances for clustering
conda activate snp-dists

snp-dists core_gene_alignment.aln > ERV_distances.tab

conda deactivate

################################################################################
```