FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

# Install Python & R
RUN apt-get update \
      && apt-get install -y -q --no-install-recommends \
        curl \
        perl \
        r-base \
        gcc \
        build-essential \
        libx11-dev \
        emboss \
      && rm -rf /var/lib/apt/lists/*

# Install BLAST
RUN mkdir /opt/blast \
      && curl ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.9.0/ncbi-blast-2.9.0+-x64-linux.tar.gz \
      | tar -zxC /opt/blast --strip-components=1

ENV PATH /opt/blast/bin:$PATH

## Install EMBOSS
#RUN mkdir /opt/emboss \
#      && curl ftp://emboss.open-bio.org/pub/EMBOSS/EMBOSS-6.6.0.tar.gz | tar -zxC /opt/emboss --strip-components=1 \
#      && cd /opt/emboss \
#      && ./configure \
#      && make

ENV PATH /opt/emboss/bin:$PATH

# Install BEDTools
RUN curl -L -O -J https://github.com/arq5x/bedtools2/releases/download/v2.28.0/bedtools \
      && chmod +x bedtools \
      && mv bedtools /usr/local/bin/

# Copy in scripts & libs
RUN mkdir -p /predictor/SPN_Reference_DB

RUN mkdir -p /predictor/bLactam_MIC_Rscripts

COPY SPN_Reference_DB/ /predictor/SPN_Reference_DB/

COPY bLactam_MIC_Rscripts /predictor/bLactam_MIC_Rscripts/

COPY ExtractGene.pl /predictor/

COPY PBP-Gene_Typer.pl /predictor/

COPY pw_wrapper.sh /predictor/

COPY entrypoint.sh /predictor/

RUN cd /predictor \
      && chmod +x *.sh \
      && chmod +x *.pl

WORKDIR /predictor/

ENTRYPOINT ["/predictor/entrypoint.sh"]
