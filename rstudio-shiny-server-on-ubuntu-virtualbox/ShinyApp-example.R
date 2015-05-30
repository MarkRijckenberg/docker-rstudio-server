install.packages("mclust")
if (!require('shiny')) install.packages("shiny")
shiny::runGitHub("shiny-examples", "rstudio", subdir = "040-dynamic-clustering")
