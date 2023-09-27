library(ggplot2)
library(dplyr)
library(grid)


#load the results for all ancestries into one data frame
#european ancenstry(eur)
load(file.path("C:/Users/HP OMEN GAMING/Desktop/mr-uganda-hackathon-2023-6/results", "eur_modified_Forward_MR.rdata"))
eur <- res
eur$pop <- "EUR"

#african ancestry(afr)
load(file.path("C:/Users/HP OMEN GAMING/Desktop/mr-uganda-hackathon-2023-6/results", "afr_modified_Forward_MR.rdata"))
afr<- res
afr$pop <- "AFR"

#central south asian ancestry(csa)
load(file.path("C:/Users/HP OMEN GAMING/Desktop/mr-uganda-hackathon-2023-6/results", "csa_sas_modified_Foward_MR.rdata"))
csa_sas<- res
csa_sas$pop <- "CSA-SAS"

#east asian ancestry(eas)
load(file.path("C:/Users/HP OMEN GAMING/Desktop/mr-uganda-hackathon-2023-6/results", "eas_modified_Forward_MR.rdata"))
eas<- res
eas$pop <- "EAS"

#combine all data frames 

res_comb <- bind_rows(eur,eas,afr, csa_sas)

head(res_comb)
View(res_comb)

#plot results of combined data

ggplot(res_comb, aes(y=pop, x=b, color=pop)) +
  geom_point() +
  geom_errorbarh(aes(xmin=b-se*1.96, xmax=b+se*1.96)) +
  geom_vline(xintercept=0, linetype="dashed") +
  labs(title = "Combined forest plot of potential MDD drug targets across ancestry",
       x = "beta_IV (logodds ratio per SD)",
       y = "Proteins") +
  facet_grid(exposure ~ .)+
  theme_minimal() +  # Apply a minimal theme
  theme(
    plot.title = element_text(hjust = 0.5), # Center the plot title
    axis.text.y=element_blank(), # remove y axis text
    strip.text.y=element_text(angle=0)
  )


# Display and save results

ggsave(file=file.path("C:/Users/HP OMEN GAMING/Desktop/mr-uganda-hackathon-2023-6/results", "combined_Foward_MR.png"))


# Adapting the original code to the new format
p = ggplot(data=res_comb, 
           aes(x=pop, y=b, ymin=b-se*1.96, ymax=b+se*1.96, color=pop)) +
  geom_pointrange() +
  geom_hline(aes(fill=pop), yintercept=0, linetype="dashed") +
  xlab('Proteins') + ylab("beta_IV (logodds ratio per SD)") +
  geom_errorbar(aes(ymin=b-se*1.96, ymax=b+se*1.96, color=pop), width=0.5) + 
  facet_wrap(~exposure, strip.position="left", nrow=8, scales="free_y") + labs(title = "Combined forest plot of potential MDD drug targets across ancestry") +
  theme(
    plot.title = element_text(size=16, face="bold"),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.text.x = element_text(face="bold"),
    axis.title = element_text(size=12, face="bold"),
    strip.text.y = element_text(hjust=0, vjust=1, angle=180, face="bold")
  ) +
  coord_flip()

print(p)  # To display the plot

###########################

