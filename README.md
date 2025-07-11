# ancestryEstimation
Comparison of global ancestry estimation techniques for highly-admixed populations. Research conducted by Mark Lamin under the supervision of Saonli Basu, PhD. 

## How it works

The main file of interest is `harmonizationPipeline.sh`. This is a slurm script that allows the user to input their desired reference panel and study sample, and the script will then create a shiny app from a template that compares multiple ancestry estimation methods on the data. The script takes the following arguments:

1) `referencePanel` -- The reference panel. It is formatted as a prefix to a plink bfile triplet (i.e., `.bed`, `.bim`, `.fam`). It is assumed that the genome reference is GRCh38 and that typical quality control has already been done.
2) `studySample` -- The study sample. It is formatted as a prefix to a plink bfile triplet (i.e., `.bed`, `.bim`, `.fam`). It is assumed that the genome reference is GRCh38 and that typical quality control has already been done. Note that the SNP name formats do not need to be the same between the reference panel and the study sample as the pipeline will harmonize and rename the SNPs accordingly.
3) `returnDirectory` -- The directory where the outputs and shiny app will be stored. The pipeline will create the directory if it doesn't already exist.
4) `pathToRepo` -- The directory that contains the files from the github repository.
5) `popLabels` -- The population labels for the reference panel. This will be loaded into the shiny app as a dataframe. The first column, `SampleID`, is assumed to match the sample ids in the .fam file of the reference panel. The second column, `Region`, is the population to which the sample id belongs. Region is kept intentionally vague as these can be populations, superpopulations, or some other grouping of samples. The pipeline is flexible to support multiple filetypes, but it is recommended to use a comma-separated `.txt` or `.csv`.
6) `rfMixResults` -- (Optional) A file that contains aggregated local ancestry estimation results. Rather than having separate files for each chromosome, it is assumed that the user has aggregated the results from all the chromosomes together. If there are $n$ samples and $K$ populations, then there are $nK$ rows in the file. It contains 3 colums: `SampleID`, where the sample ids are assumed to be the same as the study sample's `.fam` file, `Region`, the population of interest, and `Probability`, the percentage of the sample's genome that belongs to that population. The population labels in this file need not be the same as in `popLabels`.

## Logic of Harmonization

## Acknowledgements