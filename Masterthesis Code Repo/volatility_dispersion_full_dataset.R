library(ggplot2)
library(dplyr)
library(kableExtra)

setwd("C:/PATH")


#  from model_data_quarterly (all forecasters)
base_data_full <- model_data_quarterly %>%
  distinct(Period, Indicator, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV), 
         !is.na(Rolling_Volatility_3m),
         !is.na(Time_Numeric),
         !is.na(Time_Horizon_Months),
         !is.na(Difficulty_Penalty_Normalized),
         !is.na(N_Forecasters))



# outliers
cat("=== OUTLIER CHECK - FULL DATASET ===\n\n")

# dispersion outliers
base_data_full %>%
  group_by(Indicator) %>%
  summarise(
    Mean = mean(Dispersion_CV, na.rm = TRUE),
    SD = sd(Dispersion_CV, na.rm = TRUE),
    Min = min(Dispersion_CV, na.rm = TRUE),
    Max = max(Dispersion_CV, na.rm = TRUE),
    Q95 = quantile(Dispersion_CV, 0.95, na.rm = TRUE),
    Q99 = quantile(Dispersion_CV, 0.99, na.rm = TRUE)
  ) %>%
  print()

# extreme outliers
cat("\n=== OUTLIERS CHECK ===\n")
base_data_full %>%
  group_by(Indicator) %>%
  summarise(
    N = n(),
    N_Above_50 = sum(Dispersion_CV > 50, na.rm = TRUE),
    N_Above_100 = sum(Dispersion_CV > 100, na.rm = TRUE),
    Max_Dispersion = max(Dispersion_CV, na.rm = TRUE)
  ) %>%
  print()

# extreme outliers
cat("\n=== EXTREME OUTLIERS ===\n")
base_data_full %>%
  filter(Dispersion_CV > 50) %>%
  select(Indicator, Period, Publication_Quarter, Dispersion_CV, N_Forecasters, Rolling_Volatility_3m) %>%
  arrange(desc(Dispersion_CV)) %>%
  head(20) %>%
  print()

cat("Full dataset rows:", nrow(base_data_full), "\n")
cat("Balanced dataset rows:", nrow(base_data), "\n")

# Volatility vs Dispersion scatter - FULL DATA
fig_9_7_3a_full <- base_data_full %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV, color = Indicator)) +
  geom_point(alpha = 0.4, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  facet_wrap(~Indicator, ncol = 1, scales = "free") +
  labs(title = "Figure: Market Volatility vs. Forecast Dispersion (All Forecasters)",
       subtitle = "Iron Ore: positive relationship; Gold: negative relationship (2016-2025)",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),
        strip.background = element_rect(fill = "gray95"))

fig_9_7_3a_full

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3a_volatility_dispersion_full.png",
       fig_9_7_3a_full, width = 10, height = 8, dpi = 300, bg = "white")

# Gold: Pre vs Post 2022 - FULL DATA
fig_9_7_3b_full <- base_data_full %>%
  filter(Indicator == "Gold") %>%
  mutate(Period_Group = ifelse(year(Period) < 2022, "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)")) %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV, color = Period_Group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Pre-2022 (2016-2021)" = "steelblue", 
                                "Post-2022 (2022-2025)" = "coral")) +
  labs(title = "Figure: Gold Volatility-Dispersion Relationship Over Time (All Forecasters)",
       subtitle = "Negative relationship over time",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Period") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"))

fig_9_7_3b_full

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3b_gold_volatility_temporal_full.png",
       fig_9_7_3b_full, width = 10, height = 6, dpi = 300, bg = "white")

# Iron Ore: Pre vs Post 2022 - FULL DATA
fig_9_7_3c_full <- base_data_full %>%
  filter(Indicator == "Iron Ore") %>%
  mutate(Period_Group = ifelse(year(Period) < 2022, "Pre-2022 (2016-2021)", "Post-2022 (2022-2025)")) %>%
  ggplot(aes(x = Rolling_Volatility_3m, y = Dispersion_CV, color = Period_Group)) +
  geom_point(alpha = 0.5, size = 2) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Pre-2022 (2016-2021)" = "steelblue", 
                                "Post-2022 (2022-2025)" = "coral")) +
  labs(title = "Figure: Iron Ore Volatility-Dispersion Relationship Over Time (All Forecasters)",
       subtitle = "Positive relationship over time",
       x = "Rolling Volatility (3-month, %)",
       y = "Dispersion (CV %)",
       color = "Period") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"))

fig_9_7_3c_full

ggsave("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/fig_9_7_3c_iron_volatility_temporal_full.png",
       fig_9_7_3c_full, width = 10, height = 6, dpi = 300, bg = "white")

# volatility quintiles for Gold - FULL DATA
table_9_7_3_full_data <- base_data_full %>%
  filter(Indicator == "Gold") %>%
  mutate(
    Volatility_Quintile = ntile(Rolling_Volatility_3m, 5),
    Volatility_Group = case_when(
      Volatility_Quintile == 1 ~ "Q1 (Lowest)",
      Volatility_Quintile == 2 ~ "Q2",
      Volatility_Quintile == 3 ~ "Q3",
      Volatility_Quintile == 4 ~ "Q4",
      Volatility_Quintile == 5 ~ "Q5 (Highest)"
    )
  ) %>%
  group_by(Volatility_Group) %>%
  summarise(
    Mean_Volatility = mean(Rolling_Volatility_3m, na.rm = TRUE),
    Mean_Dispersion = mean(Dispersion_CV, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

# formatted table - Gold Full
table_9_7_3_full <- table_9_7_3_full_data %>%
  kbl(digits = 2,
      caption = "Table: Gold Dispersion by Volatility Quintile (All Forecasters)",
      col.names = c("Volatility Quintile", "Mean Volatility (%)", "Mean Dispersion (CV %)", "SD", "N"),
      booktabs = TRUE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_9_7_3_full_data), background = "#FFFFFF") %>%
  add_footnote("Note: Volatility quintiles based on 3-month rolling standard deviation of gold price returns. Full dataset including all forecasters.",
               notation = "none")

table_9_7_3_full

table_9_7_3_full %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_3_volatility_quintiles_full.png",
             zoom = 3, density = 300)

# volatility quintiles for Iron Ore - FULL DATA
table_9_7_4_full_data <- base_data_full %>%
  filter(Indicator == "Iron Ore") %>%
  mutate(
    Volatility_Quintile = ntile(Rolling_Volatility_3m, 5),
    Volatility_Group = case_when(
      Volatility_Quintile == 1 ~ "Q1 (Lowest)",
      Volatility_Quintile == 2 ~ "Q2",
      Volatility_Quintile == 3 ~ "Q3",
      Volatility_Quintile == 4 ~ "Q4",
      Volatility_Quintile == 5 ~ "Q5 (Highest)"
    )
  ) %>%
  group_by(Volatility_Group) %>%
  summarise(
    Mean_Volatility = mean(Rolling_Volatility_3m, na.rm = TRUE),
    Mean_Dispersion = mean(Dispersion_CV, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV, na.rm = TRUE),
    N = n(),
    .groups = "drop"
  )

# formatted table - Iron Ore Full
table_9_7_4_full <- table_9_7_4_full_data %>%
  kbl(digits = 2,
      caption = "Table: Iron Ore Dispersion by Volatility Quintile (All Forecasters)",
      col.names = c("Volatility Quintile", "Mean Volatility (%)", "Mean Dispersion (CV %)", "SD", "N"),
      booktabs = TRUE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_9_7_4_full_data), background = "#FFFFFF") %>%
  add_footnote("Note: Volatility quintiles based on 3-month rolling standard deviation of iron ore price returns. Full dataset including all forecasters.",
               notation = "none")

table_9_7_4_full

table_9_7_4_full %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_4_iron_volatility_quintiles_full.png",
             zoom = 3, density = 300)

################## CORRELATION ANALYSIS - FULL DATA ####################

# correlations for all groups - FULL DATA
correlation_analysis_full <- data.frame(
  Dataset = character(),
  Period = character(),
  Correlation = numeric(),
  P_value = numeric(),
  N = numeric(),
  stringsAsFactors = FALSE
)

# Both Commodities - FULL
overall_pre_full <- base_data_full %>% filter(year(Period) < 2022)
overall_post_full <- base_data_full %>% filter(year(Period) >= 2022)

correlation_analysis_full <- rbind(correlation_analysis_full,
                                   data.frame(
                                     Dataset = "Overall (Both)",
                                     Period = "Overall",
                                     Correlation = cor(base_data_full$Rolling_Volatility_3m, base_data_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(base_data_full$Rolling_Volatility_3m, base_data_full$Dispersion_CV)$p.value,
                                     N = nrow(base_data_full)
                                   ),
                                   data.frame(
                                     Dataset = "Overall (Both)",
                                     Period = "Pre-2022",
                                     Correlation = cor(overall_pre_full$Rolling_Volatility_3m, overall_pre_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(overall_pre_full$Rolling_Volatility_3m, overall_pre_full$Dispersion_CV)$p.value,
                                     N = nrow(overall_pre_full)
                                   ),
                                   data.frame(
                                     Dataset = "Overall (Both)",
                                     Period = "Post-2022",
                                     Correlation = cor(overall_post_full$Rolling_Volatility_3m, overall_post_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(overall_post_full$Rolling_Volatility_3m, overall_post_full$Dispersion_CV)$p.value,
                                     N = nrow(overall_post_full)
                                   )
)

# Gold - FULL
gold_data_full <- base_data_full %>% filter(Indicator == "Gold")
gold_pre_full <- gold_data_full %>% filter(year(Period) < 2022)
gold_post_full <- gold_data_full %>% filter(year(Period) >= 2022)

correlation_analysis_full <- rbind(correlation_analysis_full,
                                   data.frame(
                                     Dataset = "Gold",
                                     Period = "Overall",
                                     Correlation = cor(gold_data_full$Rolling_Volatility_3m, gold_data_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(gold_data_full$Rolling_Volatility_3m, gold_data_full$Dispersion_CV)$p.value,
                                     N = nrow(gold_data_full)
                                   ),
                                   data.frame(
                                     Dataset = "Gold",
                                     Period = "Pre-2022",
                                     Correlation = cor(gold_pre_full$Rolling_Volatility_3m, gold_pre_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(gold_pre_full$Rolling_Volatility_3m, gold_pre_full$Dispersion_CV)$p.value,
                                     N = nrow(gold_pre_full)
                                   ),
                                   data.frame(
                                     Dataset = "Gold",
                                     Period = "Post-2022",
                                     Correlation = cor(gold_post_full$Rolling_Volatility_3m, gold_post_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(gold_post_full$Rolling_Volatility_3m, gold_post_full$Dispersion_CV)$p.value,
                                     N = nrow(gold_post_full)
                                   )
)

# Iron Ore - FULL
iron_data_full <- base_data_full %>% filter(Indicator == "Iron Ore")
iron_pre_full <- iron_data_full %>% filter(year(Period) < 2022)
iron_post_full <- iron_data_full %>% filter(year(Period) >= 2022)

correlation_analysis_full <- rbind(correlation_analysis_full,
                                   data.frame(
                                     Dataset = "Iron Ore",
                                     Period = "Overall",
                                     Correlation = cor(iron_data_full$Rolling_Volatility_3m, iron_data_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(iron_data_full$Rolling_Volatility_3m, iron_data_full$Dispersion_CV)$p.value,
                                     N = nrow(iron_data_full)
                                   ),
                                   data.frame(
                                     Dataset = "Iron Ore",
                                     Period = "Pre-2022",
                                     Correlation = cor(iron_pre_full$Rolling_Volatility_3m, iron_pre_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(iron_pre_full$Rolling_Volatility_3m, iron_pre_full$Dispersion_CV)$p.value,
                                     N = nrow(iron_pre_full)
                                   ),
                                   data.frame(
                                     Dataset = "Iron Ore",
                                     Period = "Post-2022",
                                     Correlation = cor(iron_post_full$Rolling_Volatility_3m, iron_post_full$Dispersion_CV, use = "complete.obs"),
                                     P_value = cor.test(iron_post_full$Rolling_Volatility_3m, iron_post_full$Dispersion_CV)$p.value,
                                     N = nrow(iron_post_full)
                                   )
)

# change from pre to post - FULL
change_summary_full <- correlation_analysis_full %>%
  filter(Period != "Overall") %>%
  select(Dataset, Period, Correlation, N) %>%
  tidyr::pivot_wider(names_from = Period, values_from = c(Correlation, N)) %>%
  mutate(
    Change = `Correlation_Post-2022` - `Correlation_Pre-2022`,
    Pct_Change = (Change / abs(`Correlation_Pre-2022`)) * 100
  )

# Z test - FULL
test_cor_difference <- function(r1, n1, r2, n2) {
  z1 <- 0.5 * log((1 + r1) / (1 - r1))
  z2 <- 0.5 * log((1 + r2) / (1 - r2))
  se_diff <- sqrt(1/(n1 - 3) + 1/(n2 - 3))
  z_stat <- (z1 - z2) / se_diff
  p_value <- 2 * (1 - pnorm(abs(z_stat)))
  return(data.frame(z_statistic = z_stat, p_value = p_value))
}

test_results_full <- data.frame(
  Dataset = c("Overall (Both)", "Gold", "Iron Ore"),
  stringsAsFactors = FALSE
)

for(i in 1:3) {
  dataset_name <- test_results_full$Dataset[i]
  pre_data <- correlation_analysis_full %>% filter(Dataset == dataset_name, Period == "Pre-2022")
  post_data <- correlation_analysis_full %>% filter(Dataset == dataset_name, Period == "Post-2022")
  
  test <- test_cor_difference(
    pre_data$Correlation, pre_data$N,
    post_data$Correlation, post_data$N
  )
  
  test_results_full$Z_statistic[i] <- test$z_statistic
  test_results_full$P_value[i] <- test$p_value
}

# Combine - FULL
final_table_full <- change_summary_full %>%
  left_join(test_results_full, by = "Dataset") %>%
  select(Dataset, 
         `Correlation_Pre-2022`, `N_Pre-2022`,
         `Correlation_Post-2022`, `N_Post-2022`,
         Change, Z_statistic, P_value)


cat("\n=== VOLATILITY-DISPERSION CORRELATIONS (ALL FORECASTERS) ===\n\n")
print(correlation_analysis_full %>% 
        mutate(across(where(is.numeric), ~round(., 3))))

cat("\n\n=== CHANGE FROM PRE TO POST-2022 (ALL FORECASTERS) ===\n\n")
print(final_table_full %>% 
        mutate(across(where(is.numeric), ~round(., 3))))

# formatted table - FULL
table_volatility_correlation_full <- final_table_full %>%
  mutate(
    Sig = case_when(
      P_value < 0.001 ~ "***",
      P_value < 0.01 ~ "**",
      P_value < 0.05 ~ "*",
      P_value < 0.1 ~ ".",
      TRUE ~ ""
    ),
    Change_Sig = paste0(sprintf("%.3f", Change), Sig)
  ) %>%
  select(Dataset, 
         `Correlation_Pre-2022`, `N_Pre-2022`,
         `Correlation_Post-2022`, `N_Post-2022`,
         Change_Sig, Z_statistic, P_value) %>%
  kbl(digits = 3,
      caption = "Table: Volatility-Dispersion Correlation Change - All Forecasters (Pre vs Post-2022)",
      col.names = c("Dataset", "Correlation", "N", "Correlation", "N", 
                    "Change", "Z-stat", "p-value"),
      booktabs = TRUE,
      escape = FALSE,
      align = c("l", "r", "r", "r", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(final_table_full), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Pre-2022 (2016-2021)" = 2, "Post-2022 (2022-2025)" = 2, 
                     "Test of Difference" = 3),
                   background = "#FFFFFF") %>%
  footnote(general = "*** p < 0.001, ** p < 0.01, * p < 0.05, . p < 0.1. Fisher's Z transformation test for difference between correlations. Full dataset including all forecasters.")

table_volatility_correlation_full

table_volatility_correlation_full %>%
  save_kable("table_volatility_correlation_change_full.png",
             zoom = 3, density = 300)
