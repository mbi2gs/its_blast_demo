
build-sra: Dockerfile.sra_toolkit
	docker build -t mbiggs/sra_toolkit . -f Dockerfile.sra_toolkit && \
	touch $@
	
SRR3003942_2.fastq: build-sra
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003942 && \
	mv SRR3003942* data/

SRR3003943_2.fastq: SRR3003942_2.fastq
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003943 && \
	mv SRR3003943* data/
	
build-blast: Dockerfile.blast
	docker build -t mbiggs/blast . -f Dockerfile.blast && \
	touch $@
	
data/fungi.ITS.fna: build-blast
	curl ftp://ftp.ncbi.nlm.nih.gov/refseq/TargetedLoci/Fungi/fungi.ITS.fna.gz -o data/fungi.ITS.fna.gz && \
	gunzip -f data/fungi.ITS.fna.gz

data/fungi.ITS.nhr:	data/fungi.ITS.fna
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/blast \
	  makeblastdb -in data/fungi.ITS.fna -parse_seqids -dbtype nucl -out data/fungi.ITS
	  
