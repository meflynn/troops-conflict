# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tidyverse)
library(tarchetypes) # Load other packages as needed. # nolint


# Bayes options
# Suppress brms startup messages
suppressPackageStartupMessages(library(brms))

# Set options for brms and stan
options(mc.cores = 4,
        mc.threads = 2,
        brms.backend = "cmdstanr")

set.seed(66502)

# Things that get set in options() are not passed down to workers in future (see
# https://github.com/HenrikBengtsson/future/issues/134), which means all these
# neat options we set here disappear when running tar_make_future() (like
# ordered treatment contrasts and the number of cores used, etc.). The official
# recommendation is to add options() calls to the individual workers.
#
# We do this by including options() in the functions where we define model
# priors and other settings (i.e. pts_settings()). But setting options there
# inside a bunch of files can get tedious, since the number of cores, workers,
# etc. depends on the computer we run this on (i.e. my 4-core personal laptop
# vs. my 16-core work laptop).

# Pass these options to workers using options(worker_options)
worker_options <- options()[c("mc.cores", "mc.threads", "brms.backend")]

# Install custom theme
devtools::install_github("meflynn/flynnprojects")


# Set target options:
tar_option_set(
  packages = c("tidyverse", "data.table", "brms", "sf", "raster", "tidybayes",
               "geodata", "modelsummary", "rnaturalearth", "flynnprojects",
               "viridis", "tibble", "glue", "purrr", "furrr"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)

# brms settings
CHAINS <- 4
CORES <- 4
ITERS <- 4000
WARMUP <- 2000
THIN <- 1

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Load the R scripts with your custom functions:
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)
# source("other_functions.R") # Source other scripts as needed. # nolint

# Set projection CRS codes and grid size for maps
projcrs <- "EPSG:4326" # Set CRS


# Enable custom fonts
sysfonts::font_add_google("Oswald")
showtext::showtext_auto()
base_size <- 16
base_family <- "Oswald"

# # Replace the target list below with your own:
# # You can use tar_load() to load an object from the pipeline to inspect it manually!
list(

  # Load raw data files
  tar_target(vdem_raw, "data/raw-data/Country_Year_V-Dem_Core_CSV_v12/V-Dem-CY-Core-v12.csv", format  = "file"),
  tar_target(nmc_raw, "data/raw-data/NMC_5_0.csv"),
  tar_target(mid_raw, "data/raw-data/MID-5-Data-and-Supporting-Materials/MIDB 5.0.csv"),
  tar_target(ally_raw, "data/raw-data/ATOP 5.1 (.csv)/atop5_1ddyr.csv"),

  # Run cleaning functions to generate clean data frames
  tar_target(vdem_clean, clean_vdem_f(vdem_raw)),
  tar_target(nmc_clean, clean_nmc_f(nmc_raw)),
  tar_target(gdp_clean, clean_gdp_f()),
  tar_target(mid_clean, clean_mid_f(mid_raw)),
  tar_target(troopdata_clean, clean_troopdata_f()),
  tar_target(allydata_clean, clean_allydata_f(ally_raw)),
  tar_target(usally_clean, clean_us_ally_f(ally_raw)),
  tar_target(mindist_clean, clean_mindist_f()),
  tar_target(spatial_troops_clean, clean_spatial_troops_f(mindist_clean, troopdata_clean)),
  tar_target(spatial_ally_clean, clean_spatial_ally_f(mindist_clean, allydata_clean)),
  tar_target(spatial_us_ally_clean, clean_us_spatial_ally_f(mindist_clean, usally_clean)),

  # Combine into final dataset
  tar_target(analysis_data, combine_data_f(vdem_clean, nmc_clean, gdp_clean, mid_clean, troopdata_clean, usally_clean,
                                           spatial_troops_clean, spatial_ally_clean, spatial_us_ally_clean)),

  # Analysis
  #
  # Figures
  tar_target(figure_out, descriptive_plots_f(analysis_data)),

  # Models
  #
  tar_target(model_troops_mids_1, models_base_f(analysis_data)),
  tar_target(model_troops_mids_2, models_interaction_f(analysis_data))

)


