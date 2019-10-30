library(tidyverse)

its_df = read_delim('data/all_hits.csv', delim='\t')

results = its_df %>%
  group_by(stitle) %>%
  summarise(n()) %>%
  write_csv('results/report.csv')
