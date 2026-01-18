###Staging master_gold_iron_quarterly###

# Load the package
library(readxl)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(lubridate)
library(zoo)
library(knitr)
library(kableExtra)


#Loading of quarterly dataset
master_gold_iron_quarterly <- read_excel("C:/PATH.xlsx")
#Loading of realised gold and iron ore prices
realisation_gold_iron_monthly <- read_excel("C:/PATH.xlsx")

##Variable of Price Realization
#Left join of realised data onto forecast dataset
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  left_join(
    realisation_gold_iron_monthly, 
    by = c("Period" = "Date", "Indicator" = "Commodity")
  ) %>%
  rename(Realized_Price = Price)
head(master_gold_iron_quarterly)

#Loading of annually dataset
master_gold_iron_annually <- read_excel("C:/PATH.xlsx")
#Loading of annually realised prices
realisation_gold_iron_annually <- read_excel("C:/PATH.xlsx")

#Left join of realised data onto forecast dataset
master_gold_iron_annually <- master_gold_iron_annually %>%
  left_join(
    realisation_gold_iron_annually,
    by = c("Period" = "Date", "Indicator" = "Commodity")
  ) %>%
  rename(Realized_Price = Price)

#Merge Check
# Check for any missing realized prices
master_gold_iron_quarterly %>% 
  filter(is.na(Realized_Price)) %>% 
  View()

master_gold_iron_annually %>% 
  filter(is.na(Realized_Price)) %>% 
  View()

## Variable of Time Horizon
## Checking the distribution of time horizon in the dataset as a helper for the steps decision
## Distribution of forecast horizons

# For quarterly forecasts
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  mutate(
    Time_Horizon_Days = as.numeric(as.Date(Period) - as.Date(PublicationDate)),
    

    Time_Horizon_Months = Time_Horizon_Days / 30.44,     # Convert to months
    
    # Categorical version
    Time_Horizon_Category = case_when(
      Time_Horizon_Months <= 6 ~ "Short-term (≤6mo)",
      Time_Horizon_Months <= 24 ~ "Mid-term (6-24mo)",
      Time_Horizon_Months > 24 ~ "Long-term (>24mo)"
    )
  )

# Annual 
master_gold_iron_annually <- master_gold_iron_annually %>%
  mutate(
    Time_Horizon_Days = as.numeric(as.Date(Period) - as.Date(PublicationDate)),
    Time_Horizon_Months = Time_Horizon_Days / 30.44,
    Time_Horizon_Category = case_when(
      Time_Horizon_Months <= 6 ~ "Short-term (≤6mo)",
      Time_Horizon_Months <= 24 ~ "Mid-term (6-24mo)",
      Time_Horizon_Months > 24 ~ "Long-term (>24mo)"
    )
  )


# Remove negative time horizons from quarterly
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  filter(Time_Horizon_Months >= 0)

# Remove negative time horizons from annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  filter(Time_Horizon_Months >= 0)


# Verify the removals
master_gold_iron_quarterly %>%
  summarise(
    n = n(),
    min = min(Time_Horizon_Months, na.rm = TRUE),
    median = median(Time_Horizon_Months, na.rm = TRUE),
    max = max(Time_Horizon_Months, na.rm = TRUE)
  )

master_gold_iron_annually %>%
  summarise(
    n = n(),
    min = min(Time_Horizon_Months, na.rm = TRUE),
    median = median(Time_Horizon_Months, na.rm = TRUE),
    max = max(Time_Horizon_Months, na.rm = TRUE)
  )


#Visualisation of distribution
master_gold_iron_quarterly %>%
  ggplot(aes(x = Time_Horizon_Months)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~Indicator) +
  labs(title = "Distribution of Forecast Horizons",
       x = "Months Ahead", y = "Count") +
  theme_minimal()

# Summary statistics
master_gold_iron_quarterly %>%
  summarise(
    min = min(Time_Horizon_Months, na.rm = TRUE),
    q25 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    median = median(Time_Horizon_Months, na.rm = TRUE),
    q75 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    max = max(Time_Horizon_Months, na.rm = TRUE)
  )

#Visualisation of distribution
master_gold_iron_annually %>%
  ggplot(aes(x = Time_Horizon_Months)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~Indicator) +
  labs(title = "Distribution of Forecast Horizons",
       x = "Months Ahead", y = "Count") +
  theme_minimal()

# Summary statistics
master_gold_iron_annually %>%
  summarise(
    min = min(Time_Horizon_Months, na.rm = TRUE),
    q25 = quantile(Time_Horizon_Months, 0.25, na.rm = TRUE),
    median = median(Time_Horizon_Months, na.rm = TRUE),
    q75 = quantile(Time_Horizon_Months, 0.75, na.rm = TRUE),
    max = max(Time_Horizon_Months, na.rm = TRUE)
  )

# Validation if the categories make sense
master_gold_iron_quarterly %>%
  count(Time_Horizon_Category) %>%
  mutate(pct = n / sum(n) * 100)

master_gold_iron_annually %>%
  count(Time_Horizon_Category) %>%
  mutate(pct = n / sum(n) * 100)


#New Variable Q
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  mutate(
    Publication_Quarter = paste0(year(PublicationDate), "-Q", quarter(PublicationDate))
  )

master_gold_iron_annually <- master_gold_iron_annually %>%
  mutate(
    Publication_Quarter = paste0(year(PublicationDate), "-Q", quarter(PublicationDate))
  )

# Check
master_gold_iron_quarterly %>%
  count(Publication_Quarter) %>%
  head(10)
head(master_gold_iron_annually)



# Convert Realized_Price to numeric (dbl) in quarterly
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  mutate(Realized_Price = as.numeric(Realized_Price))

# Convert Realized_Price to numeric (dbl) in annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  mutate(Realized_Price = as.numeric(Realized_Price))

# Create the Has_Realized flag for quarterly
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  mutate(Has_Realized = !is.na(Realized_Price))

# Create the Has_Realized flag for annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  mutate(Has_Realized = !is.na(Realized_Price))

# For quarterly - only for periods with realized prices
penalty_quarterly <- master_gold_iron_quarterly %>%
  filter(Has_Realized == TRUE) %>%
  mutate(
    Absolute_Pct_Error = abs(Value - Realized_Price) / Realized_Price * 100
  ) %>%
  group_by(Period, Indicator) %>%
  summarise(
    MAPE = mean(Absolute_Pct_Error, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(Difficulty_Penalty = MAPE)

# Merge back to main data
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  left_join(penalty_quarterly, by = c("Period", "Indicator"))

# For annual
penalty_annually <- master_gold_iron_annually %>%
  filter(Has_Realized == TRUE) %>%
  mutate(
    Absolute_Pct_Error = abs(Value - Realized_Price) / Realized_Price * 100
  ) %>%
  group_by(Period, Indicator) %>%
  summarise(
    MAPE = mean(Absolute_Pct_Error, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rename(Difficulty_Penalty = MAPE)

master_gold_iron_annually <- master_gold_iron_annually %>%
  left_join(penalty_annually, by = c("Period", "Indicator"))

master_gold_iron_quarterly %>%
  filter(Has_Realized == TRUE) %>%
  distinct(Period, Indicator, Difficulty_Penalty) %>%
  ggplot(aes(x = Period, y = Difficulty_Penalty, color = Indicator)) +
  geom_line(linewidth = 1) +
  geom_point(alpha = 0.5) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Forecast Difficulty Over Time (Quarterly)",
    subtitle = "Higher MAPE indicates periods that were harder to forecast",
    x = "Target Period",
    y = "Difficulty Penalty (MAPE %)",
    color = "Commodity"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

master_gold_iron_annually %>%
  filter(Has_Realized == TRUE) %>%
  distinct(Period, Indicator, Difficulty_Penalty) %>%
  ggplot(aes(x = Period, y = Difficulty_Penalty, color = Indicator)) +
  geom_line(linewidth = 1) +
  geom_point(alpha = 0.5, size = 3) +
  scale_color_manual(values = c("Gold" = "gold3", "Iron Ore" = "darkgrey")) +
  labs(
    title = "Forecast Difficulty Over Time (Annual)",
    subtitle = "Higher MAPE indicates years that were harder to forecast",
    x = "Target Year",
    y = "Difficulty Penalty (MAPE %)",
    color = "Commodity"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

master_gold_iron_quarterly %>%
  filter(Has_Realized == TRUE) %>%
  distinct(Period, Indicator, Difficulty_Penalty) %>%
  ggplot(aes(x = Period, y = Difficulty_Penalty)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(alpha = 0.5) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(
    title = "Forecast Difficulty Over Time (Quarterly)",
    x = "Target Period",
    y = "Difficulty Penalty (MAPE %)"
  ) +
  theme_minimal()


# For quarterly - sigmoid transformation
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  group_by(Indicator) %>%
  mutate(
    Difficulty_Penalty_Normalized = 1 / (1 + exp(-0.1 * (Difficulty_Penalty - mean(Difficulty_Penalty, na.rm = TRUE))))
  ) %>%
  ungroup()

# For annual - sigmoid transformation
master_gold_iron_annually <- master_gold_iron_annually %>%
  group_by(Indicator) %>%
  mutate(
    Difficulty_Penalty_Normalized = 1 / (1 + exp(-0.1 * (Difficulty_Penalty - mean(Difficulty_Penalty, na.rm = TRUE))))
  ) %>%
  ungroup()

master_gold_iron_quarterly %>%
  filter(!is.na(Difficulty_Penalty_Normalized)) %>%
  ggplot(aes(x = Difficulty_Penalty_Normalized, fill = Indicator)) +
  geom_histogram(bins = 30, alpha = 0.7) +
  facet_wrap(~Indicator) +
  scale_fill_manual(values = c("gold3", "darkgrey")) +
  labs(title = "Distribution of Normalized Difficulty Penalty",
       x = "Normalized Penalty (0-1)") +
  theme_minimal()

#Variable number of forecasters
# Count forecasters per period, commodity, and publication quarter - Quarterly
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  mutate(N_Forecasters = n_distinct(Source)) %>%
  ungroup()

# Same for annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  mutate(N_Forecasters = n_distinct(Source)) %>%
  ungroup()

# Check the distribution
master_gold_iron_quarterly %>%
  summarise(
    min = min(N_Forecasters),
    median = median(N_Forecasters),
    max = max(N_Forecasters)
  )

master_gold_iron_annually %>%
  summarise(
    min = min(N_Forecasters),
    median = median(N_Forecasters),
    max = max(N_Forecasters)
  )

#Variable Rolling Volatility of Actual Prices Quarterly

realisation_gold_iron_monthly <- realisation_gold_iron_monthly %>%
  mutate(Price = as.numeric(Price))

realisation_gold_iron_annually <- realisation_gold_iron_annually %>%
  mutate(Price = as.numeric(Price))

volatility_data <- realisation_gold_iron_monthly %>%
  arrange(Commodity, Date) %>%
  group_by(Commodity) %>%
  mutate(
    # Calculate price returns (% change month-to-month)
    Price_Return = (Price - lag(Price)) / lag(Price) * 100,
    
    # 3-month rolling standard deviation of returns
    Rolling_Volatility_3m = rollapply(
      Price_Return,
      width = 3,
      FUN = sd,
      na.rm = TRUE,
      fill = NA,
      align = "right"
    )
  ) %>%
  ungroup() %>%
  select(Date, Commodity, Rolling_Volatility_3m)

# Merge to quarterly forecast data
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  left_join(
    volatility_data,
    by = c("Period" = "Date", "Indicator" = "Commodity")
  )

# Calculate annual rolling volatility (using annual data)
volatility_annual <- realisation_gold_iron_annually %>%
  arrange(Commodity, Date) %>%
  group_by(Commodity) %>%
  mutate(
    # Calculate year-to-year price returns
    Price_Return = (Price - lag(Price)) / lag(Price) * 100,
    
    # 3-year rolling standard deviation
    Rolling_Volatility_3y = rollapply(
      Price_Return,
      width = 3,
      FUN = sd,
      na.rm = TRUE,
      fill = NA,
      align = "right"
    )
  ) %>%
  ungroup() %>%
  select(Date, Commodity, Rolling_Volatility_3y)

# Merge to annual forecast data
master_gold_iron_annually <- master_gold_iron_annually %>%
  left_join(
    volatility_annual,
    by = c("Period" = "Date", "Indicator" = "Commodity")
  )

##Real Dispersion
#First adressing and delete outliers
# For quarterly - flag outliers within each (Period, Indicator, Publication_Quarter) group
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  mutate(
    Q1 = quantile(Value, 0.25, na.rm = TRUE),
    Q3 = quantile(Value, 0.75, na.rm = TRUE),
    IQR = Q3 - Q1,
    Lower_Bound = Q1 - 2.5 * IQR,
    Upper_Bound = Q3 + 2.5 * IQR,
    Is_Outlier = Value < Lower_Bound | Value > Upper_Bound
  ) %>%
  ungroup()

# For annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  mutate(
    Q1 = quantile(Value, 0.25, na.rm = TRUE),
    Q3 = quantile(Value, 0.75, na.rm = TRUE),
    IQR = Q3 - Q1,
    Lower_Bound = Q1 - 2.5 * IQR,
    Upper_Bound = Q3 + 2.5 * IQR,
    Is_Outlier = Value < Lower_Bound | Value > Upper_Bound
  ) %>%
  ungroup()

# See how many outliers
master_gold_iron_quarterly %>%
  count(Is_Outlier)

# Look at some examples
master_gold_iron_quarterly %>%
  filter(Is_Outlier == TRUE) %>%
  select(Indicator, Period, Source, Value, Realized_Price, Lower_Bound, Upper_Bound) %>%
  arrange(Indicator, Period) %>%
  head(20) %>%
  View()

master_gold_iron_annually %>%
  count(Is_Outlier)

master_gold_iron_annually %>%
  filter(Is_Outlier == TRUE) %>%
  select(Indicator, Period, Source, Value, Realized_Price, Lower_Bound, Upper_Bound) %>%
  arrange(Indicator, Period) %>%
  head(20) %>%
  View()

# Remove outliers
master_gold_iron_quarterly_clean <- master_gold_iron_quarterly %>%
  filter(Is_Outlier == FALSE)

master_gold_iron_annually_clean <- master_gold_iron_annually %>%
  filter(Is_Outlier == FALSE)

# Check how many removed
nrow(master_gold_iron_quarterly) - nrow(master_gold_iron_quarterly_clean)
nrow(master_gold_iron_annually) - nrow(master_gold_iron_annually_clean)

# Clean up outlier columns first
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  filter(Is_Outlier == FALSE) %>%
  select(-Q1, -Q3, -IQR, -Lower_Bound, -Upper_Bound, -Is_Outlier)

master_gold_iron_annually <- master_gold_iron_annually %>%
  filter(Is_Outlier == FALSE) %>%
  select(-Q1, -Q3, -IQR, -Lower_Bound, -Upper_Bound, -Is_Outlier)

# Calculate dispersion measures for quarterly data
dispersion_quarterly <- master_gold_iron_quarterly %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(
    # Standard deviation
    Dispersion_SD = sd(Value, na.rm = TRUE),
    
    # Interquartile range (robust measure)
    Dispersion_IQR = IQR(Value, na.rm = TRUE),
    
    # Range
    Dispersion_Range = max(Value, na.rm = TRUE) - min(Value, na.rm = TRUE),
    
    # Coefficient of variation (normalized by mean)
    Mean_Forecast = mean(Value, na.rm = TRUE),
    Dispersion_CV = Dispersion_SD / Mean_Forecast * 100,
    
    .groups = "drop"
  )

# Calculate dispersion measures for annual data
dispersion_annually <- master_gold_iron_annually %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(
    Dispersion_SD = sd(Value, na.rm = TRUE),
    Dispersion_IQR = IQR(Value, na.rm = TRUE),
    Dispersion_Range = max(Value, na.rm = TRUE) - min(Value, na.rm = TRUE),
    Mean_Forecast = mean(Value, na.rm = TRUE),
    Dispersion_CV = Dispersion_SD / Mean_Forecast * 100,
    .groups = "drop"
  )

# Preview the results
head(dispersion_quarterly, 10)
head(dispersion_annually, 10)

# Summary statistics
summary(dispersion_quarterly$Dispersion_SD)
summary(dispersion_annually$Dispersion_SD)

# Merge dispersion measures to quarterly data
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  left_join(
    dispersion_quarterly,
    by = c("Period", "Indicator", "Publication_Quarter")
  )

# Merge dispersion measures to annual data
master_gold_iron_annually <- master_gold_iron_annually %>%
  left_join(
    dispersion_annually,
    by = c("Period", "Indicator", "Publication_Quarter")
  )

# Summary comparison table by commodity
comparison_table <- bind_rows(
  master_gold_iron_quarterly %>%
    distinct(Period, Indicator, Publication_Quarter, Dispersion_SD, Dispersion_IQR, Dispersion_CV) %>%
    group_by(Indicator) %>%
    summarise(
      Measure = "Quarterly",
      SD_Mean = mean(Dispersion_SD, na.rm = TRUE),
      SD_Median = median(Dispersion_SD, na.rm = TRUE),
      IQR_Mean = mean(Dispersion_IQR, na.rm = TRUE),
      IQR_Median = median(Dispersion_IQR, na.rm = TRUE),
      CV_Mean = mean(Dispersion_CV, na.rm = TRUE),
      CV_Median = median(Dispersion_CV, na.rm = TRUE),
      .groups = "drop"
    ),
  
  master_gold_iron_annually %>%
    distinct(Period, Indicator, Publication_Quarter, Dispersion_SD, Dispersion_IQR, Dispersion_CV) %>%
    group_by(Indicator) %>%
    summarise(
      Measure = "Annual",
      SD_Mean = mean(Dispersion_SD, na.rm = TRUE),
      SD_Median = median(Dispersion_SD, na.rm = TRUE),
      IQR_Mean = mean(Dispersion_IQR, na.rm = TRUE),
      IQR_Median = median(Dispersion_IQR, na.rm = TRUE),
      CV_Mean = mean(Dispersion_CV, na.rm = TRUE),
      CV_Median = median(Dispersion_CV, na.rm = TRUE),
      .groups = "drop"
    )
)

# View the table
comparison_table
kable(comparison_table, digits = 2)
comparison_table %>%
  kbl() %>%
  kable_styling()

#Adjusted Dispersion variable
# Add adjusted dispersion to quarterly
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  mutate(
    Dispersion_CV_Adjusted = Dispersion_CV / Difficulty_Penalty_Normalized
  )

# Add adjusted dispersion to annual
master_gold_iron_annually <- master_gold_iron_annually %>%
  mutate(
    Dispersion_CV_Adjusted = Dispersion_CV / Difficulty_Penalty_Normalized
  )

#variable Lagged Dispersion
# For quarterly - lag by one period within each commodity
master_gold_iron_quarterly <- master_gold_iron_quarterly %>%
  arrange(Indicator, Period) %>%
  group_by(Indicator) %>%
  mutate(
    Lagged_Dispersion_CV = lag(Dispersion_CV, n = 1)
  ) %>%
  ungroup()

# For annual - lag by one year
master_gold_iron_annually <- master_gold_iron_annually %>%
  arrange(Indicator, Period) %>%
  group_by(Indicator) %>%
  mutate(
    Lagged_Dispersion_CV = lag(Dispersion_CV, n = 1)
  ) %>%
  ungroup()

#Dataset
set.seed(123)
master_gold_iron_annually %>%
  slice_sample(n = 10) %>%
  kbl() %>%
  kable_styling()

#Set working directory
setwd("C:/PATH")
# Save as CSV files
write.csv(master_gold_iron_quarterly, 
          "master_gold_iron_quarterly_staging.csv", 
          row.names = FALSE)

write.csv(master_gold_iron_annually, 
          "master_gold_iron_annually_staging.csv", 
          row.names = FALSE)

# Optional: Save as RDS (R's native format - faster and preserves data types)
saveRDS(master_gold_iron_quarterly, "master_gold_iron_quarterly_staging.rds")
saveRDS(master_gold_iron_annually, "master_gold_iron_annually_staging.rds")

