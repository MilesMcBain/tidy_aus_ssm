library(readxl)
library(tidyverse)
library(rvest)

file_name = "australian_marriage_law_postal_survey_2017_-_response_final.xls"

response_counts <-
  readxl::read_excel(
    path = file_name,
    range = "Table 2!A8:P183",
    col_name = c( "area",
                  "Yes",
                  "Yes pct",
                  "No",
                  "No pct",
                  "Response Total",
                  "Response Total pct",
                  "blank",
                  "Response clear",
                  "Response clear pct",
                  "Response not clear(b)",
                  "Response not clear(b) pct",
                  "Non-responding",
                  "Non-responding pct",
                  "Eligible Total",
                  "Eligible Total pct")
  ) %>%
  select(-blank) %>%
  tidyr::drop_na() %>%
  mutate(area = gsub("\\([a-z]\\)","",area)) %>%
  filter(!grepl("Total", area))

# Append electoral data
# Fetch the current and old electorates to append to table
current_electorates <- 
  read_html("http://www.aec.gov.au/profiles/") %>%
  rvest::html_nodes("table") %>%
  rvest::html_table() %>%
  first() %>%
  select(`Electoral division`, State, `Area (sq km)`)

old_electorates <- 
  read_html("http://www.aec.gov.au/Electorates/abolished.htm") %>%
  rvest::html_nodes("table") %>%
  rvest::html_table() %>%
  first() %>%
  select(`Electoral division` = Division, State)

electorates <- bind_rows(current_electorates, old_electorates)
  

response_data <- 
  response_counts %>%
  left_join(electorates, by = c("area" = "Electoral division"))

write_csv(response_data, "SSM_AUS_Response.csv")

# Example State Summary
# response_data %>%
#  group_by(State) %>%
#  summarise(yes_count = sum(Yes), total_count = sum(`Response Total`) )


