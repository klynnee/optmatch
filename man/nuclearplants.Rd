\name{nuclearplants}
\alias{nuclearplants}
\title{
Nuclear Power Station Construction Data
}
\description{
The \code{nuclearplants} data frame has 32 rows and 11 columns.


The data relate to the construction of 32 light water reactor (LWR) plants 
constructed in the U.S.A in the late 1960's and early 1970's.  The data was
collected with the aim of predicting the cost of construction of further
LWR plants.  6 of the power plants had partial turnkey guarantees and it is
possible that, for these plants, some manufacturers' subsidies may be hidden 
in the quoted capital costs.
}
\usage{
nuclearplants
}
\format{
This data frame contains the following columns:


\describe{
\item{\code{cost}}{
The capital cost of construction in millions of dollars adjusted to 1976 base.
}
\item{\code{date}}{
The date on which the construction permit was issued.  The data are measured in
years since January 1 1990 to the nearest month.
}
\item{\code{t1}}{
The time between application for and issue of the construction permit.
}
\item{\code{t2}}{
The time between issue of operating license and construction permit.
}
\item{\code{cap}}{
The net capacity of the power plant (MWe).
}
\item{\code{pr}}{
A binary variable where \code{1} indicates the prior existence of a LWR plant at
the same site.
}
\item{\code{ne}}{
A binary variable where \code{1} indicates that the plant was constructed in the 
north-east region of the U.S.A.
}
\item{\code{ct}}{
A binary variable where \code{1} indicates the use of a cooling tower in the plant.
}
\item{\code{bw}}{
A binary variable where \code{1} indicates that the nuclear steam supply system was
manufactured by Babcock-Wilcox.
}
\item{\code{cum.n}}{
The cumulative number of power plants constructed by each architect-engineer.
}
\item{\code{pt}}{
A binary variable where \code{1} indicates those plants with partial turnkey
guarantees.
}}}
\source{
The data were obtained from the \code{boot} package, for which they were
in turn taken from Cox and Snell (1981). Although the data themselves
are the same as those in the \code{nuclear} data frame in the \code{boot} package,
the row names of the data frame have been changed.  (The new row names
were selected to ease certain demonstrations in \code{optmatch}.)

This documentation page is also adapted from the \code{boot} package,
written by Angelo Canty and ported to R by Brian Ripley.
}
\references{
Cox, D.R. and Snell, E.J. (1981) 
\emph{Applied Statistics: Principles and Examples}. Chapman and Hall.
}
\keyword{datasets}

