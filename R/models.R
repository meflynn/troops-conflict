# Run models analyzing MIDs as a function of troop deployment levels
#


models_base_f <- function(data) {

  job::job(import = "all", "troops-mids-1" = {

  # Get priors for the base model
  get_prior(bf(mids_total ~ troops_log + us_ally + troops_w_mean_log +
                   ally_w_mean_log + us_ally_w_mean_log + cinc + v2x_libdem +
                   wbpopest + milper_log + s(year) + (1 | ccode),
                 decomp = "QR"),
              data = analysis_data,
              family = negbinomial(link = "log", link_shape = "log"))

    PRIORS <- c(set_prior("normal(0, 2)", class = "b"),
                set_prior("normal(0, 3)", class = "Intercept"),
                set_prior("normal(0, 3)", class = "sd", group = "ccode"),
                set_prior("normal(0, 3)", class = "sd", coef = "Intercept", group = "ccode"),
                set_prior("gamma(1, 1)", class = "shape")
                )

  temp <- brms::brm(bf(mids_total ~ troops_log + us_ally + troops_w_mean_log + ally_w_mean_log + us_ally_w_mean_log + cinc + v2x_libdem + wbpopest + milper_log + s(year) + (1 | ccode),
                     decomp = "QR"),
                  data = data,
                  family = negbinomial(link = "log", link_shape = "log"),
                  prior = PRIORS,
                  chains = CHAINS,
                  cores = CORES,
                  iter = ITERS,
                  warmup = WARMUP,
                  threads = threading(2),
                  thin = THIN,
                  file_refit = "on_change",
                  save_model = "code/troops-mids-1.stan",
                  backend = "cmdstanr",
                  file = "output/troops-mids-1"
                  )

  }
  )

  return(temp)

}


# Include interaction term between troops and spatial troops
models_interaction_f <- function(data) {

  job::job(import = "all", "troops-mids-1" = {

    # Get priors for the base model
    get_prior(bf(mids_total ~ troops_log + troops_log:troops_w_mean_log +
                   us_ally + troops_w_mean_log + ally_w_mean_log +
                   us_ally_w_mean_log + cinc + v2x_libdem +
                   wbpopest + milper_log + s(year) + (1 | ccode),
                 decomp = "QR"),
              data = data,
              family = negbinomial(link = "log", link_shape = "log"))

    PRIORS <- c(set_prior("normal(0, 2)", class = "b"),
                set_prior("normal(0, 3)", class = "Intercept"),
                set_prior("normal(0, 3)", class = "sd", group = "ccode"),
                set_prior("normal(0, 3)", class = "sd", coef = "Intercept", group = "ccode"),
                set_prior("gamma(1, 1)", class = "shape")
    )

    temp <- brms::brm(bf(mids_total ~ troops_log + troops_log:troops_w_mean_log + us_ally + troops_w_mean_log + ally_w_mean_log + us_ally_w_mean_log + cinc + v2x_libdem + wbpopest + milper_log + s(year) + (1 | ccode),
                       decomp = "QR"),
                    data = data,
                    family = negbinomial(link = "log", link_shape = "log"),
                    prior = PRIORS,
                    chains = CHAINS,
                    cores = CORES,
                    iter = ITERS,
                    warmup = WARMUP,
                    threads = threading(2),
                    thin = THIN,
                    file_refit = "on_change",
                    save_model = "code/troops-mids-2.stan",
                    backend = "cmdstanr",
                    file = "output/troops-mids-2"
    )

  }
  )

  return(temp)

}
