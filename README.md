# Anatomy of a BASH (WIP)
Level: Advanced beginner-Intermediate | 2024-10-03

CAUTION ITS VERY MESSY HERE

***
## Table of Contents

***

## Introduction
For a long time my bioinformatic analyses were very slow, as all my scripts were build specifically for a partiuclar sample or groups of samples. This is likely a consequence of the way most bioinfomatics courses and tutorials are taught, which is to have a single sample going through a process at one time. Once the quanntity of data I was processing at any single timepoint began to scale up, I was over-relying on loops to go parse through all my samples at each step. 

Paths were specific to a certain data/directories, defined variables were specific to the server I was using at the time, ect. This can all fall apart when you move institute and your scripts all feel messy or useless at your new job/serve/computer.

This a completely acceptable way to opperate, but once you scale up and require routine analyses to be occuring is no longer stres-free or reliable way to operate.

Bear in mind, that BASH is not always the best language for achieving this (python is a good alternative), but if all you know is a little BASH and havent had the time to learn Python, or another laguage, this guide is to help you start writing some simple and multi-sample functioning scripts. 

### Aims:

The main aim of this guide is to show you way in which you can write BASH, R and Python scripts that: 
1. Perform single/limited function(s) suitable for any appropriate data-type for that process
2. Using data located in any part of the computer/server
3. Producing outputs in a default or specified location/name
4. Has useful help messages
5. Produces usefull error mesages
6. Can be submited to any server type (e.g. SunCluter, SLURM).

***
## Anatomy of a BASH script

### Defining arguments

One way to achieve a multi-sample functioning script, very simply is to feed files into your script. The most basic way to do this in bash is to just add them to you line of code:

```{sh}
# write the script - assembly.sh
echo -e "#!/usr/bin/env bash
conda activate spades
spades.py -1 ${1} -2 ${2} -o ${3}
conda deactivate" > assembly.sh

# running the script
assembly.sh ${SAMPLE}_R1-fastq.gz ${SAMPLE}_R2-fastq.gz ${SAMPLE}_assembly-out
```

Your files are defined sequentially, so the first file following <code>assembly.sh</code> is \${1}, the second ${2}, so on. This is not the most usefriendly, if you are going to be sharing scripts for colleagues to use will be clunk for other to use. 

This is why its valuable to write script that have help mesages and defined flags that you can run as follows:

```{sh}
# BASH example
assembly.sh -i ${SAMPLEID}_R1-fastq.gz -r ${SAMPLEID}_R2-fastq.gz -o ${SAMPLEID}

# R example
Rscript assembly-stats.R -i ${SAMPLEID}.assembly-stats.txt -o ${SAMPLEID}.assembly-summary.csv

# Python example
python assembly-plotting.py -i ${SAMPLEID}.assembly-summary.csv -o ${SAMPLEID}.plot.png
```

First, we need to define the arguments for the script, and this is achieved using the <code>while getopts a\:b:c:h option; do</code>. Which looks worse than it actually is. This is utilising a <code>while</code> command to search for 

```{sh}
while getopts i:o:t:h option
do 
    case "${option}" in 
        i)input=${OPTARG};;
        o)output=${OPTARG};;
        t)threads=${OPTARG};;
        h)Help; exit;;
    esac
done
```



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


### Defining default variables

### Generating logs-files

### Informative error messages
When thinking about your error messages, you want to be sure that whatever you are calling is important. Too many programmes have error messages that dont actually impact the workflow of the script.

The easiest way to call an error message is to use an <code>if</code> statement, which is part of the <code>if</code>, <code>elif</code>, <code>else</code> statement  of commands that very helpful. These script basically ask

### Version control
An important thing to consider with your scripts, is always keep past versions of them, archiving

### Making a pretty script!
In the long matrix stream of text that your can be printed to you console, it is often useful to have important text stand out. This could be a missing file, non-exixtent path, location of output file. 

Adding color to you script can be definted very early. First you must indicate the color of the text needs to change using: <code>\033[</code>. This open up all subsequent text to a color change, BUT no color has been defined yet. To define a color your must add the approporiate ANSI escape codes (Table 1). For red text you would define it as: <code>\033[31m</code>. All text that follows this will be green. To revert the color back to default (typically white in a console), you need to close the escape code with a <code>\033[m</code>.

**Table 1.** ANSI color codes and their corresponding colors.

| code | color  |
|------|--------|
| 31m  | red    |
| 32m  | green  |
| 36m  | cyan   |
| 36m  | purple |
| 34m  | blue   |
| 33m  | orange |

A complete example might look something like this (if you are printing text to the console using the command <code>echo</code>, then you also have to add <code>-e</code> to enable interpretation of backslash escapes):

```{sh}
echo -e "\033[31m ERROR: something has gone very wrong because the text is all red!\033[m"
```

This is quite a awkward to add and you can very easily miss a closure, and the the entirely of your console is colored red and you'll feel like you have made a terrible bloody mistake. A work around is to define the colors as a variable at the start of your script:

```{sh}
# Define colors
green='\033[32m'; red='\033[31m'; cyan='\033[36m'; purple='\033[35m'; nocolor='\033[m'
```

This alows you to change the text color as follows:
```{sh}
echo -e "${red}ERROR: something has gone very wrong because the text is all red!${nocolor}"
```

### The final script and more complex examples
You can see an example of how this script broken down in the guide looks like all together at [bin/tb-profiler_v2.sh](URL). I have also added additional script to have a look through and get an idea of how else you can incorporate the features of bash to create increase the complexity/sofistication of the script.

#### Adding a timestamp to the end of your script
If your optimising your scripts and trying to get an idea of run-time and computing resources its useful to print out the run time. This is easily done by first creating a timestamp at the  start and the end of your script, the  calculating the elapsed time, then printing the time.

```{sh}
#!/usr/bin/env bash
start_time=$(date +%s) # define start time

#··············································#
#··········· The rest of the script ···········#
#··············································#

finish_time=$(date +%s) # define end time

# Calculate the difference in seconds
elapsed_time=$((finish_time - start_time))

# Convert elapsed time to hours, minutes, and seconds
((sec=elapsed_time%60, elapsed_time/=60, min=elapsed_time%60, hrs=elapsed_time/60))
timestamp=$(printf "Total time taken - %d hours, %d minutes, and %d seconds." $hrs $min $sec)
echo $timestamp

# Print the total runtime
echo -e ""
echo -e ""Total time taken: ${hrs}:${min}:${sec}"

```

If you are testing multing computing resource allocation and different processing time, you might even consider printing a running table of your experiment:

```{sh}
echo -e "script1;${THREADS};${NBOOTSTRAPS};${NUMSEQUENCES};${hrs}:${min}:${sec}" >> computing-time-test.csv
```

#### Not running the script if the output of the tool already exists:
In the example [bin/tb-profiler_v1.sh](URL) you can see that there is an example to search a collated output from previous runs of this scrip before deciing to run the script or not. It uses an <code>if</code> statement to determine wether that particular sampleID exists the output, and if it does not (i.e. ) to run the script. But if the output does exists (i.e. ), the it skips that particuler sample.

```{sh}

```

#### Forcing the script to run even if the output exists:
In a more sophisticated version of the script [bin/tb-profiler_v2.sh](URL) there is an additional flag to force the script to overright the previous output (i.e. ) using a flag of <code>-F</code>.

```{sh}

```

#### Adding a counter if processing multiple samples
If a single process is quick and not computationaly demanding, then loops are a good way to parse through lots of samples at once. I like to add a counter, so that I can keep track of where the script is at when I send it to a HPC.

To add a counter, you first must set the counter at one: <code>COUNTER=1</code>, then you will want to get the total number of samples to be processed: <code>TOTAL=$(ls ${DIRECTORY}/*R1.fastq.gz | wc -l)</code>. With those now defined you can start the loop. In this example the loop is utilising the path <code>${DIRECTORY}</code> and searching for files containing the suffix <code>\*_R1.fastq.gz</code>. This is done to capture the sample ID by using <code>basename</code> to remove the path and suffic of the R1 file.
```{}
COUNTER=0
TOTAL=$(ls ${DIRECTORY}/*R1.fastq.gz | wc -l); COUNTER=1
for file in ${DIRECTORY}/*R1.fastq.gz; do
···
```
With the loop open, we can calculate the remaining number of samples to process: <code>REMAINING=$((TOTAL - COUNTER))</code>. Its important to know that shell can only perform simple mathematics, so bear this in mind when using its calculator functions. Then an <code>echo -e</code> is used to report which sample number the loop is on, and how many are remaining: 

```{sh}
···
echo -e "   Sample: ${ID}  [${COUNTER}/${TOTAL}; ${REMAINING} remaining]
                R1: ${DIRECTORY}/${ID}_R1.fastq.gz
                R2: ${DIRECTORY}/${ID}_R2.fastq.gz"
···
```

In this example a tool called TB-Profiler is running on the R1 and R2 FASTQ files, utilising the <code>\${ID}</code> variable defined at the start of the loop for each sample. With the main function defined, we have to remember to increase the counter by 1, so that it increases with the loop to the next file: <code>COUNTER=$((COUNTER + 1))</code>. 

In all this might look something like this:

```{sh}
COUNTER=1 # start the counter
TOTAL=$(ls ${DIRECTORY}/*R1.fastq.gz | wc -l) # get the total

for file in ${DIRECTORY}/*R1.fastq.gz; do
    ID=$(basename "${file}" _R1.fastq.gz)
    
    REMAINING=$((TOTAL - COUNTER)) # Calculate remaining samples

    # Display sample information with the counter
    echo -e "   Sample: ${ID}  [${COUNTER}/${TOTAL}; ${REMAINING} remaining]
                R1: ${DIRECTORY}/${ID}_R1.fastq.gz
                R2: ${DIRECTORY}/${ID}_R2.fastq.gz"

    # Run the profiling command
    tb-profiler profile -1 ${DIRECTORY}/${ID}_R1.fastq.gz \
                        -2 ${DIRECTORY}/${ID}_R2.fastq.gz \
                        -t 4 -p ${ID} --txt
        
    COUNTER=$((COUNTER + 1)) # Increment the counter
done
```

You can even combine the loop with the <code>if</code> statement:

```{sh}
COUNTER=0 # start the counter at zero
for file in ${DIRECTORY}/*R1.fastq.gz; do
    ID=$(basename "${file}" _R1.fastq.gz)
    # Calculate remaining samples
    REMAINING=$((TOTAL - COUNTER))

    # If argument to check that the TB_profile hasnt already been run:
    if [[ ! -f ${TBPROF_DIR}/results/${ID}.results.txt ]]; then
        # Display sample information with the counter
        echo -e "${cyan}\tSample: ${ID}\t\t[$COUNTER/$TOTAL; $REMAINING remaining]\n\t\tR1: ${DIRECTORY}/${ID}_R1.fastq.gz\n\t\tR2: ${DIRECTORY}/${ID}_R2.fastq.gz"
        echo -e "${nocolor}"
        # Run the profiling command
        tb-profiler profile -1 ${DIRECTORY}/${ID}_R1.fastq.gz -2 ${DIRECTORY}/${ID}_R2.fastq.gz -t ${NTHREADS} -p ${ID} --txt
        # Increment the counter
        COUNTER=$((COUNTER + 1))
    elif [[ -f ${TBPROF_DIR}/results/${ID}.results.txt ]]; then
        echo -e "${red}\t${TBPROF_DIR}/results/${ID}.results.txt exists, skipping: ${ID}\t\t[$COUNTER/$TOTAL; $REMAINING remaining]"
        COUNTER=$((COUNTER + 1))
    fi
done
```

***
## Anatomy of a R script

### Defining arguments
Unlike this BASH, in R (and python), the help message can be created with defining arguments, making it more streamlined.

```{r}

```

### Defining default variables

```{r}

```

***
## Anatomy of a Python script

### Defining arguments

```{python}

```

### Defining default variables

```{python}

```

### Generating logs-files

```{python}

```
