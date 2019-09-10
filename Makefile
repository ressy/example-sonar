# Run in sonar environment with sonar script on path

SHELL = /bin/bash

TIMEPOINTS = WK34 WK48 WK59
THREADS = 8
WD := $(shell echo "$$(basename $$(pwd))")

ANALYSES = \
	analysis-WK34/output/sequences/nucleotide/analysis-WK34_islandSeqs.fa \
	analysis-WK48/output/sequences/nucleotide/analysis-WK48_islandSeqs.fa \
	analysis-WK59/output/sequences/nucleotide/analysis-WK59_islandSeqs.fa

ALL = analysis-longitudinal/m_3_2
all: $(ALL)

### Modules 1 and 2: Annotation and Lineage Determination
$(ANALYSES):
	mkdir -p $(subst _islandSeqs.fa,,$(notdir $@))
	cd $(subst _islandSeqs.fa,,$(notdir $@)) && make -f ../analysis.makefile

### Module 3: Phylogenetic Analysis
# 3.1: Merge Timepoints
analysis-longitudinal/output/sequences/nucleotide/analysis-longitudinal-collected.fa: $(ANALYSES)
	mkdir -p $(firstword $(subst /, ,$@))
	cd $(firstword $(subst /, ,$@)) && sonar merge_time \
		--seqs ../$(word 1,$^) --labels w34 \
		--seqs ../$(word 2,$^) --labels w48 \
		--seqs ../$(word 3,$^) --labels w59

# 3.2: Build ML Tree
analysis-longitudinal/m_3_2: analysis-longitudinal/output/sequences/nucleotide/analysis-longitudinal-collected.fa
	cd $(firstword $(subst /, ,$@)) && sonar igphyml -v 'IGHV3-30*18' --quick -f |& tee m_3_2.log

# The vignette ends there, but there are a few other longitudinal analyses in
# Module 3, and "Module 4: Figures and Output" beyond that.

### extras

runVignette_local.sh: SONAR/sample_data/runVignette.sh
	sed 's: /SONAR: ../SONAR:g' $^ > $@

vignette_results: runVignette_local.sh
	bash $^ |& tee $@.log
