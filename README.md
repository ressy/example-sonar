# SONAR Example

Following along with the [paper] and [vignette] for [SONAR].

First, a very rough setup script to automate a few setup steps.  This creates a
sonar conda environment.

    bash setup.sh

And then:

    conda activate sonar
    export PATH="$(readlink -f SONAR):$PATH"
    make

## Outline

Some brief notes on how the modules and commands are organized.

 1. Annotation
   1. Blast V (`blast_V`)
   2. Blast J (`blast_J`)
   3. Finalize Assignments (`finalize`)
   4. Dereplication and Clustering (`cluster_sequences`)
 2. Lineage Determination
   1. Identitiy Divergence (`id-div`)
   2. Selection of island for lineage of interest (`get_island`)
   3. Iterative search for sequences related to antibodies of interest (`intradonor`)
   4. Group sequences in pseudo-lineages by CDR3 (`groups`)
 3. Phylogenetic Analysis
   1. Merge timepoints from separate analyses (`getfasta`, `merge_time`)
   2. Build ML Tree (`igphyml`)

[paper]: https://doi.org/10.3389/fimmu.2016.00372
[vignette]: https://github.com/scharch/SONAR/blob/master/vignette.pdf
[SONAR]: https://github.com/scharch/SONAR
