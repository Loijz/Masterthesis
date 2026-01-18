#Set working directory

setwd("C:/PATH")
#Load packages
library(readxl)
library(plotmo)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(lubridate)
library(zoo)
library(knitr)
library(kableExtra)
library(glmnet)
library(reshape2)


###Load staged data###


# Load drom RDS
master_gold_iron_quarterly <- readRDS("master_gold_iron_quarterly_staging.rds")
master_gold_iron_annually <- readRDS("master_gold_iron_annually_staging.rds")


#### Prepare the Modeling Data ####


# Create modeling dataset - only rows with realized prices
model_data_quarterly <- master_gold_iron_quarterly %>%
  filter(Has_Realized == TRUE) %>%
  # Remove rows with any missing values in key variables
  filter(!is.na(Dispersion_CV), 
         !is.na(Time_Horizon_Months),
         !is.na(Difficulty_Penalty_Normalized),
         !is.na(Rolling_Volatility_3m),
         !is.na(N_Forecasters),
         !is.na(Lagged_Dispersion_CV)) %>%
  # Create a numeric time variable (years since start)
  mutate(
    Year = year(Period),
    Time_Numeric = Year - min(Year)
  )

# Same for annual
model_data_annually <- master_gold_iron_annually %>%
  filter(Has_Realized == TRUE) %>%
  filter(!is.na(Dispersion_CV), 
         !is.na(Time_Horizon_Months),
         !is.na(Difficulty_Penalty_Normalized),
         !is.na(Rolling_Volatility_3y),
         !is.na(N_Forecasters),
         !is.na(Lagged_Dispersion_CV)) %>%
  mutate(
    Year = year(Period),
    Time_Numeric = Year - min(Year)
  )

# Check sample sizes
nrow(model_data_quarterly)
nrow(model_data_annually)

head(model_data_annually)

#### Prepare Features and Targets ####
# For quarterly data
# Create design matrix (X) - predictor variables
X_quarterly <- model_data_quarterly %>%
  select(Time_Numeric, 
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters,
         Lagged_Dispersion_CV) %>%
  as.matrix()

# Target variable (y)
y_quarterly <- model_data_quarterly$Dispersion_CV

# For annual data
X_annually <- model_data_annually %>%
  select(Time_Numeric,
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3y,
         N_Forecasters,
         Lagged_Dispersion_CV) %>%
  as.matrix()

y_annually <- model_data_annually$Dispersion_CV

#### Fit Elastic Net with Cross-Validation
# Set seed for reproducibility
set.seed(62)

# Elastic Net for quarterly (alpha = 0.5 balances Ridge and Lasso)
# cv.glmnet performs cross-validation to find optimal lambda
#cv.glmnet performs regularization of variables
elastic_quarterly <- cv.glmnet(
  x = X_quarterly,
  y = y_quarterly,
  alpha = 0.5,  # 0.5 = elastic net (0 = ridge, 1 = lasso)
  nfolds = 10,
  standardize = TRUE  # Standardize predictors
)

# Elastic Net for annual
elastic_annually <- cv.glmnet(
  x = X_annually,
  y = y_annually,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

# View cross-validation plot
plot(elastic_quarterly, main = "Quarterly Elastic Net CV")
plot(elastic_annually, main = "Annual Elastic Net CV")


#### Extract and Interpret Coefficients ####
# Get coefficients at optimal lambda
coef_quarterly <- coef(elastic_quarterly, s = "lambda.min")
coef_annually <- coef(elastic_annually, s = "lambda.min")

# View coefficients
print("Quarterly Coefficients:")
print(coef_quarterly)

print("Annual Coefficients:")
print(coef_annually)

# Create a nice summary table
quarterly_results <- data.frame(
  Variable = rownames(coef_quarterly),
  Coefficient = as.numeric(coef_quarterly)
) %>%
  filter(Variable != "(Intercept)")

annually_results <- data.frame(
  Variable = rownames(coef_annually),
  Coefficient = as.numeric(coef_annually)
) %>%
  filter(Variable != "(Intercept)")

print(quarterly_results)
print(annually_results)

quarterly_results %>%
  kbl() %>%
  kable_styling(bootstrap_options = "striped", full_width = F)

annually_results %>%
  kbl() %>%
  kable_styling(bootstrap_options = "striped", full_width = F)

# Plot coefficient paths for quarterly
plot(elastic_quarterly$glmnet.fit, xvar = "lambda", label = TRUE, main = "Quarterly: Coefficient Paths")
abline(v = log(elastic_quarterly$lambda.min), lty = 2, col = "red")

# Add legend with variable names
legend("topright", 
       legend = c("1: Time_Numeric",
                  "2: Time_Horizon_Months", 
                  "3: Difficulty_Penalty_Normalized",
                  "4: Rolling_Volatility_3m",
                  "5: N_Forecasters",
                  "6: Lagged_Dispersion_CV"),
       lty = 1,
       col = 1:6,
       cex = 0.7,
       bg = "white")

# Same for annual
plot(elastic_annually$glmnet.fit, xvar = "lambda", label = TRUE, main = "Annual: Coefficient Paths")
abline(v = log(elastic_annually$lambda.min), lty = 2, col = "red")

legend("topright", 
       legend = c("1: Time_Numeric",
                  "2: Time_Horizon_Months", 
                  "3: Difficulty_Penalty_Normalized",
                  "4: Rolling_Volatility_3y",
                  "5: N_Forecasters",
                  "6: Lagged_Dispersion_CV"),
       lty = 1,
       col = 1:6,
       cex = 0.7,
       bg = "white")

# Get variable names in the correct order from the model
var_names <- rownames(coef(elastic_quarterly))[-1]  # Remove intercept

# Plot with better labeling
plot(elastic_quarterly$glmnet.fit, xvar = "lambda", label = TRUE, 
     main = "Quarterly: Coefficient Paths")
abline(v = log(elastic_quarterly$lambda.min), lty = 2, col = "red")

# Print the variable order to console
print("Variable numbers in plot correspond to:")
print(data.frame(Number = 1:length(var_names), Variable = var_names))

# Or use a different visualization with actual names

plot_glmnet(elastic_quarterly$glmnet.fit, label = 5, 
            s = elastic_quarterly$lambda.min,
            main = "Quarterly: Coefficient Paths")

# Extract coefficients at different lambdas
coef_path <- as.matrix(coef(elastic_quarterly$glmnet.fit))

# Create a data frame for plotting
coef_df <- as.data.frame(t(coef_path[-1, ]))  # Remove intercept
coef_df$lambda <- elastic_quarterly$glmnet.fit$lambda
coef_long <- melt(coef_df, id.vars = "lambda")

# Plot with ggplot for clear variable names
ggplot(coef_long, aes(x = log(lambda), y = value, color = variable)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = log(elastic_quarterly$lambda.min), 
             linetype = "dashed", color = "red") +
  labs(title = "Quarterly: Coefficient Paths",
       x = "Log(Lambda)",
       y = "Coefficients",
       color = "Variable") +
  theme_minimal()

# Extract coefficients for annual model
coef_path_annual <- as.matrix(coef(elastic_annually$glmnet.fit))

# Create data frame
coef_df_annual <- as.data.frame(t(coef_path_annual[-1, ]))
coef_df_annual$lambda <- elastic_annually$glmnet.fit$lambda
coef_long_annual <- melt(coef_df_annual, id.vars = "lambda")

# Plot for annual
ggplot(coef_long_annual, aes(x = log(lambda), y = value, color = variable)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = log(elastic_annually$lambda.min), 
             linetype = "dashed", color = "red") +
  labs(title = "Annual: Coefficient Paths",
       x = "Log(Lambda)",
       y = "Coefficients",
       color = "Variable") +
  theme_minimal()

######### No lagged dispersion approach ############
# Prepare data WITHOUT lagged dispersion
X_quarterly_no_lag <- model_data_quarterly %>%
  select(Time_Numeric, 
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters) %>%  # Removed Lagged_Dispersion_CV
  as.matrix()

X_annually_no_lag <- model_data_annually %>%
  select(Time_Numeric,
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3y,
         N_Forecasters) %>%  # Removed Lagged_Dispersion_CV
  as.matrix()

# Fit elastic net models
set.seed(666)

elastic_quarterly_no_lag <- cv.glmnet(
  x = X_quarterly_no_lag,
  y = y_quarterly,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

elastic_annually_no_lag <- cv.glmnet(
  x = X_annually_no_lag,
  y = y_annually,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

# View CV plots
plot(elastic_quarterly_no_lag, main = "Quarterly (No Lag) Elastic Net CV")
plot(elastic_annually_no_lag, main = "Annual (No Lag) Elastic Net CV")

# Extract coefficients
coef_quarterly_no_lag <- coef(elastic_quarterly_no_lag, s = "lambda.min")
coef_annually_no_lag <- coef(elastic_annually_no_lag, s = "lambda.min")

# Summary
quarterly_no_lag_results <- data.frame(
  Variable = rownames(coef_quarterly_no_lag),
  Coefficient = as.numeric(coef_quarterly_no_lag)
) %>%
  filter(Variable != "(Intercept)")

annually_no_lag_results <- data.frame(
  Variable = rownames(coef_annually_no_lag),
  Coefficient = as.numeric(coef_annually_no_lag)
) %>%
  filter(Variable != "(Intercept)")

print("Quarterly (No Lag):")
print(quarterly_no_lag_results)

print("Annual (No Lag):")
print(annually_no_lag_results)

### Coefficient Path Plot ###
# Quarterly coefficient paths (no lag)
coef_path_q_no_lag <- as.matrix(coef(elastic_quarterly_no_lag$glmnet.fit))
coef_df_q_no_lag <- as.data.frame(t(coef_path_q_no_lag[-1, ]))
coef_df_q_no_lag$lambda <- elastic_quarterly_no_lag$glmnet.fit$lambda
coef_long_q_no_lag <- melt(coef_df_q_no_lag, id.vars = "lambda")

ggplot(coef_long_q_no_lag, aes(x = log(lambda), y = value, color = variable)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = log(elastic_quarterly_no_lag$lambda.min), 
             linetype = "dashed", color = "red") +
  labs(title = "Quarterly (No Lagged Dispersion): Coefficient Paths",
       x = "Log(Lambda)",
       y = "Coefficients",
       color = "Variable") +
  theme_minimal()

# Annual coefficient paths (no lag)
coef_path_a_no_lag <- as.matrix(coef(elastic_annually_no_lag$glmnet.fit))
coef_df_a_no_lag <- as.data.frame(t(coef_path_a_no_lag[-1, ]))
coef_df_a_no_lag$lambda <- elastic_annually_no_lag$glmnet.fit$lambda
coef_long_a_no_lag <- melt(coef_df_a_no_lag, id.vars = "lambda")

ggplot(coef_long_a_no_lag, aes(x = log(lambda), y = value, color = variable)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = log(elastic_annually_no_lag$lambda.min), 
             linetype = "dashed", color = "red") +
  labs(title = "Annual (No Lagged Dispersion): Coefficient Paths",
       x = "Log(Lambda)",
       y = "Coefficients",
       color = "Variable") +
  theme_minimal()

### Model Fit Comparison ###
# Compare R-squared between models
# With lagged dispersion
pred_with_lag_q <- predict(elastic_quarterly, newx = X_quarterly, s = "lambda.min")
r2_with_lag_q <- cor(y_quarterly, pred_with_lag_q)^2

# Without lagged dispersion
pred_no_lag_q <- predict(elastic_quarterly_no_lag, newx = X_quarterly_no_lag, s = "lambda.min")
r2_no_lag_q <- cor(y_quarterly, pred_no_lag_q)^2

print(paste("Quarterly R² WITH lagged dispersion:", round(r2_with_lag_q, 3)))
print(paste("Quarterly R² WITHOUT lagged dispersion:", round(r2_no_lag_q, 3)))

### Difficulty vs Dispersion ###
# Scatter plot: Difficulty vs Dispersion
disp_fig <- model_data_quarterly %>%
  distinct(Period, Indicator, Publication_Quarter, Dispersion_CV, Difficulty_Penalty_Normalized) %>%
  ggplot(aes(x = Difficulty_Penalty_Normalized, y = Dispersion_CV, color = Indicator)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE) +
  facet_wrap(~Indicator, scales = "free") +
  labs(title = "Difficulty vs Dispersion",
       x = "Difficulty Penalty (Normalized)",
       y = "Dispersion (CV %)") +
  theme_minimal()

ggsave("fig_difficulty_dispersion.png", 
       plot = disp_fig,
       width = 10, 
       height = 6, 
       dpi = 300,
       bg = "white")


# Check correlation
model_data_quarterly %>%
  distinct(Period, Indicator, Publication_Quarter, Dispersion_CV, Difficulty_Penalty_Normalized) %>%
  group_by(Indicator) %>%
  summarise(correlation = cor(Difficulty_Penalty_Normalized, Dispersion_CV, use = "complete.obs"))


### Distribution of forecasters check as the main driver for dispersion ###
# Distribution of forecaster counts
fig_forecaster_count <- model_data_quarterly %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  ggplot(aes(x = N_Forecasters)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  facet_wrap(~Indicator) +
  labs(title = "Distribution of Forecaster Counts",
       x = "Number of Forecasters",
       y = "Count") +
  theme_minimal()

fig_forecaster_count

ggsave("fig_forecaster_count.png", 
       plot = fig_forecaster_count,
       width = 10, 
       height = 6, 
       dpi = 300,
       bg = "#FFFFFF")


# Summary stats
model_data_quarterly %>%
  distinct(Period, Indicator, Publication_Quarter, N_Forecasters) %>%
  group_by(Indicator) %>%
  summarise(
    min = min(N_Forecasters),
    q25 = quantile(N_Forecasters, 0.25),
    median = median(N_Forecasters),
    q75 = quantile(N_Forecasters, 0.75),
    max = max(N_Forecasters)
  )





### Top Forecasters ###
# Get top 6 forecasters per commodity (excluding FocusEconomics)
top_forecasters_by_commodity <- master_gold_iron_quarterly %>%
  filter(Source != "FocusEconomics") %>%
  group_by(Source, Indicator) %>%
  summarise(n_forecasts = n(), .groups = "drop") %>%
  group_by(Indicator) %>%
  slice_max(n_forecasts, n = 6) %>%
  ungroup()

# View them
print("Top 6 forecasters per commodity:")
print(top_forecasters_by_commodity)

# Extract the list of sources
top_forecasters <- top_forecasters_by_commodity$Source %>% unique()

print(paste("Total unique forecasters:", length(top_forecasters)))


#Table Top Forecasters
# Create the formatted table
table_forecasters <- top_forecasters_by_commodity %>%
  kbl(
    col.names = c("Forecaster", "Commodity", "Number of Forecasts"),
    caption = "Top Forecasters by Commodity",
    align = c("l", "c", "r"),
    format = "html"
  ) %>%
  kable_styling(
    bootstrap_options = c("striped", "hover"),
    full_width = FALSE,
    position = "center",
    font_size = 14
  ) %>%
  row_spec(0, bold = TRUE, color = "grey", background = "#FFFFFF", font_size = 16) %>%
  row_spec(1:6, background = "#FFFFFF") %>%  # Gold rows in light yellow
  row_spec(7:12, background = "#FFFFFF") %>%  # Iron Ore rows in light gray
  column_spec(1, bold = TRUE, width = "12em") %>%
  column_spec(2, width = "8em") %>%
  column_spec(3, width = "10em")


table_forecasters

# Save table_forecasters
table_forecasters %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_top_forecaster.png",
             zoom = 3, density = 300)






# Create balanced dataset containing only top forecaster
model_data_balanced <- master_gold_iron_quarterly %>%
  filter(Source %in% top_forecasters) %>%
  filter(Has_Realized == TRUE) %>%
  filter(!is.na(Dispersion_CV), 
         !is.na(Time_Horizon_Months),
         !is.na(Difficulty_Penalty_Normalized),
         !is.na(Rolling_Volatility_3m)) %>%
  mutate(
    Year = year(Period),
    Time_Numeric = Year - min(Year)
  )

# Recalculate dispersion for this balanced panel
dispersion_balanced <- model_data_balanced %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(
    Dispersion_CV_Balanced = sd(Value, na.rm = TRUE) / mean(Value, na.rm = TRUE) * 100,
    N_Forecasters_Balanced = n_distinct(Source),
    Mean_Forecast = mean(Value, na.rm = TRUE),
    .groups = "drop"
  )

# Check sample size
nrow(model_data_balanced)

# Check forecaster distribution
model_data_balanced %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(n_forecasters = n_distinct(Source), .groups = "drop") %>%
  summary()

# Sample size and forecaster distribution
print(paste("Total observations in balanced dataset:", nrow(model_data_balanced)))

# Check how many forecasters per group
forecaster_distribution <- model_data_balanced %>%
  group_by(Period, Indicator, Publication_Quarter) %>%
  summarise(n_forecasters = n_distinct(Source), .groups = "drop")

summary(forecaster_distribution$n_forecasters)

# Visualize
forecaster_distribution %>%
  ggplot(aes(x = n_forecasters)) +
  geom_histogram(binwidth = 1, fill = "steelblue") +
  facet_wrap(~Indicator) +
  labs(title = "Distribution of Forecasters per Group (Balanced Panel)",
       x = "Number of Forecasters",
       y = "Count") +
  theme_minimal()

# Check dispersion calculation worked
head(dispersion_balanced, 10)
summary(dispersion_balanced$Dispersion_CV_Balanced)



### Check with balanced sheet only ###
# Merge dispersion back to the balanced data
model_data_balanced <- model_data_balanced %>%
  left_join(
    dispersion_balanced %>% select(Period, Indicator, Publication_Quarter, Dispersion_CV_Balanced, N_Forecasters_Balanced),
    by = c("Period", "Indicator", "Publication_Quarter")
  )

# Prepare features (without lagged dispersion for now)
X_balanced <- model_data_balanced %>%
  distinct(Period, Indicator, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced),
         !is.na(Rolling_Volatility_3m)) %>%
  select(Time_Numeric, 
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

y_balanced <- model_data_balanced %>%
  distinct(Period, Indicator, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced),
         !is.na(Rolling_Volatility_3m)) %>%
  pull(Dispersion_CV_Balanced)

# Fit elastic net
set.seed(999)
elastic_balanced <- cv.glmnet(
  x = X_balanced,
  y = y_balanced,
  alpha = 0.5,
  nfolds = 10,
  standardize = TRUE
)

# View results
plot(elastic_balanced, main = "Balanced Panel: Elastic Net CV")

# Coefficients
coef_balanced <- coef(elastic_balanced, s = "lambda.min")
balanced_results <- data.frame(
  Variable = rownames(coef_balanced),
  Coefficient = as.numeric(coef_balanced)
) %>%
  filter(Variable != "(Intercept)")

print("Balanced Panel Coefficients:")
print(balanced_results)

# R-squared
pred_balanced <- predict(elastic_balanced, newx = X_balanced, s = "lambda.min")
r2_balanced <- cor(y_balanced, pred_balanced)^2
print(paste("Balanced Panel R²:", round(r2_balanced, 3)))


### Coefficicient Path Plot for Balanced Panel ###
# Create coefficient path plot
coef_path_balanced <- as.matrix(coef(elastic_balanced$glmnet.fit))
coef_df_balanced <- as.data.frame(t(coef_path_balanced[-1, ]))
coef_df_balanced$lambda <- elastic_balanced$glmnet.fit$lambda
coef_long_balanced <- melt(coef_df_balanced, id.vars = "lambda")

ggplot(coef_long_balanced, aes(x = log(lambda), y = value, color = variable)) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = log(elastic_balanced$lambda.min), 
             linetype = "dashed", color = "red") +
  labs(title = "Balanced Panel: Coefficient Paths",
       x = "Log(Lambda)",
       y = "Coefficients",
       color = "Variable") +
  theme_minimal()

### Summary Table ###
# Compare all models
comparison_summary <- data.frame(
  Model = c("Full Data (with lag)", "Full Data (no lag)", "Balanced Panel (no lag)"),
  Time_Coefficient = c(0.015, 0.589, 0.611),
  N_Forecasters = c(-0.017, -0.346, -0.760),
  Volatility = c(0.003, 0.246, 0.276),
  R_squared = c(0.955, 0.358, 0.222)
)

print(comparison_summary)

comparison_summary %>%
  kbl() %>%
  kable_styling(bootstrap_options = "striped", full_width = F)

# Scatter plot with forecasts over time (colored by forecaster)
disagreement_balanced <- model_data_balanced %>%
  ggplot(aes(x = Period, y = Value, color = Source)) +
  geom_point(alpha = 0.6, size = 1.5) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Forecast Distribution Over Time (Top 6 Forecasters per Commodity)",
       x = "Target Period",
       y = "Forecasted Price",
       color = "Forecaster") +
  theme_minimal() +
  theme(legend.position = "bottom")

disagreement_balanced  

ggsave("fig_disagreement_balanced.png", 
       plot = disagreement_balanced,
       width = 10, 
       height = 6, 
       dpi = 300,
       bg = "#FFFFFF")


# Show dispersion as boxplots per year
fig_box <- model_data_balanced %>%
  mutate(Year = year(Period)) %>%
  ggplot(aes(x = factor(Year), y = Value, fill = Indicator)) +
  geom_boxplot(alpha = 0.7) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Forecast Dispersion by Year (Boxplots)",
       x = "Year",
       y = "Forecasted Price") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")

fig_box

ggsave("fig_box.png", 
       plot = fig_box,
       width = 10, 
       height = 6, 
       dpi = 300,
       bg = "#FFFFFF")


# Violin plots to show distribution shape
model_data_balanced %>%
  mutate(Year = year(Period)) %>%
  filter(Year >= 2016) %>%  # Focus on recent years for clarity
  ggplot(aes(x = factor(Year), y = Value, fill = Indicator)) +
  geom_violin(alpha = 0.7, trim = FALSE) +
  geom_boxplot(width = 0.1, alpha = 0.5, outlier.shape = NA) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Forecast Distribution Shape Over Time",
       x = "Year",
       y = "Forecasted Price") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")



# Plot the actual CV dispersion measure over time
fig_disp <- dispersion_balanced %>%
  ggplot(aes(x = Period, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_line(alpha = 0.4) +
  geom_smooth(method = "loess", se = TRUE, linewidth = 1.5) +
  facet_wrap(~Indicator, ncol = 1) +
  labs(title = "Forecast Dispersion (CV) Over Time - Balanced Panel",
       subtitle = "Trend line shows dispersion is increasing",
       x = "Target Period",
       y = "Dispersion (CV %)") +
  theme_minimal() +
  theme(legend.position = "none")

fig_disp

ggsave("fig_disp.png", 
       plot = fig_disp,
       width = 10, 
       height = 6, 
       dpi = 300,
       bg = "#FFFFFF")

# Jittered scatter to see individual points better
model_data_balanced %>%
  filter(year(Period) >= 2020) %>%  # Focus on recent years
  ggplot(aes(x = Period, y = Value, color = Source)) +
  geom_jitter(alpha = 0.5, width = 5, height = 0) +
  geom_smooth(aes(group = 1), method = "lm", color = "black", se = FALSE, linetype = "dashed") +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Individual Forecasts 2020-2025 (Top Forecasters)",
       x = "Target Period",
       y = "Forecasted Price",
       color = "Forecaster") +
  theme_minimal() +
  theme(legend.position = "bottom")


# Filter to most recent forecast per forecaster per target
model_data_balanced_latest <- model_data_balanced %>%
  group_by(Source, Period, Indicator) %>%
  slice_max(PublicationDate, n = 1) %>%  # Keep only the latest forecast
  ungroup()

# Now plot with one point per forecaster per target
model_data_balanced_latest %>%
  ggplot(aes(x = Period, y = Value, color = Source)) +
  geom_point(alpha = 0.6, size = 2) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Latest Forecast per Forecaster (One per Target Period)",
       x = "Target Period",
       y = "Forecasted Price",
       color = "Forecaster") +
  theme_minimal() +
  theme(legend.position = "bottom")

###### Test for different kind of commodity usage commodity vs investment commodity #######
# Split data by commodity
model_data_gold <- model_data_balanced %>%
  filter(Indicator == "Gold") %>%
  distinct(Period, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced), !is.na(Rolling_Volatility_3m))

model_data_iron <- model_data_balanced %>%
  filter(Indicator == "Iron Ore") %>%
  distinct(Period, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced), !is.na(Rolling_Volatility_3m))

# Prepare matrices
X_gold <- model_data_gold %>%
  select(Time_Numeric, Time_Horizon_Months, Difficulty_Penalty_Normalized, 
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()

y_gold <- model_data_gold$Dispersion_CV_Balanced

X_iron <- model_data_iron %>%
  select(Time_Numeric, Time_Horizon_Months, Difficulty_Penalty_Normalized, 
         Rolling_Volatility_3m, N_Forecasters_Balanced) %>%
  as.matrix()

y_iron <- model_data_iron$Dispersion_CV_Balanced

# Fit separate models
set.seed(123)

elastic_gold <- cv.glmnet(x = X_gold, y = y_gold, alpha = 0.5, nfolds = 10, standardize = TRUE)
elastic_iron <- cv.glmnet(x = X_iron, y = y_iron, alpha = 0.5, nfolds = 10, standardize = TRUE)

# Compare coefficients
coef_gold <- data.frame(
  Variable = rownames(coef(elastic_gold, s = "lambda.min")),
  Gold_Coefficient = as.numeric(coef(elastic_gold, s = "lambda.min"))
) %>% filter(Variable != "(Intercept)")

coef_iron <- data.frame(
  Variable = rownames(coef(elastic_iron, s = "lambda.min")),
  Iron_Coefficient = as.numeric(coef(elastic_iron, s = "lambda.min"))
) %>% filter(Variable != "(Intercept)")

# Merge for comparison
commodity_comparison <- coef_gold %>%
  left_join(coef_iron, by = "Variable")

print("Coefficient Comparison by Commodity:")
print(commodity_comparison)

### Visualisation ###
# Focus on 2020-2025 period trends
dispersion_recent <- dispersion_balanced %>%
  filter(Period >= as.Date("2020-01-01"))

# Separate linear models for recent period
dispersion_recent %>%
  mutate(Year_Numeric = as.numeric(year(Period)) - 2020) %>%
  group_by(Indicator) %>%
  do(model = lm(Dispersion_CV_Balanced ~ Year_Numeric, data = .)) %>%
  summarise(
    Indicator = Indicator,
    Time_Coefficient = coef(model)[2],
    R_squared = summary(model)$r.squared
  )

# Visualize with linear trend lines for recent period
dispersion_recent %>%
  ggplot(aes(x = Period, y = Dispersion_CV_Balanced, color = Indicator)) +
  geom_point(alpha = 0.4) +
  geom_smooth(method = "lm", se = TRUE, linewidth = 1.5) +
  facet_wrap(~Indicator, scales = "free_y", ncol = 1) +
  labs(title = "Dispersion Trends 2020-2025 (Linear Fit)",
       x = "Period",
       y = "Dispersion CV %") +
  theme_minimal() +
  theme(legend.position = "none")

# Compare pre/post 2022 trends
dispersion_balanced %>%
  mutate(
    Year = year(Period),
    Period_Group = ifelse(Year < 2022, "Pre-2022", "Post-2022")
  ) %>%
  group_by(Indicator, Period_Group) %>%
  summarise(
    Mean_Dispersion = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SD_Dispersion = sd(Dispersion_CV_Balanced, na.rm = TRUE),
    .groups = "drop"
  )


dispersion_balanced %>%
  mutate(Year = year(Period)) %>%
  group_by(Year, Indicator) %>%
  summarise(
    Mean_Dispersion = mean(Dispersion_CV_Balanced, na.rm = TRUE),
    SE = sd(Dispersion_CV_Balanced, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = Year, y = Mean_Dispersion, color = Indicator, fill = Indicator)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_ribbon(aes(ymin = Mean_Dispersion - SE, ymax = Mean_Dispersion + SE), 
              alpha = 0.2, color = NA) +
  geom_vline(xintercept = 2022, linetype = "dashed", alpha = 0.5) +
  annotate("text", x = 2022, y = 15, label = "2022", size = 3) +
  scale_color_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  scale_fill_manual(values = c("Gold" = "gold4", "Iron Ore" = "darkgrey")) +
  labs(title = "Average Forecast Dispersion by Year",
       subtitle = "Balanced panel of top 6 forecasters per commodity",
       x = "Year",
       y = "Mean Dispersion (CV %)",
       color = "Commodity",
       fill = "Commodity") +
  theme_minimal() +
  theme(legend.position = "bottom")


#### Descriptive Statistics ####
# Create summary table for paper
summary_table <- bind_rows(
  model_data_balanced %>%
    group_by(Indicator) %>%
    summarise(
      Dataset = "Balanced Panel",
      N_Observations = n(),
      N_Forecasters = n_distinct(Source),
      Mean_Forecast = mean(Value, na.rm = TRUE),
      SD_Forecast = sd(Value, na.rm = TRUE),
      .groups = "drop"
    ),
  
  dispersion_balanced %>%
    group_by(Indicator) %>%
    summarise(
      Dataset = "Dispersion Measures",
      Mean_CV = mean(Dispersion_CV_Balanced, na.rm = TRUE),
      Median_CV = median(Dispersion_CV_Balanced, na.rm = TRUE),
      Min_CV = min(Dispersion_CV_Balanced, na.rm = TRUE),
      Max_CV = max(Dispersion_CV_Balanced, na.rm = TRUE),
      .groups = "drop"
    )
)

# Export for paper
write.csv(summary_table, "table1_descriptive_stats.csv", row.names = FALSE)



#### Elastic Net Regression Results ####
# Create regression results table
regression_results <- data.frame(
  Variable = c("Time (years)", "Time Horizon (months)", 
               "Difficulty Penalty", "Rolling Volatility", 
               "N Forecasters"),
  
  `Full Panel` = c(0.611, 0.002, 0.000, 0.276, -0.760),
  `Gold Only` = c(0.017, 0.130, 1.026, -0.149, 0.249),
  `Iron Ore Only` = c(0.120, 0.036, 2.729, 0.131, 1.036)
)



kbl(regression_results, 
      digits = 3,
      caption = "Elastic Net Coefficients (α = 0.5)",
      col.names = c("Variable", "Full Panel", "Gold", "Iron Ore")) %>%
  kable_styling(bootstrap_options = "striped", full_width = F)


#### Robustness Checks ####
# Compare model specifications
robustness_table <- data.frame(
  Model = c("With Lagged Dispersion", 
            "Without Lagged Dispersion",
            "Balanced Panel (Top 6)",
            "Gold Only",
            "Iron Ore Only"),
  
  N = c(nrow(model_data_quarterly),
        nrow(model_data_quarterly),
        nrow(model_data_balanced),
        sum(model_data_balanced$Indicator == "Gold"),
        sum(model_data_balanced$Indicator == "Iron Ore")),
  
  R_squared = c(0.955, 0.358, 0.222, NA, NA),
  
  Time_Coefficient = c(0.015, 0.589, 0.611, 0.017, 0.120)
)

write.csv(robustness_table, "table3_robustness.csv", row.names = FALSE)

# Export
ggsave("fig1_dispersion_trends.png", width = 10, height = 6, dpi = 300)
ggsave("fig2_coefficient_paths.png", width = 10, height = 6, dpi = 300)
ggsave("fig3_difficulty_penalty.png", width = 10, height = 6, dpi = 300)


# saveRDS
saveRDS(model_data_balanced, "model_data_balanced.rds")

