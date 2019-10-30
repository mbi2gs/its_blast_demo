
build-sra: Dockerfile.sra_toolkit
	docker build -t mbiggs/sra_toolkit . -f Dockerfile.sra_toolkit && \
	touch $@
	
data/SRR3003942_2.fasta: build-sra
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003942 --fasta 60 && \
	mv SRR3003942* data/

data/SRR3003943_2.fasta: SRR3003942_2.fastq
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003943 --fasta 60 && \
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
	  
data/output:	data/fungi.ITS.fna
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/blast \
	  tblastn -db data/fungi.ITS \
		-query data/rhiA-G.faa \
		-out data/rhizoxin_tblastn_theia_howler.csv \
		-outfmt "6 qseqid sseqid pident length mismatch qcovs qstart qend sstart send evalue bitscore sseq" && \
	sed -i '1iqseqid	sseqid	pident	length	mismatch	qcovs	qstart	qend	sstart	send	evalue	bitscore	sseq' data/rhizoxin_tblastn_theia_howler.csv

	  
