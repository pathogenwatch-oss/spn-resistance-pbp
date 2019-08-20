if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos='http://cran.us.r-project.org')
BiocManager::install(c("Biostrings", "randomForest", "iterators", "foreach", "glmnet"))
