
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
	mkdir -p data && \
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
		-outfmt "6 qseqid sseqid stitle pident length mismatch qcovs qstart qend sstart send evalue bitscore sseq" && \
	sed -i '1iqseqid	sseqid	stitle	pident	length	mismatch	qcovs	qstart	qend	sstart	send	evalue	bitscore	sseq' data/all_hits.csv

pull-pandas:
	docker pull amancevice/pandas:0.25.2-slim && touch $@


results/summary_genus_counts.tsv: pull-pandas \
								  data/all_hits.csv \
								  scripts/generate_report.py
	docker run -it \
		--rm -v $(shell pwd):/workdir \
		-w /workdir \
		amancevice/pandas:0.25.2-slim \
			python scripts/generate_report.py \
			data/all_hits.csv \
			results/summary

results/genus_counts.png: results/summary_genus_counts.tsv \
						  scripts/generate_figure.R
	docker run -it \
		--rm -v $(shell pwd):/workdir \
		-w /workdir \
		rocker/tidyverse \
			Rscript scripts/generate_figure.R

results/report.html: results/report.Rmd \
						         results/genus_counts.png 
	docker run -it --rm \
	-v $(shell pwd):/workdir \
	-w /workdir rocker/tidyverse \
	Rscript -e "library(rmarkdown); rmarkdown::render('results/report.Rmd', 'html_document')"
