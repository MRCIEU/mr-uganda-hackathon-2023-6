library(dplyr)
library(ggplot2)

#load the results for all ancestries into one data frame
#european ancenstry(eur)
load(file.path("results", "eur.rdata"))
eur <- res
eur$pop <- "EUR"

#african ancestry(afr)
load(file.path("results", "afr.rdata"))
afr<- res
afr$pop <- "AFR"

#central south asian ancestry(csa)
load(file.path("results", "csa.rdata"))
csa<- res
csa$pop <- "CSA"

#east asian ancestry(eas)
load(file.path("results", "eas.rdata"))
eas<- res
eas$pop <- "EAS"

#combine all data frames 

res_comb <- bind_rows(eur,eas,csa,afr)

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

ggsave(file=file.path("results", "combined.png"), width=10, height=10)

## Heterogeneity analysis
fixed_effects_meta_analysis <- function(beta_vec, se_vec) {
    w <- 1 / se_vec^2
    beta <- sum(beta_vec * w, na.rm=T) / sum(w, na.rm=T)
    se <- sqrt(1 / sum(w, na.rm=T))
    pval <- pnorm(abs(beta / se), lower.tail = FALSE)
    Qj <- w * (beta-beta_vec)^2
    Q <- sum(Qj, na.rm=T)
    Qdf <- sum(!is.na(beta_vec))-1
    if(Qdf == 0) Q <- 0
    Qjpval <- pchisq(Qj, 1, lower.tail=FALSE)
    Qpval <- pchisq(Q, Qdf, lower.tail=FALSE)
    return(list(beta=beta, se=se, Q=Q, Qdf=Qdf, Qpval=Qpval, Qj=Qj, Qjpval=Qjpval))
}

# Example
x <- subset(res_comb, exposure == "AKT3")
fixed_effects_meta_analysis(x$b, x$se)

# Example
x <- subset(res_comb, exposure == "FES")
fixed_effects_meta_analysis(x$b, x$se)

# Do het analysis for all proteins
res <- lapply(unique(res_comb$exposure), \(e) {
  x <- subset(res_comb, exposure == e)
  res <- fixed_effects_meta_analysis(x$b, x$se)
  Q <- tibble(exposure=e, beta=res$beta, se=res$se, Q=res$Q, Qdf=res$Qdf, Qpval=res$Qpval)
  Qj <- tibble(exposure=e, pop=x$pop, Qj=res$Qj, Qjpval=res$Qjpval)
  return(list(Q,Qj))  
})

# Organise the results for global heterogeneity (Q)
resQ <- lapply(res, \(x) x[[1]]) %>% bind_rows()

# Organise the results for per-study heterogeneity contributions (Qj)
resQj <- lapply(res, \(x) x[[2]]) %>% bind_rows()

# Correct for multiple testing using FDR
resQj$fdr <- p.adjust(resQj$Qjpval, "fdr")

# Visualise the per-study heterogeneity (pval)
ggplot(resQj, aes(x=exposure, y=-log10(Qjpval))) +
geom_point(aes(colour=pop)) +
geom_hline(yintercept=-log10(0.05))

# Visualise the per-study heterogeneity (FDR)
ggplot(resQj, aes(x=exposure, y=-log10(fdr))) +
geom_point(aes(colour=pop)) +
geom_hline(yintercept=-log10(0.05))



res_m <- inner_join(res_comb, resQj, by=c("exposure", "pop"))
res_m <- (res_comb, resQj, by=c("exposure", "pop"))

names(resQ)[names(resQ)=="beta"] <- "b"
resQ$pop <- "Combined"
resQ$Qjpval <- 1

ggplot(bind_rows(res_m, resQ), aes(y=pop, x=b, color=pop)) +
  geom_point(aes(size=Qjpval < 0.05)) +
  geom_errorbarh(aes(xmin=b-se*1.96, xmax=b+se*1.96), height=0) +
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
  ) +
  scale_colour_brewer(type="qual")
# todo
# - make the colours clearer
# - Choose how to highlight heterogeneity
# - Order combined to be at the bottom

