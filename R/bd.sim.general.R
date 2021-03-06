#' Non-constant rate Birth-Death simulation
#'
#' Simulates a species birth-death process with general rates for any number of
#' starting species. Allows for the speciation/extinction rate to be (1) a 
#' constant, or (2) a function of time. Allows for constraining results on the 
#' number of species at the end of the simulation, either total or extant. The 
#' function can also take an optional shape argument to generate age-dependence on
#' speciation and/or extinction, assuming a Weibull distribution as a model of 
#' age-dependence. Returns an object containing vectors of speciation times, 
#' extinction times, parents (= species' mother species) and status at the end of 
#' the simulation (extant or not) for each species in the simulation. 
#' It may return true extinction times or simply information on whether species 
#' lived after the maximum simulation time. For constant rate simulations, see
#' \code{bd.sim.constant}. For a function that unites all scenarios, see 
#' \code{bd.sim}. \code{bd.sim} also allows for extra inputs, creating a
#' time-dependent only rate internally through \code{make.rate}. For similar
#' flexibility, use \code{make.rate} to generate the desired rate.
#' Please note while time runs from \code{0} to \code{tMax} in the simulation, it 
#' returns speciation/extinction times as \code{tMax} (origin of the group) to 
#' \code{0} (the "present" and end of simulation), so as to conform to other
#' packages in the literature.
#'
#' @inheritParams bd.sim
#' 
#' @param lambda Function to hold the speciation rate over time. It will either be
#' interpreted as an exponential rate, or a Weibull scale if 
#' \code{lShape != NULL}.
#'
#' @param mu Similar to above, but for the extinction rate.
#' 
#' Note: this function is meant to be called by \code{bd.sim}, so it neither
#' allows for as much flexibility, nor calls \code{make.rate}. If the user wishes
#' to use \code{bd.sim.general} with environmental or step-function rates, they
#' can generate the rate with \code{make.rate} and supply it to the function.
#'
#' @return A list of vectors, as follows
#'
#' \describe{
#' \item{\code{TE}}{List of extinction times, with \code{0} as the time of
#' extinction for extant species.}
#'
#' \item{\code{TS}}{List of speciation times, with \code{NA} as the time of
#' speciation for species that started the simulation.}
#'
#' \item{\code{PAR}}{List of parents. Species that started the simulation have
#' \code{NA}, while species that were generated during the simulation have their
#' parent's number. Species are numbered as they are born.}
#'
#' \item{\code{EXTANT}}{List of logicals representing whether each species is
#' extant.}}
#'
#' @author Bruno do Rosario Petrucci.
#'
#' @examples
#'
#' # we can test a couple scenarios
#' 
#' ###
#' # first, even though this is bd.sim.general, we can try constant rates
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.11
#' 
#' # extinction
#' mu <- 0.08
#' 
#' # run the simulation
#' sim <- bd.sim.general(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # we can complicate things further with a linear function as a rate
#' # bd.sim.general takes longer so we run examples for 1000 replicates instead
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- function(t) {
#'   return(0.03 + 0.005*t)
#' }
#' 
#' # extinction
#' mu <- 0.05
#' 
#' # run the simulation
#' sim <- bd.sim.general(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # we can also create a step function
#' 
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation rate
#' lambda <- function(t) {
#'   return(0.03 + 0.005*t)
#' }
#' 
#' # vector of extinction rates
#' mList <- c(0.06, 0.09, 0.11)
#' 
#' # vector of shift times. Note mShifts could be c(40, 20, 10) for
#' # identical results
#' mShifts <- c(0, 15, 25)
#' 
#' # let us take a look at how make.rate will make it a step function
#' mu <- make.rate(mList, tMax = tMax, rateShifts = mShifts)
#' 
#' # and plot it
#' plot(seq(0, tMax, 0.1), mu(seq(0, tMax, 0.1)), type = 'l',
#'      main = "Extintion rate as a step function", xlab = "Time (My)",
#'      ylab = "Rate (species/My)")
#' 
#' # a different way to define the same extinction function
#' mu <- function(t) {
#'   ifelse(t < 15, 0.06,
#'          ifelse(t < 25, 0.09, 0.11))
#' }
#' 
#' # run the simulation
#' sim <- bd.sim.general(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' # we could instead have used q made with make.rate
#' # that is, however, much slower
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # another feature to add is age dependency
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.1
#' 
#' # extinction - a Weibull scale
#' mu <- 10
#' 
#' # extinction shape
#' mShape <- 1
#' 
#' # run simulations
#' sim <- bd.sim.general(n0, lambda, mu, tMax, mShape = mShape, 
#'                       nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # scale can be time-dependent
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # speciation
#' lambda <- 0.15
#' 
#' # extinction - a Weibull scale
#' mu <- function(t) {
#'   return(8 + 0.05*t)
#' }
#' 
#' # extinction shape
#' mShape <- 1
#' 
#' # run simulations
#' sim <- bd.sim.general(n0, lambda, mu, tMax, mShape = mShape, 
#'                       nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' ###
#' # finally, we could have environmental dependency on a rate
#' # initial number of species
#' n0 <- 1
#' 
#' # maximum simulation time
#' tMax <- 40
#' 
#' # temperature-dependent speciation
#' p_t <- function(t, temp) {
#'  return(0.025*exp(0.1*temp))
#' }
#' 
#' # extinction
#' mu <- 0.075
#' 
#' # get the temperature data
#' data(temp)
#' 
#' # speciation
#' lambda <- make.rate(p_t, envRate = temp)
#' 
#' # run simulations
#' sim <- bd.sim.general(n0, lambda, mu, tMax, nFinal = c(2, Inf))
#' 
#' # we can plot the phylogeny to take a look
#' if (requireNamespace("ape", quietly = TRUE)) {
#'   phy <- make.phylo(sim)
#'   ape::plot.phylo(phy)
#' }
#' 
#' # note nFinal has to be sensible
#' \dontrun{
#' # this would return a warning, since it is virtually impossible to get 100
#' # species at a process with diversification rate -0.09 starting at n0 = 1
#' sim <- bd.sim.general(1, lambda = 0.01, mu = 1, tMax = 100, 
#'                       nFinal = c(100, Inf))
#' }
#'
#' @name bd.sim.general
#' @rdname bd.sim.general
#' @export
#' 

bd.sim.general <- function(n0, lambda, mu, tMax, 
                         lShape = NULL, mShape = NULL,
                         nFinal = c(0, Inf), extOnly = FALSE,
                         trueExt = FALSE) {
  # error check - rate cannot be negative
  if ((is.numeric(lambda))) {
    if (lambda < 0) {
      stop("speciation rate cannot be negative")
    }
  }
  
  else {
    if (sum(lambda(seq(0, tMax, 0.1)) < 0) > 0) {
      stop("speciation rate cannot be negative")
    }
  }
  
  if ((is.numeric(mu))) {
    if (mu < 0) {
      stop("extinction rate cannot be negative")
    }
  }
  
  else {
    if (sum(mu(seq(0, tMax, 0.1)) < 0) > 0) {
      stop("extinction rate cannot be negative")
    }
  }
  
  # check that n0 is not negative
  if (n0 <= 0) {
    stop("initial number of species must be positive")
  }
  
  # check nFinal's length
  if (length(nFinal) != 2) {
    stop("nFinal must be a vector with a minimum and maximum number 
         of species")
  }
  
  # initialize species count with a value that makes sure the while loop runs
  len <- -1
  
  # counter to make sure the nFinal is achievable
  counter <- 1
  
  # if shape is not null, make scale a function to facilitate checking
  if (!is.null(lShape)) {
    message("since lShape is not null, lambda will be a Weibull scale and
            therefore correspond to 1/rate. See ?bd.sim or ?bd.sim.general")
    
    if (is.numeric(lambda)) {
      l <- lambda
      lambda <- Vectorize(function(t) l)
    }
  }
  
  if (!is.null(mShape)) {
    message("since mShape is not null, mu will be a Weibull scale and therefore
            correspond to 1/rate. See ?bd.sim or ?bd.sim.general")
    
    if (is.numeric(mu)) {
      m <- mu
      mu <- Vectorize(function(t) m)
    }
  }
  
  while (len < nFinal[1] | len > nFinal[2]) {
    # create vectors to hold times of speciation, extinction, parents and status
    TS <- rep(0, n0)
    TE <- rep(NA, n0)
    parent <- rep(NA, n0)
    isExtant <- rep(TRUE, n0)
  
    # initialize species count
    sCount <- 1
  
    # while we have species to be analyzed still
    while (length(TE) >= sCount) {
      # start at the time of speciation of sCount
      tNow <- TS[sCount]

      # find the waiting time using rexp.var if lambda is not constant
      # note we need to pass NULL for TS if the corresponding shape is NULL
      waitTimeS <- ifelse(
        is.numeric(lambda), ifelse(lambda > 0, rexp(1, lambda), Inf),
        ifelse(lambda(tNow) > 0, 
               rexp.var(1, lambda, tNow, tMax, lShape, TS[sCount], 
                        fast = !trueExt), Inf))
      waitTimeE <- ifelse(
        is.numeric(mu), ifelse(mu > 0, rexp(1, mu), Inf),
        ifelse(mu(tNow) > 0,
               rexp.var(1, mu, tNow, tMax, mShape, TS[sCount], 
                        fast = !trueExt), Inf))
  
      tExp <- tNow + waitTimeE
  
      # while there are fast enough speciations before the species goes extinct,
      while ((tNow + waitTimeS) <= min(tExp, tMax)) {
  
        # advance to the time of speciation
        tNow <- tNow + waitTimeS
  
        # add new times to the vectors
        TS <- c(TS, tNow)
        TE <- c(TE, NA)
        parent <- c(parent, sCount)
        isExtant <- c(isExtant, TRUE)
  
        # get a new speciation waiting time, and include it in the vector
        waitTimeS <- ifelse(
          is.numeric(lambda), ifelse(lambda > 0, rexp(1, lambda), Inf),
          ifelse(lambda(tNow) > 0, 
                 rexp.var(1, lambda, tNow, tMax, lShape, TS[sCount], 
                          fast = !trueExt), Inf))
      }
  
      # reached the time of extinction
      tNow <- tExp
  
      # record the extinction - if tNow > tMax, it is extant
      isExtant[sCount] <- ifelse(tNow > tMax, TRUE, FALSE)
      TE[sCount] <- ifelse(tNow <= tMax | trueExt, tNow, NA)
  
      # next species
      sCount <- sCount + 1
    }
  
    # now we invert TE and TS so time goes from tMax to 0
    TE <- tMax - TE
    TS <- tMax - TS

    # check the size of the simulation
    len <- ifelse(extOnly, sum(isExtant), length(isExtant))
    # if this is in nFinal, the while loop stops
    
    # if we have ran for too long, stop
    counter <- counter + 1
    if (counter > 100000) {
      warning("This value of nFinal took more than 100000 simulations 
              to achieve")
      return(NA)
    }
  }
  
  return(list(TE = TE, TS = TS, PAR = parent, EXTANT = isExtant))
}
