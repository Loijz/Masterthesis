library(readxl)
library(dplyr)
library(lubridate)
library(ggplot2)
library(tidyverse)
library(kableExtra)


setwd("C:/PATH")

scraped_gold <- read_excel("C:/Users/jsaar/OneDrive/Masterarbeit/Data/scraped_gold.xlsx") %>%
  select(`Prediction in`, `For`, Forecast, Mean, Expertise, Commodity) %>%
  rename(
    Indicator = Commodity,
    Source = Expertise, 
    Period = `For`,
    PublicationDate = `Prediction in`,
    Value = Mean,
    Time_Horizon_Days = Forecast
  ) %>%
  mutate(
    Time_Horizon_Days = Time_Horizon_Days * 30,
    Time_Horizon_Category = case_when(
      Time_Horizon_Days >= 0 & Time_Horizon_Days <= 180 ~ "Short-term (≤6mo)",
      Time_Horizon_Days >= 181 & Time_Horizon_Days <= 720 ~ "Mid-term (6-24mo)",
      Time_Horizon_Days >= 721 ~ "Long-term (>24mo)",
      TRUE ~ NA_character_
    ),
    PublicationDate = as_datetime(dmy(PublicationDate)),
    Period = as_datetime(dmy(Period)),
    Publication_Quarter = paste0(year(PublicationDate), "-Q", quarter(PublicationDate)),
    dataset = "scraped"
  ) %>%
  filter(!is.na(Period))

head(scraped_gold)



scraped_iron_ore <- read_excel("C:/Users/jsaar/OneDrive/Masterarbeit/Data/scraped_iron_ore.xlsx") %>%
  select(`Prediction in`, `For`, Forecast, Mean, Expertise, Commodity) %>%
  rename(
    Indicator = Commodity,
    Source = Expertise, 
    Period = `For`,
    PublicationDate = `Prediction in`,
    Value = Mean,
    Time_Horizon_Days = Forecast
  ) %>%
  mutate(
    Time_Horizon_Days = Time_Horizon_Days * 30,
    Time_Horizon_Category = case_when(
      Time_Horizon_Days >= 0 & Time_Horizon_Days <= 180 ~ "Short-term (≤6mo)",
      Time_Horizon_Days >= 181 & Time_Horizon_Days <= 720 ~ "Mid-term (6-24mo)",
      Time_Horizon_Days >= 721 ~ "Long-term (>24mo)",
      TRUE ~ NA_character_
    ),
    PublicationDate = as_datetime(dmy(PublicationDate)),
    Period = as_datetime(dmy(Period)),
    Publication_Quarter = paste0(year(PublicationDate), "-Q", quarter(PublicationDate)),
    dataset = "scraped"
  ) %>%
  filter(!is.na(Period))  # Remove rows where Period is NA (failed to parse)

head(scraped_iron_ore)

scraped_commodities <- bind_rows(scraped_gold, scraped_iron_ore)

# Save as CSV
write.csv(scraped_commodities, 
          "C:/Users/jsaar/OneDrive/Masterarbeit/Data/scraped_commodities.csv", 
          row.names = FALSE)

# Save as RDA
save(scraped_commodities, 
     file = "C:/Users/jsaar/OneDrive/Masterarbeit/Data/scraped_commodities.rda")

master_gold_iron_quarterly_clean <- master_gold_iron_quarterly_clean %>%
  filter(Value >= 25)

focuseconomics_commodities <- master_gold_iron_quarterly_clean %>%
  mutate(
    dataset = "focuseconomics"
  )

# select
cols_to_keep <- names(scraped_commodities)

# Select and bind
data_validation_df <- bind_rows(
  scraped_commodities,
  focuseconomics_commodities %>% select(all_of(cols_to_keep))
)

data_validation_df <- data_validation_df %>%
  filter(PublicationDate >= as.Date("2016-01-01"))



# unique combinations
time_horizons <- unique(data_validation_df$Time_Horizon_Category)
commodities <- unique(data_validation_df$Indicator)

counter <- 1

# Loop through each combination and create separate plots
for (horizon in time_horizons) {
  for (commodity in commodities) {
    
    # Filter data for this combination
    plot_data <- data_validation_df %>%
      filter(Time_Horizon_Category == horizon, Indicator == commodity)
    
    # Create the plot
    p <- ggplot(plot_data, aes(x = PublicationDate, y = Value, color = dataset)) +
      geom_point(aes(alpha = dataset)) +
      scale_alpha_manual(values = c("focuseconomics" = 0.2, "scraped" = 1.0)) +
      geom_smooth(method = "lm", se = TRUE) +
      labs(
        title = paste(commodity, "-", horizon),
        x = "Publication Date",
        y = "Value",
        color = "Dataset"
      ) +
      guides(alpha = "none") +
      theme_classic() +
      theme(legend.position = "bottom",
            plot.title = element_text(face = "bold"),
            panel.background = element_rect(fill = "white", color = "black"),
            plot.background = element_rect(fill = "white", color = NA),
            panel.grid.major = element_line(color = "gray90"))
    
    
    ggsave(
      filename = paste0("C:/PATH/data_val", counter, ".png"),
      plot = p,
      width = 10,
      height = 6,
      dpi = 300
    )
    
    counter <- counter + 1
  }
}



###################################
# Filter for short-term only
short_term_data <- data_validation_df %>%
  filter(Time_Horizon_Category == "Short-term (≤6mo)")

# Create separate tables for each indicator
gold_short_term_data <- short_term_data %>%
  filter(Indicator == "Gold")

iron_short_term_data <- short_term_data %>%
  filter(Indicator == "Iron Ore")
#####################################







# ===== GOLD SHORT-TERM =====

# Aggregate data
gold_aggregated <- gold_short_term_data %>%
  group_by(Publication_Quarter, dataset) %>%
  summarise(
    Value = mean(Value, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  arrange(Publication_Quarter) %>%
  mutate(Quarter_numeric = as.numeric(as.factor(Publication_Quarter)))

#  separate datasets
gold_focus <- gold_aggregated %>% filter(dataset == "focuseconomics")
gold_scraped <- gold_aggregated %>% filter(dataset == "scraped")

# Run regressions
model_focus <- lm(Value ~ Quarter_numeric, data = gold_focus)
model_scraped <- lm(Value ~ Quarter_numeric, data = gold_scraped)

summary_focus <- summary(model_focus)
summary_scraped <- summary(model_scraped)

# Create and save plot
gold_plot <- ggplot(gold_aggregated, aes(x = Quarter_numeric, y = Value, color = dataset)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Gold Short-term: Regression Comparison",
       x = "Publication Quarter (Timeline)",
       y = "Value (CV)") +
  theme_minimal()

ggsave("gold_short_term_validation_plot.png", 
       plot = gold_plot, 
       width = 10, height = 6, dpi = 300)

# Step 5: Match overlapping quarters
gold_matched <- gold_focus %>%
  inner_join(gold_scraped, by = "Publication_Quarter", suffix = c("_focus", "_scraped"))

# Calculate correlations
if(nrow(gold_matched) >= 2) {
  pearson_cor <- cor(gold_matched$Value_focus, gold_matched$Value_scraped, 
                     method = "pearson", use = "complete.obs")
  spearman_cor <- cor(gold_matched$Value_focus, gold_matched$Value_scraped, 
                      method = "spearman", use = "complete.obs")
} else {
  pearson_cor <- NA
  spearman_cor <- NA
}

# Create and save table with white background
validation_table_gold <- tibble(
  Metric = c(
    "Number of Observations",
    "R-squared",
    "Regression Slope",
    "Regression Intercept",
    "Number of Matching Quarters",
    "Pearson Correlation (matched)",
    "Spearman Correlation (matched)"
  ),
  FocusEconomics = c(
    nrow(gold_focus),
    round(summary_focus$r.squared, 3),
    round(coef(model_focus)[2], 4),
    round(coef(model_focus)[1], 4),
    nrow(gold_matched),
    round(pearson_cor, 3),
    round(spearman_cor, 3)
  ),
  Scraped = c(
    nrow(gold_scraped),
    round(summary_scraped$r.squared, 3),
    round(coef(model_scraped)[2], 4),
    round(coef(model_scraped)[1], 4),
    nrow(gold_matched),
    round(pearson_cor, 3),
    round(spearman_cor, 3)
  )
)

validation_table_gold_formatted <- validation_table_gold %>%
  kbl(caption = "Gold Short-term: Dataset Validation Comparison",
      align = c("l", "r", "r")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:7, background = "#FFFFFF")

save_kable(validation_table_gold_formatted, 
           "gold_short_term_validation_table.png",
           zoom = 2)

print(validation_table_gold)


# ===== IRON ORE SHORT-TERM =====

# Aggregate data
iron_aggregated <- iron_short_term_data %>%
  group_by(Publication_Quarter, dataset) %>%
  summarise(
    Value = mean(Value, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  arrange(Publication_Quarter) %>%
  mutate(Quarter_numeric = as.numeric(as.factor(Publication_Quarter)))

# Create separate datasets
iron_focus <- iron_aggregated %>% filter(dataset == "focuseconomics")
iron_scraped <- iron_aggregated %>% filter(dataset == "scraped")

# Run regressions
model_focus <- lm(Value ~ Quarter_numeric, data = iron_focus)
model_scraped <- lm(Value ~ Quarter_numeric, data = iron_scraped)

summary_focus <- summary(model_focus)
summary_scraped <- summary(model_scraped)

# Create and save plot
iron_plot <- ggplot(iron_aggregated, aes(x = Quarter_numeric, y = Value, color = dataset)) +
  geom_point(alpha = 0.6, size = 3) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(title = "Iron Ore Short-term: Regression Comparison",
       x = "Publication Quarter (Timeline)",
       y = "Value (CV)") +
  theme_minimal()

ggsave("iron_short_term_validation_plot.png", 
       plot = iron_plot, 
       width = 10, height = 6, dpi = 300)

# Match overlapping quarters
iron_matched <- iron_focus %>%
  inner_join(iron_scraped, by = "Publication_Quarter", suffix = c("_focus", "_scraped"))

# Calculate correlations
if(nrow(iron_matched) >= 2) {
  pearson_cor <- cor(iron_matched$Value_focus, iron_matched$Value_scraped, 
                     method = "pearson", use = "complete.obs")
  spearman_cor <- cor(iron_matched$Value_focus, iron_matched$Value_scraped, 
                      method = "spearman", use = "complete.obs")
} else {
  pearson_cor <- NA
  spearman_cor <- NA
}

# Create and save table with white background
validation_table_iron <- tibble(
  Metric = c(
    "Number of Observations",
    "R-squared",
    "Regression Slope",
    "Regression Intercept",
    "Number of Matching Quarters",
    "Pearson Correlation (matched)",
    "Spearman Correlation (matched)"
  ),
  FocusEconomics = c(
    nrow(iron_focus),
    round(summary_focus$r.squared, 3),
    round(coef(model_focus)[2], 4),
    round(coef(model_focus)[1], 4),
    nrow(iron_matched),
    round(pearson_cor, 3),
    round(spearman_cor, 3)
  ),
  Scraped = c(
    nrow(iron_scraped),
    round(summary_scraped$r.squared, 3),
    round(coef(model_scraped)[2], 4),
    round(coef(model_scraped)[1], 4),
    nrow(iron_matched),
    round(pearson_cor, 3),
    round(spearman_cor, 3)
  )
)

validation_table_iron_formatted <- validation_table_iron %>%
  kbl(caption = "Iron Ore Short-term: Dataset Validation Comparison",
      align = c("l", "r", "r")) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed"),
                full_width = FALSE) %>%
  row_spec(0, bold = TRUE, background = "#FFFFFF") %>%
  row_spec(1:7, background = "#FFFFFF")

save_kable(validation_table_iron_formatted, 
           "iron_short_term_validation_table.png",
           zoom = 2)

print(validation_table_iron)

