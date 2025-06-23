#!/usr/bin/env bash

set -eo pipefail

customtaxnames="${1}"
[ -z "${verbose}" ] && verbose=false

readarray -t species_array < <(tail -q -n +2 *.tsv | awk -F '\t' '{print $1}' | sort -u)

for file in *.tsv; do
  unset lookup
  declare -A lookup
  while IFS=$'\t' read species filtered_reads; do
    lookup["$species"]=$filtered_reads
  done < <(tail +2 $file | awk -F $'\t' -v OFS=$'\t' '{print $1,$(NF-4)}')
  # For every elem in the species array, lookup the correponding number of filtered reads (empty if no species present)
  echo ${file%_genome_info.tsv} > ${file}_species_lookup.tmp
  for species in "${species_array[@]}"; do
    reads=${lookup["$species"]}
    if [ -z "$reads" ]; then reads=0; fi
    echo $reads
  done >> ${file}_species_lookup.tmp
done

cat <(echo) <(printf '%s\n' "${species_array[@]}") > row_labels.tmp
paste row_labels.tmp *_species_lookup.tmp > instrain_summary.tsv

# convert names from a custom dictionary (if it has been provided)
if [ -n "${customtaxnames}" ] ; then
  echo "" > row_labels_custom.tmp
  declare -A customtaxa_array
  [ "${verbose}" == true ] && echo "building conversion table:"
  while IFS=$'\t' read taxonin taxonout; do
    [ "${verbose}" == true ] && echo "$taxonin -> $taxonout"
    customtaxa_array["$taxonin"]=$taxonout
  done < ${customtaxnames}
  tail -n+2 row_labels.tmp | while read taxonin ; do
    [ "${verbose}" == true ] && echo "try and replace '${taxonin}' name..." 1>&2
    trtaxon=${customtaxa_array["$taxonin"]} || echo "'${taxonin}' is not present in the dataset; skip." 1>&2
    if [ -z "${trtaxon}" ] ; then
      echo ${taxonin}
    else
      echo ${trtaxon}
    fi
  done >> row_labels_custom.tmp
  paste row_labels_custom.tmp *_species_lookup.tmp > instrain_summary_tidynames.tsv
else
  cp instrain_summary.tsv instrain_summary_tidynames.tsv
fi
# sanitise the names by removing redundant substrings
for redundanttag in ', complete genome' ', complete sequence' ' genomic sequence' ', complete cds' ; do
  sed -i "s|$redundanttag||g" instrain_summary_tidynames.tsv
done
# clean up
rm *.tmp