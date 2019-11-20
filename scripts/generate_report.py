import pandas as pd
import sys
import re

def parse_taxonomy(stitle, genus=False):
	'''
	Parse from the stitle values  
	genus/species classifications.
	'''
	pts = re.split(r'\sITS region', stitle)
	if genus:
		return re.sub(r'[\[\]]', '', pts[0].split()[0])
	else:
		return re.sub(r'[\[\]]', '', pts[0])

		
# Read file from the command line, 
# and keep only the best match
infile = sys.argv[1]
all_hits_df = (pd.read_csv(infile, sep='\t')
			   .sort_values(by=['bitscore'], ascending=[0])
			   .drop_duplicates(subset=['qseqid'])
			   )
		   
all_hits_df['binomial'] = all_hits_df['stitle'].apply(parse_taxonomy, args=(False,))
all_hits_df['genus'] = all_hits_df['stitle'].apply(parse_taxonomy, args=(True,))

# Write genus counts report to file
outfile_root = sys.argv[2]
(all_hits_df
 .groupby('genus')
 .size()
 .sort_values(ascending=False)
 .to_csv(outfile_root + '_genus_counts.tsv', sep='\t', header=True)
)

# Write species counts report to file
(all_hits_df
 .groupby('binomial')
 .size()
 .sort_values(ascending=False)
 .to_csv(outfile_root + '_species_counts.tsv', sep='\t', header=True)
)