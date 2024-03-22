## code to prepare `gaoch_photo` dataset goes here
dir = "/Volumes/Data/Projects/06-leaf-analysis/data-raw/"
gaoch_photo = md5sum(dir)
usethis::use_data(gaoch_photo, internal = TRUE, overwrite = TRUE)
