% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gdcShinyPlot.R
\name{shinyCorPlot}
\alias{shinyCorPlot}
\title{Shiny correlation plot}
\usage{
shinyCorPlot(gene1, gene2, rna.expr, metadata)
}
\arguments{
\item{gene1}{a vector of Ensembl gene ids or miRBase v21 mature miRNA ids}

\item{gene2}{a vector of Ensembl gene ids or miRBase v21 mature miRNA ids}

\item{rna.expr}{\code{\link[limma]{voom}} transformed expression data}

\item{metadata}{metadata parsed from \code{\link{gdcParseMetadata}}}
}
\value{
a local webpage for visualization of correlation plots
}
\description{
A simple \pkg{shiny} app to show scatter plot of correlations between two genes/miRNAs on local web browser
}
\author{
Ruidong Li and Han Qu
}
