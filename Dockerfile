FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update \
      && apt install -y -q apt-transport-https software-properties-common \
      && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
      && apt update \
      && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' \
      && apt install -y -q \
        curl \
        perl \
        r-base \
        gcc \
        build-essential \
        libx11-dev \
      && rm -rf /var/lib/apt/lists/*

# Install BLAST
RUN  mkdir -p /tmp/blast \
      && mkdir /opt/blast \
      && curl ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz \
      | tar -zxC /tmp/blast --strip-components=1 \
      && cd /tmp/blast/bin \
      && mv blastn makeblastdb blastp /opt/blast/ \
      && cd .. \
      && rm -rf /tmp/blast

ENV PATH /opt/blast:$PATH

# Install BEDTools
RUN curl -L -O -J https://github.com/arq5x/bedtools2/releases/download/v2.28.0/bedtools \
      && chmod +x bedtools \
      && mv bedtools /usr/local/bin/

# Install R dependencies
COPY install_r_dependencies.R /install_r_dependencies.R

RUN Rscript /install_r_dependencies.R \
      && rm -f /install_r_dependencies.R

# Install Clustal Omega
RUN curl -L -O -J http://www.clustal.org/omega/clustalo-1.2.4-Ubuntu-x86_64 \
       && mv clustalo-1.2.4-Ubuntu-x86_64 clustalo \
       && chmod +x clustalo \
       && mv clustalo /usr/local/bin/

# Install CPAN dependencies
RUN cpan App::cpanminus \
      && cpan JSON

# Copy in scripts & libs
RUN mkdir -p /predictor/SPN_Reference_DB

RUN mkdir -p /predictor/bLactam_MIC_Rscripts

COPY SPN_Reference_DB/ /predictor/SPN_Reference_DB/

COPY bLactam_MIC_Rscripts /predictor/bLactam_MIC_Rscripts/

COPY ExtractGene.pl /predictor/

COPY PBP-Gene_Typer.pl /predictor/

COPY pw_wrapper.sh /predictor/

COPY to_json.pl /predictor/

COPY transeq.pl /predictor/

COPY entrypoint.sh /predictor/

RUN cd /predictor \
      && chmod +x *.sh \
      && chmod +x *.pl

ENV PATH /predictor:$PATH

WORKDIR /predictor/

#ENTRYPOINT ["/bin/bash"]
ENTRYPOINT ["/predictor/entrypoint.sh"]
