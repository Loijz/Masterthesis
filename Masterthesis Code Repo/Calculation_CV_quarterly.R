library(dplyr)
library(kableExtra)
library(webshot2)

setwd("C:/PATH")

# SD and CV for each commodity-quarter
dispersion_stats <- master_gold_iron_quarterly_clean %>%
  filter(Time_Horizon_Category == "Short-term (≤6mo)") %>%  
  group_by(Indicator, Publication_Quarter) %>%
  summarise(
    mean_forecast = mean(Value, na.rm = TRUE),
    sd_forecast = sd(Value, na.rm = TRUE),
    n_forecasts = n(),
    .groups = 'drop'
  ) %>%
  mutate(
    CV = (sd_forecast / mean_forecast) * 100  
  ) %>%
  filter(n_forecasts >= 3)  


head(dispersion_stats)

# summary statistics for the table
summary_stats <- dispersion_stats %>%
  group_by(Indicator) %>%
  summarise(
    mean_sd = mean(sd_forecast, na.rm = TRUE),
    mean_cv = mean(CV, na.rm = TRUE),
    min_sd = min(sd_forecast, na.rm = TRUE),
    max_sd = max(sd_forecast, na.rm = TRUE),
    min_cv = min(CV, na.rm = TRUE),
    max_cv = max(CV, na.rm = TRUE),
    .groups = 'drop'
  )

#  stats
print(summary_stats)

# values for each commodity
gold_stats <- summary_stats %>% filter(Indicator == "Gold")
iron_stats <- summary_stats %>% filter(Indicator == "Iron Ore")

# formatted table data
table_data <- data.frame(
  Commodity = c("Gold", "Iron Ore", "Ratio"),
  `Mean SD` = c(
    paste0("$", round(gold_stats$mean_sd, 0)),
    paste0("$", round(iron_stats$mean_sd, 0)),
    paste0(round(gold_stats$mean_sd / iron_stats$mean_sd, 1), "×")
  ),
  `Mean CV` = c(
    paste0(round(gold_stats$mean_cv, 1), "%"),
    paste0(round(iron_stats$mean_cv, 1), "%"),
    paste0(round(gold_stats$mean_cv / iron_stats$mean_cv, 2), "×")
  ),
  `SD Range` = c(
    paste0("$", round(gold_stats$min_sd, 0), "–$", round(gold_stats$max_sd, 0)),
    paste0("$", round(iron_stats$min_sd, 0), "–$", round(iron_stats$max_sd, 0)),
    "—"
  ),
  `CV Range` = c(
    paste0(round(gold_stats$min_cv, 1), "%–", round(gold_stats$max_cv, 1), "%"),
    paste0(round(iron_stats$min_cv, 1), "%–", round(iron_stats$max_cv, 1), "%"),
    "—"
  ),
  check.names = FALSE
)

# Create the final table
table_7_1 <- table_data %>%
  kbl(align = c("l", "r", "r", "r", "r"),
      caption = "Table: Comparison of absolut values and coefficient of variation",
      booktabs = TRUE,
      escape = FALSE) %>%
  kable_styling(bootstrap_options = "striped", full_width = FALSE,
                position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_data), background = "#FFFFFF") %>%  
  row_spec(3, italic = TRUE, background = "#FFFFFF") %>%  
  footnote(general = "Statistics calculated across all quarterly forecast observations, 2015-2025.
           SD measured in commodity-specific units (USD/troy oz for gold, USD/metric ton for iron ore).
           The ratio row shows Gold/Iron Ore ratios.",
           general_title = "Note:",
           footnote_as_chunk = TRUE)



table_7_1 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_cv_comparison_highres.png", 
             zoom = 4,      # 4x zoom for very high resolution
             density = 600)  # 600 DPI for publication quality


table_7_1
