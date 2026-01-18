library(kableExtra)

setwd("C:/PATH")

# Create comparison table
sample_comparison <- data.frame(
  Commodity = rep(c("Gold", "Iron Ore"), each = 2),
  Sample = rep(c("Full Sample (All Forecasters)", "Balanced Panel (Top 6)"), 2),
  N_Forecasters = c("15-25", "6", "12-20", "6"),
  Mean_CV = c(14.3, 5.8, 22.0, 11.1),
  Max_CV = c(63.4, 13.1, 73.4, 22.3),
  CV_2024_2025 = c(20.5, 7.5, 29.1, 15.0)  # Approximate from your data
)

table_7_4 <- sample_comparison %>%
  kbl(digits = 1,
      caption = "Table: Comparison of Full Sample vs. Balanced Panel Dispersion",
      col.names = c("Commodity", "Sample", "N Forecasters", 
                    "Mean CV (%)", "Max CV (%)", "2024-25 Mean CV (%)"),
      booktabs = TRUE,
      align = c("l", "l", "c", "r", "r", "r")) %>%
  kable_styling(full_width = FALSE, position = "center") %>%
  row_spec(0, bold = TRUE) %>%
  pack_rows("Gold", 1, 2) %>%
  pack_rows("Iron Ore", 3, 4) %>%
  footnote(general = "Full sample includes all forecasters with at least 3 observations per period. 
           Balanced panel restricted to top 6 forecasters per commodity based on total forecast contributions.",
           general_title = "Note:",
           footnote_as_chunk = TRUE)


table_7_4 %>%
  save_kable("C:/Users/jsaar/OneDrive/Masterarbeit/Data/tables_and_plots/table_7_4_sample_comparison.png",
             zoom = 3, density = 300)

