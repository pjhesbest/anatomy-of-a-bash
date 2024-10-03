<!-- TOC -->

- [Introduction](#introduction)
- [Anatomy of a BASH script](#anatomy-of-a-bash-script)
    - [Defining arguments](#defining-arguments)
    - [Defining default variables](#defining-default-variables)
    - [Generating logs-files](#generating-logs-files)
    - [Informative error messages](#informative-error-messages)
    - [Making pretty script](#making-pretty-script)
- [Anatomy of a R script](#anatomy-of-a-r-script)
    - [Defining arguments](#defining-arguments)
    - [Defining default variables](#defining-default-variables)
- [Anatomy of a Python script](#anatomy-of-a-python-script)
    - [Defining arguments](#defining-arguments)
    - [Defining default variables](#defining-default-variables)
    - [Generating logs-files](#generating-logs-files)

<!-- /TOC -->

## Introduction
For a long time my bioinformatic analyses were very slow, as all my scripts were build specifically for a partiuclar sample. Paths were specific to a certain data/directories, definted variables were specific to the server I was using at the time, ect. This a completely acceptable way to process to opperate, but once you scale up and require routine analyses to be occuring is no longer helpful.

Bear in mind, that BASH is not always the best language to do this with (python is a good alternative) are all excellent alternatives, but if all you know is a little BASH and havent had the time to learn Python. 

Sometime you want to write a script that can be run with an input and output flag, such as the example below.

```{sh}
# BASH example
assembly.sh -i ${SAMPLEID}_R1-fastq.gz -r ${SAMPLEID}_R1-fastq.gz -o ${SAMPLEID}

# R example
Rscript assembly-stats.R -i ${SAMPLEID}.assembly-stats.txt -o ${SAMPLEID}.assembly-summary.csv

# Python example
python assembly-plotting.py -i ${SAMPLEID}.assembly-summary.csv -o ${SAMPLEID}.plot.png
```

Achieving this is suprisingly simple, this will be covered bit by bit.
***
## Anatomy of a BASH script

### Defining arguments

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


### Making a pretty script!
In the long matrix stream of text that your can be printed to you console, it is often useful to have important text stand out. This could be a missing file, non-exixtent path, location of output file. 

Adding color to you script can be definted very early. First you must indicate the color of the text needs to change using: <code>\033[</code>. This open up all subsequent text to a color change, BUT no color has been defined yet. To define a color your must add the approporiate ANSI escape codes (Table 1). For red text you would define it as: <code>\033[31m</code>. All text that follows this will be green. To revert the color back to default (typically white in a console), you need to close the escape code with a <code>\033[m</code>.

<small>**Table 1.** ANSI color codes and their corresponding colors.</small>

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
echo -e "\033[31m ERROR: something has gone very wrong because the text is red!\033[m"
```

This is quite a awkward to add and you can very easily miss a closure, and the the entirely of your console is colored red and you'll feel like you have made a terrible bloody mistake. A work around is to define the color at the start of your script:

```{sh}
green='\033[32m'; red='\033[31m'; cyan='\033[36m'; purple='\033[35m'; nocolor='\033[m'
```

This alows you to change the text color as follows:
```{sh}
echo -e "${red}ERROR: something has gone very wrong because the text is red!${nocolor}"
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