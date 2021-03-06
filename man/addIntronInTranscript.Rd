% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/IntronRetention.R
\name{addIntronInTranscript}
\alias{addIntronInTranscript}
\title{Add a retained intron to the transcripts it is skipped by}
\usage{
addIntronInTranscript(intronRanges = IR_range, flanking_exons, gtf.exons,
  glueExons = TRUE)
}
\arguments{
\item{intronRanges}{GRanges object with ranges for introns}

\item{flanking_exons}{data.frame generataed by findIntronContainingTranscripts()}

\item{gtf.exons}{GRanges object made from a GTF with ONLY exon annotations (no gene, transcript, CDS etc.)}

\item{glueExons}{Join together exons that are not seperated by introns?}
}
\value{
GRanges with transcripts containing retained introns
}
\description{
Add a retained intron to the transcripts it is skipped by
}
\author{
Beth Signal
}
