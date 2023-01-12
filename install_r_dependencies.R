if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos='https://cloud.r-project.org/')
BiocManager::install(c("Biostrings", "iterators", "foreach", "glmnet"))
