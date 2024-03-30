  #!/bin/bash
#### Description: Identify ORFs in the Chinese hamster genome
####              Using ORF-RATER
####              1. Remove transcripts from Pseudogenes
####              data using Plastid              
####              2. convert GTF to genePred format 
####              3. Remove CGR chromomosome that causes error
####              4. Run ORF-RATER in docker
####              5. convert ORF-RATER bed to GTF  
#### Written by: NIBRT Clarke Lab. - colin.clarke@nibrt.ie

mkdir orf_identification && orf_dir=$_ 

gtf=reference_genome/GCF_003668045.3_CriGri-PICRH-1.0_genomic.gtf

# 1. remove pseudogenes 
grep '; pseudo'  $gtf | \
awk -F'\'t '{print $9}' | awk -F';' '{print $1}' | sed s/gene_id//g | \
sed s/\"//g | sed 's/[[:space:]]//g'| sort | uniq > $orf_dir/pseudogene_gene_ids.txt

echo "$(wc -l < $orf_dir/pseudogene_gene_ids.txt) pseduogenes removed"

grep -f $orf_dir/pseudogene_gene_ids.txt $gtf | \
awk -F'\'t '{print $9}' | awk -F';' '{print $2}' | sed s/transcript_id//g | \
sed s/\"//g | sed 's/[[:space:]]//g'| uniq > $orf_dir/pseudogene_transcript_ids.txt

echo "$(wc -l < $orf_dir/pseudogene_transcript_ids.txt) pseduogene transcripts removed"

# 2. convert NCBI gtf to genePred format 
gtfToGenePred \
-ignoreGroupsWithoutExons -allErrors $gtf stdout | \
genePredToBed stdin \
$orf_dir/cgr.orfrater.annotation.tmp.bed

# 3. remove the chromosome thats causes error 
grep -v NW_023277000.1  $orf_dir/cgr.orfrater.annotation.tmp.bed > \
$orf_dir/cgr.orfrater.annotation.tmp2.bed

# 4. remove miscRNAs that at protein coding gene loci
grep '^misc_RNA' reference_genome/GCF_003668045.3_CriGri-PICRH-1.0_feature_table.txt | \
awk -F'\'t '{print $11}' |  sort | uniq > $orf_dir/miscrna_transcript_ids.txt

grep -v -f $orf_dir/miscrna_transcript_ids.txt $orf_dir/cgr.orfrater.annotation.tmp2.bed > \
$orf_dir/cgr.orfrater.annotation.reference.bed

echo "$(wc -l < $orf_dir/miscrna_transcript_ids.txt) miscRNA transcripts removed"

# clean up
rm $orf_dir/cgr.orfrater.annotation.tmp*.bed
# rm $orf_dir/*.txt

# 5. run the ORF-RATER docker with the commands file
docker run --rm -v $PWD:/microprotein_analysis -t clarkelab/orfrater:final bash "/microprotein_analysis/scripts/orf_discovery/run_orfrater.sh"

# 6. convert orfrater BED to GTF
/mnt/HDD2/colin/bin/kentUtils/bin/linux.x86_64/bedToGenePred \
orf_identification/orfraterorfrater_predictions.reference.bed stdout | \
/mnt/HDD2/colin/bin/kentUtils/bin/linux.x86_64/genePredToGtf file stdin \
orf_identification/orfrater/orfrater_predictions.reference.gtf


# write the metagenes for each riboseq type to results

# mkdir results/metagene_profiles
# cp orfrater_analysis/chx/metagene.txt results/metagene_profiles/chx.metagene.txt
# cp orfrater_analysis/harr/metagene.txt results/metagene_profiles/harr.metagene.txt
# cp orfrater_analysis/nd/metagene.txt results/metagene_profiles/nd.metagene.txt