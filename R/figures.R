

#### Figures for troops and conflict ####


descriptive_plots_f <- function(data) {


  # Plots of MIDs over time with troops indicator shading
  ggplot(data = data, aes(x = mids_total))  +
    geom_histogram(linewidth = 1.0) +
    viridis::scale_color_viridis(option = "magma") +
    scale_x_continuous(breaks = seq(0, 30, 5)) +
    theme_flynn(base_family = base_family, base_size = base_size) +
    labs(x = "MID Count",
         color = "log(US Troop Count)")

  ggsave("figures/mids-histogram.jpg", height = 4, width = 6, dpi = 300)


  # Plots of MIDs over time with troops indicator shading
  ggplot(data = data, aes(x = year, y = mids_total, color = log1p(troops)))  +
    geom_point(position = position_jitter(width = 0.2, height = 0.2), alpha = 0.6, size = 1.5, stroke = 0.1) +
    scale_x_continuous(breaks = seq(1950, 2015, 5), limits = c(1950, 2015)) +
    scale_y_continuous(breaks = seq(0, 30, 5)) +
    viridis::scale_color_viridis(option = "magma") +
    theme_flynn(base_family = base_family, base_size = base_size) +
    labs(x = "Year",
         y = "MID Count",
         color = "log(US Troop Count)")

  ggsave("figures/mids-year.jpg", height = 4, width = 6, dpi = 300)


  # Plots of MIDs across log of troops levels
  ggplot(data = data, aes(x = log1p(troops), y = mids_total))  +
    geom_point(position = position_jitter(width = 0.1, height = 0.1), alpha = 0.6, size = 1.5, stroke = 0.1) +
    scale_x_continuous(breaks = seq(0, 14, 2), limits = c(0, 14)) +
    scale_y_continuous(breaks = seq(0, 15, 3), limits = c(0, 15)) +
    viridis::scale_color_viridis(option = "magma") +
    theme_flynn(base_family = base_family, base_size = base_size) +
    labs(x = "log(US Troop Count)",
         y = "MID Count")

  ggsave("figures/mids-troops.jpg", height = 4, width = 6, dpi = 300)

}
