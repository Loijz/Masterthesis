library(ggplot2)
library(dplyr)
library(tidyr)
library(kableExtra)

setwd("C:/PATH")

# filter categories
horizon_data <- base_data %>%
  mutate(
    Horizon_Category = case_when(
      Time_Horizon_Months <= 6 ~ "Short-term (1-6 mo)",
      Time_Horizon_Months <= 12 ~ "Medium-term (7-12 mo)",
      TRUE ~ "Long-term (13+ mo)"
    ),
    Horizon_Category = factor(Horizon_Category, 
                              levels = c("Short-term (1-6 mo)", 
                                         "Medium-term (7-12 mo)", 
                                         "Long-term (13+ mo)"))
  )

# Scatter plot with smooth lines
fig_9_7_1 <- horizon_data %>%
  ggplot(aes(x = Time_Horizon_Months, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1.5, alpha = 0.2) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  facet_wrap(~Indicator, ncol = 1, scales = "free_y") +
  labs(title = "Figure: Dispersion by Time Horizon",
       subtitle = "Relationship between forecast horizon and dispersion (2016-2025)",
       x = "Time Horizon (months)",
       y = "Dispersion (CV %)",
       color = "Commodity") +
  theme_classic() +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        panel.background = element_rect(fill = "white", color = "black"),
        plot.background = element_rect(fill = "white", color = NA),
        panel.grid.major = element_line(color = "gray90"),
        strip.background = element_rect(fill = "gray95"))

fig_9_7_1

ggsave("fig_9_7_1_horizon_effects.png",
       fig_9_7_1, width = 10, height = 8, dpi = 300, bg = "white")



# horizon x difficulty cross-tabulation
table_9_7_1_data <- base_data %>%
  mutate(
    Horizon_Category = case_when(
      Time_Horizon_Months <= 6 ~ "Short (1-6 mo)",
      Time_Horizon_Months <= 12 ~ "Medium (7-12 mo)",
      TRUE ~ "Long (13+ mo)"
    ),
    Difficulty_Level = ifelse(
      Difficulty_Penalty_Normalized > median(Difficulty_Penalty_Normalized, na.rm = TRUE),
      "High Difficulty",
      "Low Difficulty"
    )
  ) %>%
  group_by(Indicator, Horizon_Category, Difficulty_Level) %>%
  summarise(
    N = n(),
    Mean_Dispersion = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(Indicator, Horizon_Category, Difficulty_Level)

# View
print(table_9_7_1_data)

# Create formatted table for Gold
table_gold_horizon <- table_9_7_1_data %>%
  filter(Indicator == "Gold") %>%
  select(-Indicator) %>%
  pivot_wider(
    names_from = Difficulty_Level,
    values_from = c(Mean_Dispersion, N),
    names_sep = "_"
  ) %>%
  select(Horizon_Category, 
         `Mean_Dispersion_Low Difficulty`, 
         `Mean_Dispersion_High Difficulty`,
         `N_Low Difficulty`,
         `N_High Difficulty`)

# formatted table
table_9_7_1 <- table_gold_horizon %>%
  kbl(digits = 2,
      caption = "Table: Gold Dispersion by Time Horizon and Difficulty Level",
      col.names = c("Horizon", "Low Difficulty", "High Difficulty", "N", "N"),
      booktabs = TRUE,
      align = c("l", "r", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_gold_horizon), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Mean Dispersion (CV %)" = 2, "Observations" = 2),
                   background = "#FFFFFF") %>%
  add_footnote("Note: Difficulty level based on median split of normalized difficulty penalty.",
               notation = "none")

table_9_7_1

table_9_7_1 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_9_7_1_horizon_difficulty.png",
             zoom = 3, density = 300)





# Summarise to unique rows per Indicator/Horizon/Difficulty
summary_tbl <- table_9_7_1_data %>%
  group_by(Indicator, Horizon_Category, Difficulty_Level) %>%
  summarise(
    Mean_Dispersion = mean(Mean_Dispersion, na.rm = TRUE),
    N = sum(N, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Difficulty_Level = dplyr::recode(
      Difficulty_Level,
      "Low Difficulty"  = "Low",
      "High Difficulty" = "High",
      .default = as.character(Difficulty_Level)
    )
  )

# Pivot Low/High side-by-side per Indicator + Horizon
table_all_horizon <- summary_tbl %>%
  pivot_wider(
    names_from = Difficulty_Level,
    values_from = c(Mean_Dispersion, N),
    names_glue = "{.value}_{Difficulty_Level}",
    values_fill = list(Mean_Dispersion = NA_real_, N = 0)
  ) %>%
  mutate(Horizon_Category = factor(Horizon_Category,
                                   levels = c("Short (1-6 mo)", "Medium (7-12 mo)", "Long (13+ mo)"))) %>%
  arrange(Indicator, Horizon_Category) %>%
  select(Indicator, Horizon_Category,
         Mean_Dispersion_Low, Mean_Dispersion_High,
         N_Low, N_High)


table_all_horizon <- table_all_horizon %>%
  mutate(Pct_Change = ((Mean_Dispersion_High - Mean_Dispersion_Low) /
                         Mean_Dispersion_Low) * 100)


# row ranges for pack_rows grouping by Indicator
row_index <- table_all_horizon %>%
  group_by(Indicator) %>%
  summarise(n = n(), .groups = "drop") %>%
  mutate(
    start = cumsum(dplyr::lag(n, default = 0)) + 1,
    end   = cumsum(n)
  )

# table
kbl_tbl <- table_all_horizon %>%
  select(-Indicator) %>%
  kbl(
    digits = 2,
    caption = "Table: Dispersion by Time Horizon, Difficulty Level, and Indicator",
    col.names = c("Horizon", "Low Difficulty", "High Difficulty", "N", "N", "Change in %"),
    booktabs = TRUE,
    align = c("l", "r", "r", "r", "r", "r")
  ) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(table_all_horizon), background = "#FFFFFF") %>%
  add_header_above(
    c(" " = 1, "Mean Dispersion (CV %)" = 2, "Observations" = 2, "Change" = 1),
    background = "#FFFFFF"
  ) %>%
  add_footnote(
    "Note: Difficulty level based on median split of normalized difficulty penalty.",
    notation = "none"
  )


for (i in seq_len(nrow(row_index))) {
  kbl_tbl <- kbl_tbl %>%
    pack_rows(
      group_label = row_index$Indicator[i],
      start_row   = row_index$start[i],
      end_row     = row_index$end[i],
      label_row   = TRUE,
      latex_gap_space = "0em"
    )
}

kbl_tbl
kbl_tbl %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_horizon_difficulty.png",
             zoom = 3, density = 300)
