# Run in sonar environment with sonar script on path

INPUT = SRR2126754.fastq
# TODO Split into separate working directories for each
TIMEPOINT_34 = SRR2126754
TIMEPOINT_48 = SRR1057705
TIMEPOINT_59 = SRR1057707
REFERENCE = SONAR/sample_data/CAP256-VRC26.01-12H.fa
THREADS = 8
WD := $(shell echo "$$(basename $$(pwd))")

SRR%.fastq:
	mkdir -p $(dir $@)
	cd $(dir $@) && fastq-dump $(subst .fastq,,$(notdir $@))

all: output/sequences/nucleotide/$(WD)_goodVJ_unique.fa

### Module 1: Annotation

# 1.0: merge reads (skipped)

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
M_2_1 = output/tables/$(WD)_goodVJ_unique_coverage.tab
m_2_1: $(M_2_1)
$(M_2_1): $(M_1_4)
	sonar id-div -a $(REFERENCE) -t $(THREADS)
	find work > work_m_2_1.txt
	find output > output_m_2_1.txt

# 2.2: Selection of island for lineage of interest
# Interactive plot; requires X11.
# sonar get_island output/tables/$(WD)_goodVJ_unique_id-div.tab --mab CAP256-VRC26.01 --mab CAP256-VRC26.08

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

### Module 3: Phylogenetic Analysis

# 3.1: Merge Timepoints
# sonar getfasta -l output/tables/islandSeqs.txt -f output/sequences/nucleotide/cap256-week34H_goodVJ_unique.fa -o output/sequences/nucleotide/cap256-week34H_islandSeqs.fa
# sonar merge_time --seqs ../cap256-week34H/output/sequences/nucleotide/cap256-week34H_islandSeqs.fa --labels w34 \
#   --seqs ../cap256-week48H/output/sequences/nucleotide/cap256-week48H_islandSeqs.fa\
#    --labels w48 --seqs ../cap256-week59H/output/sequences/nucleotide/cap256-week59H_islandSeqs.fa --labels w59

# 3.2: Build ML Tree
# sonar igphyml -i output/sequences/nucleotide/cap256-longitudinal-collected_aligned.fa -f

# The vignette ends there, but there are a few other longitudinal analyses in
# Module 3, and "Module 4: Figures and Output" beyond that.

clean:
	rm -f derepAllRawSeqs.uc
	rm -rf work/
	rm -rf output/
