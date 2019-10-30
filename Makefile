
build-sra: Dockerfile.sra_toolkit
	docker build -t mbiggs/sra_toolkit . -f Dockerfile.sra_toolkit && \
	touch $@
	
data/SRR3003942_2.fasta: build-sra
	mkdir -p data && \
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003942 --fasta 60 && \
	mv SRR3003942* data/

data/SRR3003943_2.fasta: data/SRR3003942_2.fasta
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003943 --fasta 60 && \
	mv SRR3003943* data/

data/all_samples_its_short.fasta: data/SRR3003942_2.fasta \
						    data/SRR3003943_2.fasta
	cat data/SRR300394*.fasta > data/all_samples_its.fasta && \
	head -500 data/all_samples_its.fasta > data/all_samples_its_short.fasta
	
build-blast: Dockerfile.blast
	docker build -t mbiggs/blast . -f Dockerfile.blast && \
	touch $@
	
data/fungi.ITS.fna: build-blast
	curl ftp://ftp.ncbi.nlm.nih.gov/refseq/TargetedLoci/Fungi/fungi.ITS.fna.gz -o data/fungi.ITS.fna.gz && \
	gunzip -f data/fungi.ITS.fna.gz

data/fungi.ITS.nhr:	data/fungi.ITS.fna
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/blast \
	  makeblastdb -in data/fungi.ITS.fna -parse_seqids -dbtype nucl -out data/fungi.ITS
	  
data/all_hits.csv: data/fungi.ITS.nhr \
			 data/all_samples_its_short.fasta
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/blast \
	  blastn -db data/fungi.ITS \
		-query data/all_samples_its_short.fasta \
		-out data/all_hits.csv \
		-max_target_seqs 10 \
		-outfmt "6 qseqid sseqid pident length mismatch qcovs qstart qend sstart send evalue bitscore sseq" && \
	sed -i '1iqseqid	sseqid	pident	length	mismatch	qcovs	qstart	qend	sstart	send	evalue	bitscore	sseq' data/all_hits.csv

results/report.tsv: data/all_hits.csv \
					scripts/gen_report.R
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir rocker/tidyverse \
	  Rscript gen_report.R data/all_hits.csv scripts/report.tsv
	  
