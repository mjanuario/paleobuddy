#' General rate Birth-Death simulation
#'
#' \code{bd.sim} takes an initial number of species, speciation and extinction
#' rate functions and a maximum time of simulation, together with multiple
#' options to alter the rates, and calls \code{bd.sim.constant} or
#' \code{bd.sim.general} to generate a species diversification process under the
#' desired scenario.
#'
#' @param n0 initial number of species, usually 1. Good parameter
#' to tweak if one is observing a low sample size when testing.
#'
#' @param pp function to hold the speciation rate over time. It could be a
#' constant or a function of time (to be an exponential rate or weibull scale),
#' a function of time and an environmental variable, or a vector of rates to be
#' accompanied by a vector of rate shifts \code{pShifts}.
#'
#' @param qq similar as above, but for the extinction rate.
#'
#' Note: \code{pp} and \code{qq} must always be greater than 0
#'
#' @param tMax ending time of simulation. Any species still living
#' after tMax is considered extant, and any species that would be generated
#' after \code{tMax} is not born.
#'
#' @param pShape shape parameter for the Weibull distribution for age-dependent
#' speciation. Default is \code{NULL}, where \code{pp} will be considered a
#' time-dependent exponential rate. For \code{pShape != NULL}, \code{pp} will
#' be considered a scale, and \code{rexp.var} will draw a Weibull distribution
#' instead.
#'
#' @param qShape similar as above, but for the extinction rate.
#'
#' @param envPP a matrix containing time points and values of an
#' environmental variable, like temperature, for each time point. This will be
#' used to create a speciation rate, so \code{pp} must be a function of time
#' and said variable.
#'
#' @param envQQ similar as above, but for the extinction rate.
#'
#' @param pShifts vector of rate shifts. First element must be the sstarting
#' time for the simulation (0 or tMax). It must have the same length as
#' \code{pp}. E.g. \code{pp = c(0.1, 0.2, 0.1)}, \code{pShifts = c(0, 10, 20)}
#' means the speciation rate will be 0.1 from 0 to 10, 0.2 from 10 to 20, and 
#' 0.1 from 20 to \code{tMax}. It would also be identical, in this case, to use
#' \code{pShifts = c(tMax, tMax-10, tMax-20)}.
#' 
#' Note that using this  method for step-function rates is currently slower than using
#' \code{ifelse}.
#'
#' @param qShifts similar as above, but for the extinction rate.
#' 
#' @param nFinal an interval of acceptable number of species at the end of the
#' simulation. If not supplied, default is \code{c(0, Inf)}, so that any number
#' of species is accepted. If supplied, \code{bd.sim.constant} or 
#' \code{bd.sim.general} will run until the number of total species generated, or, 
#' if \code{extOnly = TRUE}, the number of extant species at the end of the 
#' simulation, lies within the interval.
#' 
#' @param extOnly a boolean indicating whether \code{nFinal} should be taken as
#' the number of total or extant species during the simulation. If \code{TRUE},
#' \code{bd.sim.constant} or \code{bd.sim.general} will run until the number of extant
#' species lies within the \code{nFinal} interval. If \code{FALSE}, as default, it 
#' will run until the total number of species generated lies within that interval.
#' 
#' @param fast used for \code{bd.sim.general}. When \code{TRUE}, sets 
#' \code{rexp.var} to throw away waiting times higher than the maximum 
#' simulation time. Should be \code{FALSE} for unbiased testing of age 
#' dependency. User might also se it to \code{FALSE} for more accurate waiting
#' times.
#' 
#' @param trueExt used for \code{bd.sim.general}. When \code{TRUE}, time of 
#' extinction of extant species will be the true time, otherwise it will be 
#' tMax+0.01. Need to be \code{TRUE} when testing age-dependent 
#' extinction.
#'
#' @return the return list of either \code{bd.sim.constant} or
#' \code{bd.sim.general}, which have the same elements, as follows
#'
#' \describe{
#' \item{\code{TE}}{list of extinction times, with -0.01 as the time of
#' extinction for extant species.}
#'
#' \item{\code{TS}}{list of speciation times, with tMax+0.01 as the time of
#' speciation for species that started the simulation.}
#'
#' \item{\code{PAR}}{list of parents. Species that started the simulation have
#' NA, while species that were generated during the simulation have their
#' parent's number. Species are numbered as they are born.}
#'
#' \item{\code{EXTANT}}{list of booleans representing whether each species is
#' extant.}}
#'
#' @author written by Bruno do Rosario Petrucci.
#'
#' @examples
#' 
#' # we will showcase here some of the possible scenarios for diversification,
#' # touching on all the kinds of rates
#' 
#' ###
#' # consider first the simplest regimen, constant speciation and extinction
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' p <- 0.11
#' 
#' # extinction
#' q <- 0.08
#' 
#' # run the simulation, making sure we have more than 1 species in the end
#' sim <- bd.sim(n0, p, q, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   # full phylogeny
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # now let us complicate speciation more, maybe a linear function
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation rate
#' p <- function(t) {
#'   return(0.05 + 0.005*t)
#' }
#' 
#' # extinction rate
#' q <- 0.08
#' 
#' # run the simulation, making sure we have more than 1 species in the end
#' sim <- bd.sim(n0, p, q, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   # full phylogeny
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' # what if we want q to be a step function?
#' 
#' # list of extinction rates
#' qList <- c(0.09, 0.08, 0.1)
#' 
#' # list of shift times. Note qShifts could be c(40, 20, 5) for identical results
#' qShifts <- c(0, 20, 35)
#' 
#' # let us take a look at how make.rate will make it a step function
#' q <- make.rate(qList, fShifts = qShifts)
#' 
#' # and plot it
#' plot(seq(0, tMax, 0.1), q(seq(0, tMax, 0.1)), type = 'l',
#'      main = "Extintion rate as a step function", xlab = "Time (My)",
#'      ylab = "Rate (species/My)")
#' 
#' # looking good, we will keep everything else the same
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # speciation
#' p <- function(t) {
#'   return(0.02 + 0.005*t)
#' }
#' 
#' # a different way to define the same extinction function
#' q <- function(t) {
#'   ifelse(t < 20, 0.09, 
#'          ifelse(t < 35, 0.08, 0.1))
#' }
#' 
#' # run the simulation
#' sim <- bd.sim(n0, p, q, tMax, nFinal = c(2, Inf))
#' # equivalent:
#' # sim <- bd.sim.general(n0, p, qList, tMax, qShifts = qShifts)
#' # this is, however, much slower
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # we can also supply a shape parameter to try age-dependent rates
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - here note it is a Weibull scale
#' p <- 10
#' 
#' # speciation shape
#' pShape <- 2
#' 
#' # extinction
#' q <- 0.08
#' 
#' # run the simulation
#' sim <- bd.sim(n0, p, q, tMax, pShape = pShape, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ### 
#' # scale can be a time-varying function as well
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation - here note it is a Weibull scale
#' p <- function(t) {
#'   return(2 + 0.25*t)
#' }
#' 
#' # speciation shape
#' pShape <- 2
#' 
#' # extinction
#' q <- 0.2
#' 
#' # run the simulation
#' sim <- bd.sim(n0, p, q, tMax, pShape = pShape, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # finally, we can also have a rate dependent on an environmental variable,
#' # like temperature data in RPANDA
#' 
#' if (requireNamespace("RPANDA", quietly = TRUE)) {
#'   
#'   # get temperature data from RPANDA
#'   data(InfTemp, package = "RPANDA")
#'   
#'   # initial number of species
#'   n0 <- 1
#'   
#'   # maximum simulation time
#'   tMax <- 40
#'   
#'   # speciation - a scale
#'   p <- 10
#'   
#'   # note the scale for the age-dependency can be a time-varying function
#'   
#'   # speciation shape
#'   pShape <- 2
#'   
#'   # extinction, dependent on temperature exponentially
#'   q <- function(t, env) {
#'     return(0.2*exp(0.01*env))
#'   }
#'   
#'   # need a variable to tell bd.sim the extinction is environmentally dependent
#'   envQQ <- InfTemp
#'   
#'   # run the simulation
#'   sim <- bd.sim(n0, p, q, tMax, pShape = pShape, envQQ = InfTemp,
#'                nFinal = c(2, Inf))
#'   
#'   # we can plot the phylogeny to take a look
#'   if (requireNamespace("ape", quietly = TRUE)) {
#'     phy <- make.phylo(sim)
#'     ape::plot.phylo(phy)
#'   }
#'   
#'   ###
#'   # one can mix and match all of these scenarios as they wish - age-dependency
#'   # and constant rates, age-dependent and temperature-dependent rates, etc. The
#'   # only combination that is not allowed is a vector rate and environmental
#'   # data, but one can get around that as follows
#'   
#'   # initial number of species
#'   n0 <- 1
#'   
#'   # speciation - a step function of temperature built using ifelse()
#'   p <- function(t, env) {
#'     ifelse(t < 20, 2*env,
#'            ifelse(t < 30, env/2, 2*env/3))
#'   }
#'   
#'   # speciation shape
#'   pShape <- 2
#'   
#'   # environment variable to use - temperature
#'   envPP <- InfTemp
#'   
#'   # extinction - high so this does not take too long to run
#'   q <- 0.3
#'   
#'   # maximum simulation time
#'   tMax <- 40
#'   
#'   # run the simulation
#'   sim <- bd.sim(n0, p, q, tMax, pShape = pShape, envPP = envPP,
#'                nFinal = c(2, Inf))
#'   
#'   # we can plot the phylogeny to take a look
#'   if (requireNamespace("ape", quietly = TRUE)) {
#'     phy <- make.phylo(sim)
#'     ape::plot.phylo(phy)
#'   }
#' }
#' 
#' @name bd.sim
#' @rdname bd.sim
#' @export

bd.sim <- function(n0, pp, qq, tMax, 
                  pShape = NULL, qShape = NULL, 
                  envPP = NULL, envQQ = NULL, 
                  pShifts = NULL, qShifts = NULL, 
                  nFinal = c(0, Inf), extOnly = FALSE,
                  fast = TRUE, trueExt=FALSE) {
  
  # if we have ONLY numbers for pp and qq, it is constant
  if ((is.numeric(pp) & length(pp) == 1) &
      (is.numeric(qq) & length(qq) == 1) &
       (is.null(c(pShape, qShape, envPP, envQQ, pShifts, qShifts)))) {
    p <- pp
    q <- qq
    
    # call bd.sim.constant
    return(bd.sim.constant(n0, p, q, tMax, nFinal, extOnly))
  }

  # else it is not constant
  # note even if pp or qq is constant this may call bd.sim.general, since we
  # might have a shape parameter
  else {
    # use make.rate to create the rates we want
    p <- make.rate(pp, tMax, envPP, pShifts)
    q <- make.rate(qq, tMax, envQQ, qShifts)

    # call bd.sim.general
    return(bd.sim.general(n0, p, q, tMax, pShape, qShape, 
                        nFinal, extOnly, fast, trueExt))
  }
}