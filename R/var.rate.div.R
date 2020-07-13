#' Calculates the expected number of species for a given time varying rate
#' using the exponential distribution for variable rates.
#'
#' \code{var.rate.div} takes a function, an initial number of species and a time
#' vector and calculates the predicted exponential with that function as rate
#' on that interval. This allows for efficient testing of the diversity curves
#' produced by \code{paleobuddy} simulations.
#'
#' @param ff a rate for the exponential distribution that can be
#' any function of time. One can also supply data for an environmental
#' variable (see below for the \code{envF} param) and get the expected
#' number of species for a hybrid function of time and said variable. Finally,
#' one can instead supply a vector of rates to \code{ff} and a vector of shifts
#' to \code{fShifts} and get a step function. It is more efficient to create a
#' stepfunction using \code{ifelse} however (see examples below).
#'
#' @param n0 the initial number of species is by default 1, but one
#' can change to any positive number. We allow for negative initial values as
#' well, but of course that will not help in testing the package.
#'
#' NOTE: \code{var.rate.div} will find the expected number of daughters given a
#' rate \code{ff} and an initial number of parents \code{n0}, so in a
#' biological context \code{ff} is diversification rate, not speciation (unless
#' extinction is 0, of course).
#'
#' @param t a time vector over which to consider the distribution.
#'
#' @param envF a two dimensional dataframe with time as a first
#' column and the desired environmental variable as a second. Note that
#' supplying a function with one argument and a non-NULL \code{envF}, and vice
#' versa, will return an error.
#'
#' @param fShifts a vector of rate shifts. Then used with the rates
#' vector to create a step function for the rates. If supplied without a rates
#' vector, and vice versa, will return an error.
#'
#' @return a vector of the expected number of species per time point supplied
#' in \code{t}, which can then be used to plot vs. \code{t}.
#'
#' @examples
#'
#' # let us first create a vector of times to use in these examples.
#' t <- seq(0, 50, 0.1)
#' 
#' ###
#' # we can start simple: create a constant rate
#' ff <- 0.1
#' 
#' # set this up so we see rates next to diversity
#' par(mfrow = c(1,2))
#' 
#' # see how the rate looks
#' r <- make.rate(0.5)
#' plot(t, rep(r, length(t)), type = 'l')
#' 
#' # get the diversity and plot it
#' div <- var.rate.div(ff, t = t)
#' plot(t, div, type = 'l')
#' 
#' ###
#' # something a bit more complex: a linear rate
#' ff <- function(t) {
#'   return(0.01*t)
#' }
#' 
#' # visualize the rate
#' r <- make.rate(ff)
#' plot(t, r(t), type = 'l')
#' 
#' # get the diversity and plot it
#' div <- var.rate.div(ff, t = t)
#' plot(t, div, type = 'l')
#' 
#' ###
#' # remember: ff is diversity!
#' 
#' # we can create speciation...
#' pp <- function(t) {
#'   return(-0.01*t + 0.2)
#' }
#' 
#' # ...and extinction...
#' qq <- function(t) {
#'   return(0.01*t)
#' }
#' 
#' # ...and code ff as diversification
#' ff <- function(t) {
#'   return(pp(t) - qq(t))
#' }
#' 
#' # visualize the rate
#' r <- make.rate(ff)
#' plot(t, r(t), type = 'l')
#' 
#' # get diversity and plot it
#' div <- var.rate.div(ff, n0 = 2, t)
#' plot(t, div, type = 'l')
#' 
#' ###
#' # remember: ff can be any time-varying function!
#' 
#' # such as a sine
#' ff <- function(t) {
#'   return(sin(t)*0.5)
#' }
#' 
#' # visualize the rate
#' r <- make.rate(ff)
#' plot(t, r(t), type = 'l')
#' 
#' # we can have any number of starting species
#' div <- var.rate.div(ff, n0 = 2, t)
#' plot(t, div, type = 'l')
#' 
#' ###
#' # we can use ifelse() to make a step function like this
#' ff <- function(t) {
#'   return(ifelse(t < 2, 0.1,
#'                 ifelse(t < 3, 0.3,
#'                        ifelse(t < 5, -0.2, 0.05))))
#' }
#' 
#' # change t so things are faster
#' t <- seq(0, 10, 0.1)
#' 
#' # visualize the rate
#' r <- make.rate(ff)
#' plot(t, r(t), type = 'l')
#' 
#' # get the diversity and plot it
#' div <- var.rate.div(ff, t = t)
#' plot(t, div, type = 'l')
#' 
#' # important note: this method of creating a step function might be annoying,
#' # but when running thousands of simulations it will provide a much faster
#' # integration than when using our method of transforming a rates and shifts
#' # vector into a function of time
#' 
#' ###
#' # ...which we can do as follows
#' 
#' # rates vector
#' ff <- c(0.1, 0.3, -0.2, 0.05)
#' 
#' # rate shifts vector
#' fShifts <- c(0, 2, 3, 5)
#' 
#' # visualize the rate
#' r <- make.rate(ff, fShifts = fShifts)
#' plot(t, r(t),type = 'l')
#' 
#' # get the diversity and plot it
#' div <- var.rate.div(ff, t = t, fShifts = fShifts)
#' plot(t, div, type = 'l')
#' 
#' # note the delay in running var.rate.div using this method. integrating a step
#' # function created using the methods in make.rate() is slow, as explained in
#' # the make.rate documentation)
#' 
#' # it is also impractical to supply a rate and a shifts vector and
#' # have an environmental dependency, so in cases where one looks to run
#' # more than a couple dozen simulations, and when one is looking to have a
#' # step function modified by an environmental variable, consider using ifelse()
#' 
#' # finally let us see what we can do with environmental variables
#' 
#' # RPANDA supplies us with some really useful environmental dataframes
#' # to use as an example, let us try temperature
#' if (requireNamespace("RPANDA", quietly = TRUE)) {
#'   # get the temperature data
#'   data(InfTemp, package = "RPANDA")
#'   
#'   # diversification
#'   ff <- function(t, env) {
#'     return(0.002*env)
#'   }
#'   
#'   # visualize the rate
#'   r <- make.rate(ff, envF = InfTemp)
#'   plot(t, r(t), type = 'l')
#'   
#'   # get diversity and plot it
#'   div <- var.rate.div(ff, t = t, envF = InfTemp)
#'   plot(t, div, type = 'l')
#'   
#'   ###
#'   # we can also have a function that depends on both time AND temperature
#'   
#'   # diversification
#'   ff <- function(t, env) {
#'     return(0.03 * env - 0.01 * t)
#'   }
#'   
#'   # visualize the rate
#'   r <- make.rate(ff, envF = InfTemp)
#'   plot(t, r(t), type = 'l')
#'   
#'   # get diversity and plot it
#'   div <- var.rate.div(ff, t = t, envF = InfTemp)
#'   plot(t, div, type = 'l')
#'   
#'   ###
#'   # as mentioned above, we could also use ifelse() to construct a step function
#'   # that is modulated by temperature
#'   
#'   # diversification
#'   ff <- function(t, env) {
#'     return(ifelse(t < 2, 0.1 + 0.01*env,
#'                   ifelse(t < 5, 0.2 - 0.005*env,
#'                          ifelse(t < 8, 0.1 + 0.005*env, 0))))
#'   }
#'   
#'   # visualize the rate
#'   r <- make.rate(ff, envF = InfTemp)
#'   plot(t, r(t), type = 'l')
#'   
#'   div <- var.rate.div(ff, t = t, envF = InfTemp)
#'   plot(t, div, type = 'l')
#' }
#' 
#' @name var.rate.div
#' @rdname var.rate.div
#' @export

var.rate.div <- function(ff, n0 = 1, t, envF = NULL, fShifts = NULL) {
  # get the corresponding rate
  f <- make.rate(ff, envF = envF, fShifts = fShifts)

  if (!is.numeric(f)) {
    # integrate the rate for each t
    integral <- lapply(t, function(x) {
      integrate(Vectorize(f), 0, x, subdivisions = 2000)$value
      })

    # make the integral numerical so we can plot
    for (i in 1:length(integral)) {
      integral[i] <- as.numeric(integral[[i]])
      }
    integral <- as.numeric(integral)
  }

  else {
    integral <- f*t
  }

  return(n0*exp(integral))
}