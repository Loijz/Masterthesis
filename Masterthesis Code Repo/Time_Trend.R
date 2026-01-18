library(glmnet)
library(dplyr)

setwd("C:/PATH")


base_data <- model_data_balanced %>%
  distinct(Period, Indicator, Publication_Quarter, .keep_all = TRUE) %>%
  filter(!is.na(Dispersion_CV_Balanced), 
         !is.na(Rolling_Volatility_3m),
         !is.na(Time_Numeric),
         !is.na(Time_Horizon_Months),
         !is.na(Difficulty_Penalty_Normalized),
         !is.na(N_Forecasters_Balanced))

# dimensions check
cat("Base data rows:", nrow(base_data), "\n")

#  x-matrices creation
X_no_time <- base_data %>%
  select(Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

X_with_time <- base_data %>%
  select(Time_Numeric,
         Time_Horizon_Months,
         Difficulty_Penalty_Normalized,
         Rolling_Volatility_3m,
         N_Forecasters_Balanced) %>%
  as.matrix()

# Create y from the SAME base_data
y_balanced <- base_data$Dispersion_CV_Balanced

# dimensions match check
cat("\n=== DIMENSION CHECK ===\n")
cat("X_no_time rows:", nrow(X_no_time), "\n")
cat("X_with_time rows:", nrow(X_with_time), "\n")
cat("y_balanced length:", length(y_balanced), "\n")


if(nrow(X_no_time) == nrow(X_with_time) && nrow(X_no_time) == length(y_balanced)) {
  cat("\n✓ Dimensions match! Proceeding with models...\n\n")
  
  # Fit the models
  set.seed(123)
  
  elastic_no_time <- cv.glmnet(
    x = X_no_time,
    y = y_balanced,
    alpha = 0.5,
    nfolds = 10,
    standardize = TRUE
  )
  
  elastic_with_time <- cv.glmnet(
    x = X_with_time,
    y = y_balanced,
    alpha = 0.5,
    nfolds = 10,
    standardize = TRUE
  )
  
  #  results
  cat("=== MODEL 1: WITHOUT TIME TREND ===\n")
  print(coef(elastic_no_time, s = "lambda.min"))
  
  cat("\n=== MODEL 2: WITH TIME TREND ===\n")
  print(coef(elastic_with_time, s = "lambda.min"))
  
  # Calculate R2
  pred_no_time <- predict(elastic_no_time, newx = X_no_time, s = "lambda.min")
  r2_no_time <- cor(y_balanced, pred_no_time)^2
  
  pred_with_time <- predict(elastic_with_time, newx = X_with_time, s = "lambda.min")
  r2_with_time <- cor(y_balanced, pred_with_time)^2
  
  cat("\n=== MODEL FIT ===\n")
  cat("R² without time trend:", round(r2_no_time, 3), "\n")
  cat("R² with time trend:", round(r2_with_time, 3), "\n")
  cat("Difference:", round(r2_with_time - r2_no_time, 3), "\n")
  

  saveRDS(base_data, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/base_data.rds")
  saveRDS(X_no_time, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/X_no_time.rds")
  saveRDS(X_with_time, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/X_with_time.rds")
  saveRDS(y_balanced, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/y_balanced.rds")
  saveRDS(elastic_no_time, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/elastic_no_time.rds")
  saveRDS(elastic_with_time, "C:/Users/jsaar/OneDrive/Masterarbeit/Data/Ridge-Lasso/elastic_with_time.rds")
  
  cat("\n✓ Models saved successfully!\n")
  
} else {
  cat("\n✗ ERROR: Dimensions don't match!\n")
  cat("Check your data filtering steps.\n")
}

