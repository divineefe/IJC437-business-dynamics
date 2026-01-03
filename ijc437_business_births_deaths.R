############################################################
# IJC437 Data Science Project
# Title: Business Birth and Death Dynamics and Labour Market Levels
# Author: Divine Eze
#
# Research question:
# How do business birth and death rates in Yorkshire compare with other
# English regions between 2018 and 2023, and to what extent are these
# dynamics associated with regional labour market (employment) levels?
############################################################

#########################
# 0. Load packages
#########################

# Uncomment this line the first time you run the script to install packages:
# install.packages(c("readxl", "dplyr", "tidyr", "ggplot2", "stringr"))

library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

#########################
# 1. File paths
#########################


birth_death_file <- "clean data vis data.xlsx"
labour_file      <- "nomis_2026_01_03_195544.xlsx"

# Safety checks: stop with a clear message if files are missing
if (!file.exists(birth_death_file)) {
  stop("Cannot find 'clean data vis data.xlsx'. Check getwd() and list.files().")
}

if (!file.exists(labour_file)) {
  stop("Cannot find 'nomis_2026_01_03_195544.xlsx'. Check getwd() and list.files().")
}

#########################
# 2. Business births and deaths (2018–2023)
#########################

# Inspect sheet names (expected: separate sheets for births and deaths)
all_sheets   <- excel_sheets(birth_death_file)
birth_sheets <- all_sheets[grepl("births",  all_sheets, ignore.case = TRUE)]
death_sheets <- all_sheets[grepl("deaths",  all_sheets, ignore.case = TRUE)]

# Helper function to read and clean a single births/deaths sheet
read_birth_death_sheet <- function(sheet_name, type_label) {
  # Read sheet
  df_raw <- read_excel(birth_death_file, sheet = sheet_name)
  
  # Force the first four columns to have standard names:
  # CODE = local area code, REGION = region name,
  # COUNT = number of births/deaths, YEAR = year
  if (ncol(df_raw) < 4) {
    stop(paste("Sheet", sheet_name, "has fewer than 4 columns. Check the file."))
  }
  names(df_raw)[1:4] <- c("CODE", "REGION", "COUNT", "YEAR")
  
  # Select required columns and standardise types
  df_clean <- df_raw %>%
    select(CODE, REGION, COUNT, YEAR) %>%
    mutate(
      type   = type_label,
      REGION = str_to_upper(as.character(REGION)),
      YEAR   = as.numeric(YEAR),
      COUNT  = as.numeric(COUNT)
    )
  
  return(df_clean)
}

# Read in all births and deaths sheets and stack them
births_all <- lapply(birth_sheets, read_birth_death_sheet, type_label = "birth") %>%
  bind_rows()

deaths_all <- lapply(death_sheets, read_birth_death_sheet, type_label = "death") %>%
  bind_rows()

# Combine births and deaths and restrict to 2018–2023
biz_all <- bind_rows(births_all, deaths_all) %>%
  filter(YEAR >= 2018, YEAR <= 2023)

# Aggregate to region-year level:
# Total births, total deaths, and net change (births - deaths) per region-year
biz_region_year <- biz_all %>%
  group_by(REGION, YEAR, type) %>%
  summarise(
    total_count = sum(COUNT, na.rm = TRUE),
    .groups     = "drop"
  ) %>%
  pivot_wider(
    names_from  = type,
    values_from = total_count,
    values_fill = 0
  ) %>%
  mutate(
    net_change = birth - death
  )

#########################
# 3. Labour market data (employment from Nomis)
#########################

# The Nomis file contains employment counts for selected English regions.
# The first 7 rows are metadata; row 8 contains the header row.
labour_raw <- read_excel(labour_file, sheet = "Data", skip = 7)

# Keep only the columns needed for this project:
# Date (year), North East, Yorkshire and The Humber, West Midlands
labour_clean <- labour_raw %>%
  select(
    YEAR                      = Date,
    `North East`,
    `Yorkshire and The Humber`,
    `West Midlands`
  ) %>%
  # Remove metadata row where YEAR is NA
  filter(!is.na(YEAR)) %>%
  # Convert YEAR to numeric and keep 2018–2023
  mutate(
    YEAR = as.numeric(YEAR)
  ) %>%
  filter(YEAR >= 2018, YEAR <= 2023) %>%
  # Convert counts to numeric
  mutate(
    `North East`               = as.numeric(`North East`),
    `Yorkshire and The Humber` = as.numeric(`Yorkshire and The Humber`),
    `West Midlands`            = as.numeric(`West Midlands`)
  )

# Reshape to a long format: one row per region-year
labour_long <- labour_clean %>%
  pivot_longer(
    cols      = -YEAR,
    names_to  = "region_name",
    values_to = "labour_level"    # employment count
  ) %>%
  mutate(
    REGION      = str_to_upper(region_name),
    labour_level = as.numeric(labour_level)
  )

#########################
# 4. Merge business dynamics with labour market data
#########################

data_merged <- biz_region_year %>%
  inner_join(labour_long, by = c("REGION", "YEAR")) %>%
  mutate(
    births_per_100k = (birth / labour_level) * 100000,
    deaths_per_100k = (death / labour_level) * 100000,
    net_per_100k    = births_per_100k - deaths_per_100k
  )

#########################
# 5. Focus on Yorkshire vs other English regions
#########################

yorkshire_name <- "YORKSHIRE AND THE HUMBER"

data_yorkshire_vs <- data_merged %>%
  filter(
    REGION %in% c(
      yorkshire_name,
      "NORTH EAST",
      "WEST MIDLANDS"
    )
  )

#########################
# 6. Descriptive summary tables
#########################

# Summary table of average rates per region (2018–2023)
summary_table <- data_yorkshire_vs %>%
  group_by(REGION) %>%
  summarise(
    mean_births_per_100k = mean(births_per_100k, na.rm = TRUE),
    mean_deaths_per_100k = mean(deaths_per_100k, na.rm = TRUE),
    mean_net_per_100k    = mean(net_per_100k,    na.rm = TRUE),
    .groups              = "drop"
  )

# Print summary table
print(summary_table)

#########################
# 7. Visualisation: trends over time
#########################

# Business birth rates over time
ggplot(data_yorkshire_vs,
       aes(x = YEAR, y = births_per_100k, colour = REGION, group = REGION)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title  = "Business birth rates per 100,000 employed (2018–2023)",
    x      = "Year",
    y      = "Births per 100,000 employed",
    colour = "Region"
  ) +
  theme_minimal()

# Business death rates over time
ggplot(data_yorkshire_vs,
       aes(x = YEAR, y = deaths_per_100k, colour = REGION, group = REGION)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(
    title  = "Business death rates per 100,000 employed (2018–2023)",
    x      = "Year",
    y      = "Deaths per 100,000 employed",
    colour = "Region"
  ) +
  theme_minimal()

# Net business change over time
ggplot(data_yorkshire_vs,
       aes(x = YEAR, y = net_per_100k, colour = REGION, group = REGION)) +
  geom_line(linewidth = 1) +
  geom_point() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title  = "Net business change per 100,000 employed (births - deaths)",
    x      = "Year",
    y      = "Net births per 100,000 employed",
    colour = "Region"
  ) +
  theme_minimal()

#########################
# 8. Association with labour levels
#########################

# Correlations between labour level and business dynamics by region
cor_results <- data_yorkshire_vs %>%
  group_by(REGION) %>%
  summarise(
    cor_births_labour = cor(births_per_100k, labour_level, use = "complete.obs"),
    cor_deaths_labour = cor(deaths_per_100k, labour_level, use = "complete.obs"),
    cor_net_labour    = cor(net_per_100k,    labour_level, use = "complete.obs"),
    .groups           = "drop"
  )

# Print correlation table
print(cor_results)

# Simple linear model for Yorkshire:
# net business rate ~ labour level
model_yorkshire <- lm(
  net_per_100k ~ labour_level,
  data = filter(data_yorkshire_vs, REGION == yorkshire_name)
)

# Print model summary
summary(model_yorkshire)
