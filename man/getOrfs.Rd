% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/longestORF.R
\name{getOrfs}
\alias{getOrfs}
\title{Get open reading frames for transcripts}
\usage{
getOrfs(transcripts, BSgenome = g, returnLongestOnly = TRUE,
  all_frames = FALSE, longest = 1)
}
\arguments{
\item{transcripts}{GRanges object with ONLY exon annotations (no gene, transcript, CDS etc.) with all transcripts for orf retrevial}

\item{BSgenome}{BSgenome object}

\item{returnLongestOnly}{only return longest ORF?}

\item{all_frames}{return longest ORF for all 3 frames?}

\item{longest}{return x longest ORFs (regardless of frames)}
}
\value{
data.frame with longest orf details
}
\description{
Get open reading frames for transcripts
}
\author{
Beth Signal
}
