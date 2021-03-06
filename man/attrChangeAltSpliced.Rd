% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compareTranscripts.R
\name{attrChangeAltSpliced}
\alias{attrChangeAltSpliced}
\title{Evaluate the change in an attribute between a set of 'normal' transcripts and 'alternative' transcripts}
\usage{
attrChangeAltSpliced(orfsX, orfsY, attribute = "orf_length",
  compareBy = "gene", useMax = TRUE, compareUTR = FALSE)
}
\arguments{
\item{orfsX}{orf information for 'normal' transcripts. Generated by getOrfs()}

\item{orfsY}{orf information for 'alternative' transcripts. Generated by getOrfs()}

\item{attribute}{attribute to compare}

\item{compareBy}{compare by 'transcript' isoforms or by 'gene' groups}

\item{useMax}{use max as the summary function when multiple isoforms are aggregated? If FALSE, will use min instead.}
}
\value{
data.frame with attribute changes
}
\description{
Evaluate the change in an attribute between a set of 'normal' transcripts and 'alternative' transcripts
}
\author{
Beth Signal
}
