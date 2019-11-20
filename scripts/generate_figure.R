library(tidyverse)

genus_df = read_delim('results/summary_genus_counts.tsv', delim='\t')

ggplot(genus_df, aes(x=reorder(genus, -`0`), y=`0`)) +
	geom_bar(stat='identity', aes(fill=genus)) +
	coord_polar() +
	scale_y_log10() +
	theme_minimal() +
	theme(axis.title=element_blank(),
	      axis.ticks = element_blank(),
		  axis.text.y = element_blank())
	
ggsave('results/genus_counts.png')