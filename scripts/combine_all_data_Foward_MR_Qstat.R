# Loading required packages
library(ggplot2)
library(dplyr)
library(grid)
library(metafor)

# Load the results for each ancestry into separate data frames

# European ancestry (EUR)
load(file.path("results", "eur_modified_Forward_MR.rdata"))
eur <- res
eur$pop <- "EUR"  # Add a column indicating population

# African ancestry (AFR)
load(file.path("results", "afr_modified_Forward_MR.rdata"))
afr <- res
afr$pop <- "AFR"

# Central South Asian ancestry (CSA-SAS)
load(file.path("results", "csa_sas_modified_Foward_MR.rdata"))
csa_sas <- res
csa_sas$pop <- "CSA-SAS"

# East Asian ancestry (EAS)
load(file.path("results", "eas_modified_Forward_MR.rdata"))
eas <- res
eas$pop <- "EAS"

# Combine all ancestry results into a single data frame
res_comb <- bind_rows(eur, eas, afr, csa_sas)

# Display the first few rows of the combined results
head(res_comb)

# Compute the number of rows (i.e., studies) for each exposure
df_value <- dplyr::summarise(dplyr::group_by(res_comb, exposure), df = dplyr::n())
df_value

# Join the main results with the computed df values based on the exposure
joined_data <- res_comb %>%
  dplyr::left_join(df_value, by = "exposure")

print(head(joined_data))

# Compute Cochran's Q statistic
results <- joined_data %>%
  dplyr::group_by(exposure) %>%
  dplyr::mutate(
    #q_stat = sum((b / se)^2) - (sum(b / se^2)^2 / sum(1 / se^2)),#Q statistic not sure which formula is correct.
    q_stat = sum(((b - mean(b))^2) / (se^2)),
    qpval = pchisq(q_stat, df - 1, lower.tail = FALSE)#P value
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(exposure, q_stat, qpval) %>%
  distinct()

results <- joined_data %>%
  dplyr::group_by(exposure) %>%
  dplyr::mutate(
    q_stat = sum(((b - mean(b))^2) / (se^2)),
    qpval = pchisq(q_stat, df - 1, lower.tail = FALSE)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(exposure, q_stat, qpval) %>%
  distinct()



print(head(results))

# Categorize the significance of the Q statistic based on its p-value
results$significance <- case_when(
  results$qpval < 0.05  ~ "Significant",
  TRUE                  ~ "Not Significant"
)

# Join the main data with the significance results
res_comb <- left_join(res_comb, results, by = "exposure")

# Create background data to color facets based on significance
background_data <- res_comb %>%
  dplyr::select(exposure, significance) %>%
  distinct()

# Visualizing the results with ggplot2

ggplot(res_comb, aes(y=pop, x=b, color=pop)) +
  # Colored facet backgrounds
  geom_rect(data=background_data, inherit.aes=FALSE,
            aes(xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf, fill=significance),
            alpha = 0.5) +
  # Main plot points
  geom_point() +
  # Horizontal error bars
  geom_errorbarh(aes(xmin=b-se*1.96, xmax=b+se*1.96)) +
  # Dashed vertical line at x=0
  geom_vline(xintercept=0, linetype="dashed") +
  # Plot labels and title
  labs(title = "Combined forest plot of potential MDD drug targets across ancestry",
       x = "beta_IV (logodds ratio per SD)",
       y = "Proteins") +
  # Separate plot for each exposure
  facet_grid(exposure ~ .) +
  # Define colors for significance
  scale_fill_manual(values = c("Significant" = "green", "Not Significant" = "yellow"),
                    name = "Heterogeneity") +
  # Apply a clean theme and customize
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    axis.text.y=element_blank(),
    strip.text.y=element_text(angle=0),
    legend.position = "bottom"
  )

#########Plot 1 (divided facets) 
ggplot(data=res_comb, aes(x=pop, y=b, color=pop)) +
  
  # Colored facet backgrounds
  geom_rect(data=background_data, inherit.aes=FALSE,
            aes(xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf, fill=significance),
            alpha = 0.5) +
  
  # Main plot points with error bars
  geom_pointrange(aes(ymin=b-se*1.96, ymax=b+se*1.96)) +
  
  # Dashed horizontal line at y=0
  geom_hline(yintercept=0, linetype="dashed") +
  
  # X and Y labels
  xlab('Proteins') + ylab("beta_IV (logodds ratio per SD)") +
  
  # Separate plot for each exposure using facet_grid
  facet_grid(exposure ~ ., scales="free_y") + 
  
  # Plot title
  labs(title = "Combined forest plot of potential MDD drug targets across ancestry") +
  
  # Define colors for significance
  scale_fill_manual(values = c("Significant" = "green", "Not Significant" = "yellow"),
                    name = "Heterogeneity") +
  
  # Apply a clean theme and customize
  theme(
    plot.title = element_text(size=16, face="bold", hjust = 0.5),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(face="bold"),
    axis.title = element_text(size=12, face="bold"),
    strip.text.y = element_text(angle=0, face="bold"),
    legend.position = "bottom"
  ) +
  
  # Flip coordinates to match the orientation
  coord_flip()
