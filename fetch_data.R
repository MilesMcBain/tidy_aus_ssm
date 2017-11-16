library(purrr)
library(curl)

data_files <- c(
  "australian_marriage_law_postal_survey_2017_-_participation_final.xls",
  "australian_marriage_law_postal_survey_2017_-_response_final.xls"
)
base_url <- 
  "https://marriagesurvey.abs.gov.au/results/files/"

walk(data_files, ~curl_download(url = paste0(base_url,.), destfile = .))
