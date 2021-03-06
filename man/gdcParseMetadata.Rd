% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gdcParseMetadata.R
\name{gdcParseMetadata}
\alias{gdcParseMetadata}
\title{Parse metadata}
\usage{
gdcParseMetadata(metafile = NULL, project.id, data.type, write.meta = FALSE)
}
\arguments{
\item{metafile}{metadata file in \code{.json} format download from GDC cart. If provided, the metadata will be parsed from this file,
otherwise, \code{project} and \code{data.type} arguments should be provided to retrieve metadata automatically. Default is \code{NULL}}

\item{project.id}{project id in GDC}

\item{data.type}{one of \code{'RNAseq'} and \code{'miRNAs'}}

\item{write.meta}{logical, whether to write the metadata to a \code{.json} file}
}
\value{
A dataframe of metadata containing file_name, sample_id, etc. as well as some basic clinical data
}
\description{
Parse metadata either by providing the \emph{.json} file that is 
downloaded from GDC cart or by parse metadata automatically by providing the projct id and data type
}
\examples{
####### Merge RNA expression data #######
metaMatrix <- gdcParseMetadata(project.id='TARGET-RT', data.type='RNAseq')
}
\author{
Ruidong Li and Han Qu
}
