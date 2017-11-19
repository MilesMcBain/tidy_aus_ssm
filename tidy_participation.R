library(tidyverse)
library(readxl)
library(readr)
library(rvest)

file_name = "australian_marriage_law_postal_survey_2017_-_participation_final.xls"

extract_participation_counts <- function(file_name, table_name, table_gender){
  
areas <- 
  read_excel(
      path = file_name,
      range = paste0(table_name,"!A8:A650"),
      col_names = "area") %>%
  filter(!grepl("Division|Australia$", area)) %>%
  mutate(area = gsub("\\([a-z]\\)","",area)) %>%
  drop_na()

age_counts <- readxl::read_excel(
  path = file_name,
  range = paste0(table_name,"!B8:R650"),
  col_names = c("measure",
                "18-19 years",
                "20-24 years",
                "25-29 years",
                "30-34 years",
                "35-39 years",
                "40-44 years",
                "45-49 years",
                "50-54 years",
                "55-59 years",
                "60-64 years",
                "65-69 years",
                "70-74 years",
                "75-79 years",
                "80-84 years",
                "85 years and over",
                "Total for Gender")) %>%
  tidyr::drop_na() %>%
  mutate(area = rep(areas$area, each=3), gender=table_gender) %>%
  filter(!grepl("Total", area)) %>%
  gather(key = "age", value = "count", -measure, -area, -gender)
}

params <-
  list(
    table_name = c("Table 5", "Table 6"),
    table_gender = c("Male", "Female")
)

ssm_participation <-
  pmap(.l = params, 
     .f = extract_participation_counts,
     file_name = file_name) %>%
  bind_rows() 


# Fetch the current electorates to append to table
current_electorates <- 
  read_html("http://www.aec.gov.au/profiles/") %>%
  rvest::html_nodes("table") %>%
  rvest::html_table() %>%
  first() %>%
  select(`Electoral division`, State, `Area (sq km)`)

ssm_participation_state <- 
  ssm_participation %>%
  left_join(current_electorates, by = c("area" = "Electoral division")) 

# Final spread of participation measures to columns and write to csv
ssm_participation_state %>%
  spread(measure, count) %>%
  mutate(
    `Eligible participants` = as.integer(`Eligible participants`),
    `Total Paticipants` = as.integer(`Total participants`)) %>%
  write_csv(path = "SSM_AUS_Participation.csv")

