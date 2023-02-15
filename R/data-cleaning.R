
# Note that we want to keep the German ccodes broken up until the very end.
# We can reunite 260 and 255 for the entire time period but don't do this
# until after the minimum distance measures have been created.

# Import and clean vdem data

clean_vdem_f <- function(filename) {

  vdem_clean_data <- data.table::fread(filename) |>
    dplyr::filter(year >= 1950) |>
    dplyr::select(year, country_name, v2x_polyarchy, v2x_libdem, COWcode) |>
    dplyr::rename(ccode = COWcode) |>
    dplyr::arrange(ccode, year)

  return(vdem_clean_data)

  }

# Import and clean COW NMC data

clean_nmc_f <- function(filename) {

  nmc_clean_data <- data.table::fread(filename) |>
    dplyr::filter(year >= 1950) |>
    dplyr::select(ccode, year, milex, milper, tpop, upop, cinc)

  return(nmc_clean_data)

}

# Read in SDGDP data from peacesciencer data. Original data are in weird format.

clean_gdp_f <- function() {

  gdp_clean <- peacesciencer::cow_sdp_gdp |>
    dplyr::filter(year >= 1950)

}


# Import and clean MID data

clean_mid_f <- function(filename) {

  mid_clean_data <- data.table::fread(filename) |>
    dplyr::rowwise() |>
    dplyr::mutate(year = list(seq(styear, endyear))) |>
    tidyr::unnest(year) |>
    dplyr::filter(year >= 1950) |>
    dplyr::group_by(ccode, year) |>
    dplyr::summarise(mids_total = dplyr::n_distinct(dispnum),
                     mids_1_total = dplyr::n_distinct(dispnum[.data$hostlev==1]),
                     mids_2_total = dplyr::n_distinct(dispnum[.data$hostlev==2]),
                     mids_3_total = dplyr::n_distinct(dispnum[.data$hostlev==3]),
                     mids_4_total = dplyr::n_distinct(dispnum[.data$hostlev==4]),
                     mids_5_total = dplyr::n_distinct(dispnum[.data$hostlev==5]),
                     mids_2_4_total = dplyr::n_distinct(dispnum[.data$hostlev>=2 & .data$hostlev <= 4]))

  return(mid_clean_data)

}

# Read in troopdata from troopdata package

clean_troopdata_f <- function(){

  troops_clean_data <- troopdata::get_troopdata(startyear = 1950, endyear = 2020) |>
    filter(ccode != 255 | troops != 0) |> # Delete redundant Germany observation/
    mutate(ccode2 = ccode)

  return(troops_clean_data)

}


# Import and clean ATOP alliance data
clean_allydata_f <- function(filename){

  allydata_clean <- fread(filename) |>
    dplyr::rename(ccode1 = stateA,
                  ccode2 = stateB) |>
    dplyr::select(ccode1, ccode2, year, defense) |>
    filter(year >= 1950)

  return(allydata_clean)

}


# Create data to identify US Allies
clean_us_ally_f <- function(filename){

  us_ally_clean <- fread(filename) |>
    dplyr::rename(ccode1 = stateA,
                  ccode2 = stateB) |>
    dplyr::select(ccode1, ccode2, year, defense) |>
    filter(year >= 1950) |>
    filter(ccode1 == 2) |>
    dplyr::rename(ccode = ccode2, us_ally = defense) |>
    dplyr::select(ccode, year, us_ally)

}


# Build spatial data with troops

clean_mindist_f <- function(){

  startdate <- as.Date("1950-01-01", format = "%Y-%m-%d")
  enddate <- as.Date("2016-01-01", format = "%Y-%m-%d")
  datelist <- data.frame(date = seq(startdate, enddate, by = "1 year"))

  thedate <- startdate

  mindist <- as.list(datelist$date)

  mindist <- lapply(mindist, function(x) {
    df <- cshapes::distlist(date = x, type = "mindist", keep = 0.1, useGW = FALSE) |>
      dplyr::mutate(year = x)
  }
  )

  mindist <- dplyr::bind_rows(mindist) |>
    dplyr::mutate(year = as.numeric(format(year, "%Y"))) |>
    filter(ccode1 != ccode2) |>
    mutate(mindist = ifelse(mindist == 0, 1, mindist))

  return(mindist)

}


# Function to create spatial measures of troop deployments
clean_spatial_troops_f <- function(distlist, troopdata) {

  spatial_troops_data <- distlist |>
    left_join(troopdata, by = c("ccode2", "year")) |>
    group_by(ccode1, year) |>
    dplyr::mutate(invdistance = 1/mindist,
                  troops_w = invdistance * troops) |>
    dplyr::summarise(troops_w_mean = mean(troops_w, na.rm = TRUE)) |>
    dplyr::rename(ccode = ccode1)

  return(spatial_troops_data)

}


# Create spatial alliance measure

clean_spatial_ally_f <- function(distlist, allydata) {

  spatial_ally_data <- distlist |>
    left_join(allydata, by = c("ccode1", "ccode2", "year")) |>
    group_by(ccode1, year) |>
    dplyr::mutate(defense = ifelse(is.na(defense), 0, defense),
                  invdistance = 1/mindist,
                  ally_w = invdistance * defense) |>
    dplyr::summarise(ally_w_mean = mean(ally_w, na.rm = TRUE)) |>
    dplyr::rename(ccode = ccode1)

  return(spatial_ally_data)

}

# Create spatial US alliance measure

clean_us_spatial_ally_f <- function(distlist, usallydata) {

  spatial_us_ally_data <- distlist |>
    left_join(usallydata, by = c("ccode2" = "ccode", "year")) |>
    group_by(ccode1, year) |>
    dplyr::mutate(us_ally = ifelse(is.na(us_ally), 0, us_ally),
                  invdistance = 1/mindist,
                  us_ally_w = invdistance * us_ally) |>
    dplyr::summarise(us_ally_w_mean = mean(us_ally_w, na.rm = TRUE)) |>
    dplyr::rename(ccode = ccode1)

  return(spatial_us_ally_data)

}



# Combine data into single data set

combine_data_f <- function(demdata, nmcdata, gdpdata, middata, troopsdata, usallydata, spatialtroopsdata, spatialallydata, spatialusallydata) {

  out <- demdata |>
    left_join(nmcdata) |>
    left_join(gdpdata) |>
    left_join(middata) |>
    left_join(troopsdata, by = c("ccode", "year")) |>
    left_join(usallydata) |>
    left_join(spatialtroopsdata) |>
    left_join(spatialallydata) |>
    left_join(spatialusallydata) |>
    filter(ccode != 2) |>
    mutate(across(starts_with("mids_"), ~ ifelse(is.na(.x), 0, .x)),
           us_ally = ifelse(is.na(us_ally), 0, us_ally),
           across(c("milex", "troops_w_mean", "milper", "tpop", "upop", "troops", "ally_w_mean", "us_ally_w_mean"),
                  ~ log1p(.x),
                  .names = "{col}_log"))

  return(out)

}
