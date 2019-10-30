
build-sra: Dockerfile.sra_toolkit
	docker build -t mbiggs/sra_toolkit . -f Dockerfile.sra_toolkit && \
	touch $@
	
SRR3003942_2.fastq:
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003942

SRR3003943_2.fastq:
	docker run -it --rm -v $(shell pwd):/workdir -w /workdir mbiggs/sra_toolkit \
	  fastq-dump --split-files SRR3003943
	
build-blast: Dockerfile.blast
	docker build -t mbiggs/blast . -f Dockerfile.blast && \
	touch $@