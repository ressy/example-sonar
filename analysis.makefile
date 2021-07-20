# Run in sonar environment with sonar script on path, inside of a single
# timepoint's analysis directory

REFERENCE = ../SONAR/sample_data/CAP256-VRC26.01-12H.fa
WD := $(shell echo "$$(basename $$(pwd))")
TIMEPOINT := $(subst analysis-WK,,$(WD))
SRR := $(shell cat ../samples.csv | grep ^$(TIMEPOINT) | cut -f 2 -d ,)
INPUT := $(SRR).fastq

THREADS = 8

%.fastq:
	mkdir -p $(dir $@)
	cd $(dir $@) && fastq-dump $(subst .fastq,,$(notdir $@))

all: output/sequences/nucleotide/$(WD)_islandSeqs.fa

### Module 1: Annotation

# 1.0: merge reads (skipped in this example)

# 1.1: Blast V
# This defaults to using the databases built into SONAR/germDB/.
M_1_1 = work/annotate/vgene/$(WD)_001.fasta
m_1_1: $(M_1_1)
$(M_1_1): $(INPUT)
	sonar blast_V --fasta $^ --locus H --derep --threads $(THREADS)
	find work > work_m_1_1.txt
	find output > output_m_1_1.txt

# 1.2: BLast J
M_1_2 = work/annotate/jgene/$(WD)_001.fasta
m_1_2: $(M_1_2)
$(M_1_2): $(M_1_1)
	sonar blast_J --threads $(THREADS)
	find work > work_m_1_2.txt
	find output > output_m_1_2.txt

# 1.3: Finalize Assignments - use V and J to find CDR3.
# By default this script removes the output from the previous V and J steps,
# but I'll keep them for this example.
M_1_3 = output/sequences/nucleotide/$(WD)_goodVJ.fa
m_1_3: $(M_1_3)
$(M_1_3): $(M_1_2)
	sonar finalize --noclean --threads $(THREADS)
	find work > work_m_1_3.txt
	find output > output_m_1_3.txt

# 1.4: Dereplication and Clustering
M_1_4 = output/sequences/nucleotide/$(WD)_goodVJ_unique.fa
m_1_4: $(M_1_4)
$(M_1_4): $(M_1_3)
	sonar cluster_sequences --id .97 --min2 2
	find work > work_m_1_4.txt
	find output > output_m_1_4.txt

m_1: $(M_1_4)

### Module 2: Lineage Determination

# 2.1: Identity Divergence
# Here we compare with known antibodies of interest (in this case in this
# sample FASTA file)
M_2_1 = output/tables/$(WD)_goodVJ_unique_id-div.tab 
m_2_1: $(M_2_1)
$(M_2_1): $(M_1_4)
	sonar id-div -a $(REFERENCE) -t $(THREADS)
	find work > work_m_2_1.txt
	find output > output_m_2_1.txt

# 2.2: Selection of island for lineage of interest
# Interactive plot; requires X11.
# Processing will stop here and until the plot is manually drawn on to select a
# region of interest.  runVignette.sh has a fallback to use readymade
# _islandSeqs.fa files to cover this and the getfasta rules.
M_2_2 = output/tables/islandSeqs.txt
m_2_2: $(M_2_2)
$(M_2_2): $(M_2_1)
	sonar get_island $^ --mab CAP256-VRC26.01 --mab CAP256-VRC26.08 --output $(subst .txt,,$(notdir $@))

# 2.3: Intradonor Analysis
# Iterative method to find sequences related to given antibodies.
M_2_3 = work/lineage/NJ00001.aln
m_2_3: $(M_2_3)
$(M_2_3): $(M_1_4)
	sonar intradonor --n $(REFERENCE) --v IGHV3-30*18 --threads $(THREADS)
	find work > work_m_2_3.txt
	find output > output_m_2_3.txt

# 2.4: Cluster into Groups
# Group sequences in pseudo-lineages by CDR3
M_2_4 = output/tables/$(WD)_lineages.txt
m_2_4: $(M_2_4)
$(M_2_4): $(M_1_4)
	sonar groups -v 'IGHV3-30*18' -j 'IGHJ3*01' -t $(THREADS)
	find work > work_m_2_4.txt
	find output > output_m_2_4.txt

# 3.1: Get FASTA in preparation for longitudinal analysis
# In the older SONAR described by the vignette, "sonar getfasta" is specific
# enough, but there are more scripts now so we need to be more specific for the
# automatic name matching to work.
M_3_1 = output/sequences/nucleotide/$(WD)_islandSeqs.fa
m_3_1: $(M_3_1)
$(M_3_1): $(M_2_2) $(M_1_4)
	sonar getfastafromlist -l $(word 1,$^) -f $(word 2,$^) -o $@

clean:
	rm -f derepAllRawSeqs.uc
	rm -rf work/
	rm -rf output/
