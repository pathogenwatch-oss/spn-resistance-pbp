# PBP resistance predictor for S. pneumoniae

## About

### Purpose

This software is for the inference of beta-lactam resistance phenotype from the PBP genotype of Streptococcus
pneumoniae.

### History

This software is a modified version of [Ben Metcalfe's AMR predictor](https://github.com/BenJamesMetcalf/Spn_Scripts_Reference) designed for running within a Docker container, and as part of
[Pathogenwatch](https://pathogen.watch/). Please credit the original authors in any resulting publication.

## Warning

We do not provide any support for the use or interpretation of this software, and it is provided on an "as-is" basis.

## Running the software

### Requirements

- [Docker](https://www.docker.com/)

### Building the Docker image

In the root directory of the repository run the following command:

```
docker build --rm -t spn_pbp_amr .
```

### Running the image

The software reads a FASTA file from STDIN and prints a JSON-formatted result to STDOUT.

```
cat [path/to/genome.fa] | docker run --rm -i spn_pbp_amr > result.json
```