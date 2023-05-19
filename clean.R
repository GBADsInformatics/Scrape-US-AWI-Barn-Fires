library(tidyverse)
library(dplyr)

## This script is both an exploration and overall cleaning of AWI barn fires data.

df <- read_csv('/Users/kassyraymond/PhD/trunk/20230414-AWI-Scraping/AWI_barnfires.csv')

# Fix up some of the names
df <- df %>% 
  mutate(species = replace(species, species == 'Animals (species unspecified)', 'Animals (species not specified)')) %>% 
  mutate(species = replace(species, species == 'Calf', 'Calves')) %>% 
  mutate(species = replace(species, species == 'Cow', 'Cows')) %>% 
  mutate(species = replace(species, species == 'Horse', 'Horses')) %>% 
  mutate(species = replace(species, species == 'Muliple species: ducks, geese and chickens', 'Multiple species: ducks, geese and chickens')) %>% 
  mutate(species = replace(species, species == 'Chickens, geese and ducks', 'Multiple species: ducks, geese and chickens'))

# Get all unique species 
unique_vals <- df %>% 
  distinct(., species)

nrow(unique_vals)
# There are 89 unique vals

print(unique_vals, n = 89)

# Have to deal with multiple species, create 2 dfs 
df_species <- df %>% 
  dplyr::filter(., !grepl('Multiple species', species))

df_mspecies <- df %>% 
  dplyr::filter(., grepl('Multiple species', species))

# Remove all non-ag species 
# Animals (species not specified), Dogs, species, Puppies
remove = c('Animals (species not specified)', 'Dogs', 'Puppies', 'species')
df_species <- df_species[!df_species$species %in% remove, ]

# Now with multiple species 
print(distinct(df_mspecies, species), n = 70)

# Separate multiple species based on whether there are numbers in the row or not 

# Check that at least one character in the species field is numerical
df_mspecies_num <- dplyr::filter(df_mspecies, grepl('[[:digit:]]', species))

# Replace ', and' with just a comma then 'and' with a comma then remove multiple species 
df_mspecies_num <- df_mspecies_num %>% 
  mutate(species = str_replace_all(species, ', and', ',')) %>% 
  mutate(species = str_replace_all(species, 'and', ',')) %>% 
  mutate(species = str_replace_all(species, 'Multiple species: ', '')) %>% 
  mutate(species = str_replace_all(species, ' a ', '1 '))
  

# Replace commas with and so then we can slice the string on the and, and then create new rows from this 
df_mspecies_num <- df_mspecies_num %>% 
  mutate(species = strsplit(as.character(species), ",")) %>% 
  unnest(species) %>% 
  mutate(species_deaths = readr::parse_number(as.character(species))) %>% 
  mutate(species = str_replace_all(species, '[[:digit:]]', '')) %>% 
  mutate_if(is.character, str_trim)

# Remove trailing spaces species col
df_mspecies_num  %>%
  mutate_if(is.character, str_trim)

# Drop dogs, cats, peacocks, puppies, guinea pigs, blanks 
remove <- c('dog', 'peacock', 'several cats', 'guinea pigs', 'puppies', 'other animals')
df_mspecies_num <- df_mspecies_num[!df_mspecies_num$species %in% remove, ]
print(df_mspecies_num[is.na(df_mspecies_num$species_deaths),], n=23)


## Remove any non-ag species 
## Replace multiples that are a mix and have no numbers with Unknown.
## Questions for Will 
# Removals ok? 
# Multiple species - sep by if there is a number, seperate rows - if no numbers given then what?? Which rows are OK to drop and which should be kept even if they don't report #s 
# Date column - just year? Do we want to aggregate everything once it is clean? 
# How often do barn fires happen and how often 