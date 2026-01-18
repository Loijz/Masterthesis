setwd("C:/PATH")

#Load packages
library(ggplot2)
library(tidyverse)
library(knitr)
library(kableExtra)
library(readxl)

# For quarterly data
master_gold_iron_quarterly_clean <- master_gold_iron_quarterly_clean %>%
  filter(Value >= 25)

# For annual data
master_gold_iron_annually_clean <- master_gold_iron_annually_clean %>%
  filter(Value >= 25)

# function - convertion to characters
create_first_last_table <- function(df, caption_text) {
  
  # Convert entire dataframe to character FIRST
  df_char <- df %>% mutate(across(everything(), as.character))
  
  # check first 5
  first_5 <- df_char %>% head(5)
  
  # check last 5
  last_5 <- df_char %>% tail(5)
  
  # row of dots (now safe because everything is character)
  dots_row <- first_5[1,]
  dots_row[1,] <- "..."
  
  # Combine
  display_df <- bind_rows(first_5, dots_row, last_5)
  
  # table
  table <- display_df %>%
    kbl(caption = caption_text,
        align = "c",
        booktabs = TRUE) %>%
    kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      font_size = 10
    ) %>%
    row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
    row_spec(6, italic = TRUE, background = "#f0f0f0")  
  
  return(table)
}


table_quarterly <- create_first_last_table(
  master_gold_iron_quarterly_clean,
  "Table: Master Dataset - Quarterly Forecasts (Sample)"
)

table_quarterly

save_kable(table_quarterly,
           "table_6_1_quarterly_sample.png",
           zoom = 2)

# Annual table
table_annually <- create_first_last_table(
  master_gold_iron_annually_clean,
  "Table 6.2: Master Dataset - Annual Forecasts (Sample)"
)

table_annually

save_kable(table_annually,
           "table_6_2_annual_sample.png",
           zoom = 2)





##################

# Table Indicator to Has_Realized
create_first_last_table_part1 <- function(df, caption_text) {
  
  # Select columns for first table
  df_part1 <- df %>%
    select(Indicator, Source, Period, PublicationDate, Value, Realized_Price, Time_Horizon_Days, 
           Time_Horizon_Months, Time_Horizon_Category, 
           Publication_Quarter, Has_Realized)
  
  # Convert to character
  df_char <- df_part1 %>% mutate(across(everything(), as.character))
  
  first_5 <- df_char %>% head(5)
  last_5 <- df_char %>% tail(5)
  
  dots_row <- first_5[1,]
  dots_row[1,] <- "..."
  
  display_df <- bind_rows(first_5, dots_row, last_5)
  
  table <- display_df %>%
    kbl(caption = caption_text,
        align = "c",
        booktabs = TRUE) %>%
    kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      font_size = 9
    ) %>%
    row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
    row_spec(6, italic = TRUE, background = "#f0f0f0")
  
  return(table)
}

# Table Difficulty_Penalty to Is_Outlier
create_first_last_table_part2 <- function(df, caption_text) {
  
  # Select columns for second table
  df_part2 <- df %>%
    select(Difficulty_Penalty, Difficulty_Penalty_Normalized, N_Forecasters, Rolling_Volatility_3m,
           Q1, Q3, IQR, Lower_Bound, Upper_Bound, Is_Outlier)
  
  # Convert to character
  df_char <- df_part2 %>% mutate(across(everything(), as.character))
  
  first_5 <- df_char %>% head(5)
  last_5 <- df_char %>% tail(5)
  
  dots_row <- first_5[1,]
  dots_row[1,] <- "..."
  
  display_df <- bind_rows(first_5, dots_row, last_5)
  
  table <- display_df %>%
    kbl(caption = caption_text,
        align = "c",
        booktabs = TRUE) %>%
    kable_styling(
      bootstrap_options = c("striped", "hover", "condensed"),
      full_width = FALSE,
      font_size = 9
    ) %>%
    row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
    row_spec(6, italic = TRUE, background = "#f0f0f0")
  
  return(table)
}

# tables for quarterly data
table_quarterly_part1 <- create_first_last_table_part1(
  master_gold_iron_quarterly_clean,
  "Table: Quarterly Dataset - Core Variables (Sample)"
)

table_quarterly_part1

save_kable(table_quarterly_part1,
           "table_6_1a_quarterly_core.png",
           zoom = 2)

table_quarterly_part2 <- create_first_last_table_part2(
  master_gold_iron_quarterly_clean,
  "Table: Quarterly Dataset - Derived Variables (Sample)"
)

table_quarterly_part2

save_kable(table_quarterly_part2,
           "table_6_1b_quarterly_derived.png",
           zoom = 2)



originaldatasetirongold <- read_excel("C:/PATH/datasetirongold.xlsx")
summary(originaldatasetirongold)






### Distribution Analysis

### QUARTERLY DATA ###

# Forecast Horizon Distribution (Quarterly)
horizon_dist_q <- master_gold_iron_quarterly_clean %>%
  ggplot(aes(x = Time_Horizon_Months, fill = Indicator)) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
  facet_wrap(~Indicator, ncol = 1) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Distribution of Forecast Horizons - Quarterly Data",
    x = "Forecast Horizon (Months)",
    y = "Number of Forecasts"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

horizon_dist_q

ggsave("figure_6_1_forecast_horizon_quarterly.png",
       plot = horizon_dist_q,
       width = 10, height = 6, dpi = 300)

# Forecaster Count Distribution (Quarterly)
forecaster_dist_q <- master_gold_iron_quarterly_clean %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  ggplot(aes(x = N_Forecasters, fill = Indicator)) +
  geom_histogram(bins = 20, alpha = 0.7, position = "identity") +
  facet_wrap(~Indicator, ncol = 1) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Distribution of Forecaster Counts - Quarterly Data",
    x = "Number of Forecasters",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

forecaster_dist_q

ggsave("figure_6_2_forecaster_count_quarterly.png",
       plot = forecaster_dist_q,
       width = 10, height = 6, dpi = 300)


### ANNUAL DATA ###

# Forecast Horizon Distribution (Annual)
horizon_dist_a <- master_gold_iron_annually_clean %>%
  ggplot(aes(x = Time_Horizon_Months, fill = Indicator)) +
  geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
  facet_wrap(~Indicator, ncol = 1) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Distribution of Forecast Horizons - Annual Data",
    x = "Forecast Horizon (Months)",
    y = "Number of Forecasts"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

horizon_dist_a

ggsave("figure_6_3_forecast_horizon_annual.png",
       plot = horizon_dist_a,
       width = 10, height = 6, dpi = 300)

# Forecaster Count Distribution (Annual)
forecaster_dist_a <- master_gold_iron_annually_clean %>%
  distinct(Period, Indicator, PublicationDate, N_Forecasters) %>%
  ggplot(aes(x = N_Forecasters, fill = Indicator)) +
  geom_histogram(bins = 20, alpha = 0.7, position = "identity") +
  facet_wrap(~Indicator, ncol = 1) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Distribution of Forecaster Counts - Annual Data",
    x = "Number of Forecasters",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

forecaster_dist_a

ggsave("figure_6_4_forecaster_count_annual.png",
       plot = forecaster_dist_a,
       width = 10, height = 6, dpi = 300)


### SUMMARY STATISTICS ###

# Summary stats for horizons
cat("\n=== FORECAST HORIZON SUMMARY ===\n")
cat("\nQuarterly:\n")
master_gold_iron_quarterly_clean %>%
  group_by(Indicator) %>%
  summarise(
    Min = min(Time_Horizon_Months, na.rm = TRUE),
    Q1 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    Median = median(Time_Horizon_Months, na.rm = TRUE),
    Mean = mean(Time_Horizon_Months, na.rm = TRUE),
    Q3 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    Max = max(Time_Horizon_Months, na.rm = TRUE)
  ) %>%
  print()

cat("\nAnnual:\n")
master_gold_iron_annually_clean %>%
  group_by(Indicator) %>%
  summarise(
    Min = min(Time_Horizon_Months, na.rm = TRUE),
    Q1 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    Median = median(Time_Horizon_Months, na.rm = TRUE),
    Mean = mean(Time_Horizon_Months, na.rm = TRUE),
    Q3 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    Max = max(Time_Horizon_Months, na.rm = TRUE)
  ) %>%
  print()

# Summary stats for forecaster counts
cat("\n=== FORECASTER COUNT SUMMARY ===\n")
cat("\nQuarterly:\n")
master_gold_iron_quarterly_clean %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    Min = min(N_Forecasters, na.rm = TRUE),
    Q1 = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median = median(N_Forecasters, na.rm = TRUE),
    Mean = mean(N_Forecasters, na.rm = TRUE),
    Q3 = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max = max(N_Forecasters, na.rm = TRUE)
  ) %>%
  print()

cat("\nAnnual:\n")
master_gold_iron_annually_clean %>%
  distinct(Period, Indicator, PublicationDate, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    Min = min(N_Forecasters, na.rm = TRUE),
    Q1 = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median = median(N_Forecasters, na.rm = TRUE),
    Mean = mean(N_Forecasters, na.rm = TRUE),
    Q3 = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max = max(N_Forecasters, na.rm = TRUE)
  ) %>%
  print()





### FORECAST HORIZON DISTRIBUTION TABLES ###

# Quarterly - Forecast Horizon Summary
horizon_summary_q <- master_gold_iron_quarterly_clean %>%
  group_by(Indicator) %>%
  summarise(
    N_Forecasts = n(),
    Min = min(Time_Horizon_Months, na.rm = TRUE),
    Q1 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    Median = median(Time_Horizon_Months, na.rm = TRUE),
    Mean = round(mean(Time_Horizon_Months, na.rm = TRUE), 1),
    Q3 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    Max = max(Time_Horizon_Months, na.rm = TRUE),
    SD = round(sd(Time_Horizon_Months, na.rm = TRUE), 1)
  )

horizon_table_q <- horizon_summary_q %>%
  kbl(caption = "Table 6.3: Forecast Horizon Distribution - Quarterly Data",
      col.names = c("Commodity", "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 8)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(horizon_summary_q), background = "#FFFFFF") %>%
  add_header_above(c(" " = 2, "Forecast Horizon (Months)" = 7))

horizon_table_q

save_kable(horizon_table_q,
           "table_6_3_horizon_quarterly.png",
           zoom = 2)

# Annual - Forecast Horizon Summary
horizon_summary_a <- master_gold_iron_annually_clean %>%
  group_by(Indicator) %>%
  summarise(
    N_Forecasts = n(),
    Min = min(Time_Horizon_Months, na.rm = TRUE),
    Q1 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    Median = median(Time_Horizon_Months, na.rm = TRUE),
    Mean = round(mean(Time_Horizon_Months, na.rm = TRUE), 1),
    Q3 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    Max = max(Time_Horizon_Months, na.rm = TRUE),
    SD = round(sd(Time_Horizon_Months, na.rm = TRUE), 1)
  )

horizon_table_a <- horizon_summary_a %>%
  kbl(caption = "Table 6.4: Forecast Horizon Distribution - Annual Data",
      col.names = c("Commodity", "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 8)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(horizon_summary_a), background = "#FFFFFF") %>%
  add_header_above(c(" " = 2, "Forecast Horizon (Months)" = 7))

horizon_table_a

save_kable(horizon_table_a,
           "table_6_4_horizon_annual.png",
           zoom = 2)


### FORECASTER COUNT DISTRIBUTION TABLES ###

# Quarterly - Forecaster Count Summary
forecaster_summary_q <- master_gold_iron_quarterly_clean %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods = n(),
    Min = min(N_Forecasters, na.rm = TRUE),
    Q1 = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median = median(N_Forecasters, na.rm = TRUE),
    Mean = round(mean(N_Forecasters, na.rm = TRUE), 1),
    Q3 = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max = max(N_Forecasters, na.rm = TRUE),
    SD = round(sd(N_Forecasters, na.rm = TRUE), 1)
  )

forecaster_table_q <- forecaster_summary_q %>%
  kbl(caption = "Table 6.5: Forecaster Count Distribution - Quarterly Data",
      col.names = c("Commodity", "N Periods", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 8)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(forecaster_summary_q), background = "#FFFFFF") %>%
  add_header_above(c(" " = 2, "Number of Forecasters" = 7))

forecaster_table_q

save_kable(forecaster_table_q,
           "table_6_5_forecasters_quarterly.png",
           zoom = 2)

# Annual - Forecaster Count Summary
forecaster_summary_a <- master_gold_iron_annually_clean %>%
  distinct(Period, Indicator, PublicationDate, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods = n(),
    Min = min(N_Forecasters, na.rm = TRUE),
    Q1 = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median = median(N_Forecasters, na.rm = TRUE),
    Mean = round(mean(N_Forecasters, na.rm = TRUE), 1),
    Q3 = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max = max(N_Forecasters, na.rm = TRUE),
    SD = round(sd(N_Forecasters, na.rm = TRUE), 1)
  )

forecaster_table_a <- forecaster_summary_a %>%
  kbl(caption = "Table 6.6: Forecaster Count Distribution - Annual Data",
      col.names = c("Commodity", "N Periods", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 8)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(forecaster_summary_a), background = "#FFFFFF") %>%
  add_header_above(c(" " = 2, "Number of Forecasters" = 7))

forecaster_table_a

save_kable(forecaster_table_a,
           "table_6_6_forecasters_annual.png",
           zoom = 2)

# Print all tables
print("=== QUARTERLY DATA ===")
print(horizon_table_q)
print(forecaster_table_q)

print("=== ANNUAL DATA ===")
print(horizon_table_a)
print(forecaster_table_a)




### COMBINED FORECASTER COUNT TABLE ###

# Prepare quarterly data
forecaster_summary_q <- master_gold_iron_quarterly_clean %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods_Q = n(),
    Min_Q = min(N_Forecasters, na.rm = TRUE),
    Q1_Q = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median_Q = median(N_Forecasters, na.rm = TRUE),
    Mean_Q = round(mean(N_Forecasters, na.rm = TRUE), 1),
    Q3_Q = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max_Q = max(N_Forecasters, na.rm = TRUE),
    SD_Q = round(sd(N_Forecasters, na.rm = TRUE), 1)
  )

# Prepare annual data
forecaster_summary_a <- master_gold_iron_annually_clean %>%
  distinct(Period, Indicator, PublicationDate, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods_A = n(),
    Min_A = min(N_Forecasters, na.rm = TRUE),
    Q1_A = quantile(N_Forecasters, 0.25, na.rm = TRUE),
    Median_A = median(N_Forecasters, na.rm = TRUE),
    Mean_A = round(mean(N_Forecasters, na.rm = TRUE), 1),
    Q3_A = quantile(N_Forecasters, 0.75, na.rm = TRUE),
    Max_A = max(N_Forecasters, na.rm = TRUE),
    SD_A = round(sd(N_Forecasters, na.rm = TRUE), 1)
  )

# Combine
forecaster_combined <- forecaster_summary_q %>%
  left_join(forecaster_summary_a, by = "Indicator")

# Create combined table
forecaster_table_combined <- forecaster_combined %>%
  kbl(caption = "Table: Forecaster Count Distribution",
      col.names = c("Commodity", 
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD",
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 16)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE,
    font_size = 10
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(forecaster_combined), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Quarterly" = 8, "Annual" = 8))

forecaster_table_combined

save_kable(forecaster_table_combined,
           "table_6_5_forecasters_combined.png",
           zoom = 2)



### COMBINED FORECASTER COUNT TABLE ###

# Prepare quarterly data
forecaster_summary_q <- master_gold_iron_quarterly_clean %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods_Q = n(),
    Min_Q = min(N_Forecasters, na.rm = TRUE),
    Q1_Q = round(quantile(N_Forecasters, 0.25, na.rm = TRUE), 2),
    Median_Q = round(median(N_Forecasters, na.rm = TRUE), 2),
    Mean_Q = round(mean(N_Forecasters, na.rm = TRUE), 2),
    Q3_Q = round(quantile(N_Forecasters, 0.75, na.rm = TRUE), 2),
    Max_Q = max(N_Forecasters, na.rm = TRUE),
    SD_Q = round(sd(N_Forecasters, na.rm = TRUE), 2)
  )

# Prepare annual data
forecaster_summary_a <- master_gold_iron_annually_clean %>%
  distinct(Period, Indicator, PublicationDate, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    N_Periods_A = n(),
    Min_A = min(N_Forecasters, na.rm = TRUE),
    Q1_A = round(quantile(N_Forecasters, 0.25, na.rm = TRUE), 2),
    Median_A = round(median(N_Forecasters, na.rm = TRUE), 2),
    Mean_A = round(mean(N_Forecasters, na.rm = TRUE), 2),
    Q3_A = round(quantile(N_Forecasters, 0.75, na.rm = TRUE), 2),
    Max_A = max(N_Forecasters, na.rm = TRUE),
    SD_A = round(sd(N_Forecasters, na.rm = TRUE), 2)
  )

# Combine
forecaster_combined <- forecaster_summary_q %>%
  left_join(forecaster_summary_a, by = "Indicator")

# Create combined table
forecaster_table_combined <- forecaster_combined %>%
  kbl(caption = "Table: Forecaster Count Distribution",
      col.names = c("Commodity", 
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD",
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 16)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE,
    font_size = 10
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(forecaster_combined), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Quarterly" = 8, "Annual" = 8))

forecaster_table_combined

save_kable(forecaster_table_combined,
           "table_6_5_forecasters_combined.png",
           zoom = 2)


### COMBINED FORECAST HORIZON TABLE ###

# Prepare quarterly horizon data
horizon_summary_q <- master_gold_iron_quarterly_clean %>%
  group_by(Indicator) %>%
  summarise(
    N_Q = n(),
    Min_Q = round(min(Time_Horizon_Months, na.rm = TRUE), 2),
    Q1_Q = round(quantile(Time_Horizon_Months, 0.25, na.rm = TRUE), 2),
    Median_Q = round(median(Time_Horizon_Months, na.rm = TRUE), 2),
    Mean_Q = round(mean(Time_Horizon_Months, na.rm = TRUE), 2),
    Q3_Q = round(quantile(Time_Horizon_Months, 0.75, na.rm = TRUE), 2),
    Max_Q = round(max(Time_Horizon_Months, na.rm = TRUE), 2),
    SD_Q = round(sd(Time_Horizon_Months, na.rm = TRUE), 2)
  )

# Prepare annual horizon data
horizon_summary_a <- master_gold_iron_annually_clean %>%
  group_by(Indicator) %>%
  summarise(
    N_A = n(),
    Min_A = round(min(Time_Horizon_Months, na.rm = TRUE), 2),
    Q1_A = round(quantile(Time_Horizon_Months, 0.25, na.rm = TRUE), 2),
    Median_A = round(median(Time_Horizon_Months, na.rm = TRUE), 2),
    Mean_A = round(mean(Time_Horizon_Months, na.rm = TRUE), 2),
    Q3_A = round(quantile(Time_Horizon_Months, 0.75, na.rm = TRUE), 2),
    Max_A = round(max(Time_Horizon_Months, na.rm = TRUE), 2),
    SD_A = round(sd(Time_Horizon_Months, na.rm = TRUE), 2)
  )

# Combine
horizon_combined <- horizon_summary_q %>%
  left_join(horizon_summary_a, by = "Indicator")

# Create combined table
horizon_table_combined <- horizon_combined %>%
  kbl(caption = "Table: Forecast Horizon Distribution (Months)",
      col.names = c("Commodity", 
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD",
                    "N", "Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
      align = c("l", rep("r", 16)),
      booktabs = TRUE) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover", "condensed"),
    full_width = FALSE,
    font_size = 10
  ) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:nrow(horizon_combined), background = "#FFFFFF") %>%
  add_header_above(c(" " = 1, "Quarterly" = 8, "Annual" = 8))

horizon_table_combined

save_kable(horizon_table_combined,
           "table_6_3_horizon_combined.png",
           zoom = 2)

# Print both tables
print(horizon_table_combined)
print(forecaster_table_combined)






### Raw Forecast Points - Quarterly ###

raw_forecasts_q <- master_gold_iron_quarterly_clean %>%
  ggplot(aes(x = Period, y = Value, color = Indicator)) +
  geom_point(alpha = 0.3, size = 1) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  scale_color_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Raw Forecast Distribution - Quarterly Data",
    subtitle = "Each point represents a single forecast",
    x = "Target Period",
    y = "Forecasted Price"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

raw_forecasts_q

ggsave("figure_6_5_raw_forecasts_quarterly.png",
       plot = raw_forecasts_q,
       width = 12, height = 8, dpi = 300)


### Raw Forecast Points - Annual ###

raw_forecasts_a <- master_gold_iron_annually_clean %>%
  ggplot(aes(x = Period, y = Value, color = Indicator)) +
  geom_point(alpha = 0.3, size = 1.5) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  scale_color_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Raw Forecast Distribution - Annual Data",
    subtitle = "Each point represents a single forecast",
    x = "Target Period",
    y = "Forecasted Price"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14)
  )

raw_forecasts_a

ggsave("figure_6_6_raw_forecasts_annual.png",
       plot = raw_forecasts_a,
       width = 12, height = 8, dpi = 300)


### Forecasts vs Realized Prices ###

forecasts_vs_realized_q <- master_gold_iron_quarterly_clean %>%
  filter(Has_Realized == TRUE) %>%
  ggplot(aes(x = Period)) +
  geom_point(aes(y = Value), alpha = 0.2, size = 1, color = "grey50") +
  geom_line(aes(y = Realized_Price), color = "red", linewidth = 1.2) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(
    title = "Forecasts vs. Realized Prices - Quarterly",
    subtitle = "Red line = realized prices, grey points = individual forecasts",
    x = "Target Period",
    y = "Price"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

forecasts_vs_realized_q

ggsave("figure_6_7_forecasts_vs_realized_quarterly.png",
       plot = forecasts_vs_realized_q,
       width = 12, height = 8, dpi = 300)


### Box Plots by Year ###

forecasts_by_year_q <- master_gold_iron_quarterly_clean %>%
  mutate(Year = year(Period)) %>%
  filter(Year >= 2015, Year <= 2025) %>%
  ggplot(aes(x = factor(Year), y = Value, fill = Indicator)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Forecast Distribution by Year",
    x = "Year",
    y = "Forecasted Price"
  ) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 14)
  )

forecasts_by_year_q

ggsave("figure_6_8_forecasts_by_year_quarterly.png",
       plot = forecasts_by_year_q,
       width = 12, height = 8, dpi = 300)




