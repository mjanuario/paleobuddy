#' General rate exponential and Weibull waiting times
#' 
#' Generates a waiting time following an exponential or Weibull distribution with
#' constant or varying rates. Allows for an optional shape parameter, in which 
#' case \code{rate} will be taken as a Weibull scale. Allows for information on
#' the current time, to consider only rates starting from then, and the speciation
#' time, optionally, in case shape is provided, as the process is age-dependent.
#' Allows for customization on the possibility of throwing away waiting times
#' higher than \code{tMax}, and therefore takes that time as a parameter.
#'
#' @param n The number of waiting times to return. Usually 1, but we allow for
#' a higher \code{n} to be consistent with the \code{rexp} function.
#' 
#' @param rate The rate parameter for the exponential distribution. If
#' \code{shape} is not \code{NULL}, \code{rate} is a scale for a Weibull
#' distribution. In both cases we allow for any time-varying function. Note
#' \code{rate} can be constant.
#'
#' @param now The current time. Needed if one wants to consider only the interval
#' between the current time and the maximum time for the time-varying rate.
#' Note this does means the waiting time is \code{>= now}, so we also subtract
#' \code{now} from the result before returning. The default is \code{0}.
#'
#' @param tMax The simulation ending time. If the waiting time would be too
#' high, we return \code{tMax + 0.01} to signify the event never happens, if
#' \code{fast == TRUE}. Otherwise we return the true waiting time. By default,
#' \code{tMax} will be \code{Inf}, but if \code{FAST == TRUE} one must supply
#' a finite value.
#'
#' @param shape Shape of the Weibull distribution. This will be when smaller than 
#' one, rate will decrease along species' age (negative age-dependency). When 
#' larger than one, rate will increase along each species's age (positive 
#' age-dependency). Default is \code{NULL}, equivalent to an exponential
#' distribution. For \code{pShape != NULL} (including when equal to 
#' one), \code{pp} will be considered a scale (= 1/rate), and \code{rexp.var} will
#' draw a Weibull distribution instead of an exponential. This means 
#' Weibull(rate, 1) = Exponential(1/rate). Notice even when \code{pShape != NULL}, 
#' \code{pp} may still be time-dependent. 
#'
#' Note: Time-varying shape is implemented, so one could have \code{shape} be a
#' function of time. It is not thoroughly tested, however, so it may be prudent to
#' wait for a future release where this feature is well established.
#'
#' @param TS Speciation time, used to account for the scaling between simulation 
#' and species time. The default is \code{0}. Supplying a \code{TS > now} will
#' return an error.
#'
#' @param fast If set to \code{FALSE}, waiting times larger than \code{tMax} will
#' not be thrown away. This argument is needed so one can test the function
#' without bias.
#'
#' @return A vector of waiting times for the exponential or weibull distribution
#' with the given parameters.
#'
#' @author Bruno do Rosario Petrucci.
#'
#' @import stats
#'
#' @examples
#'
#' ###
#' # let us start by checking a simple exponential variable
#' 
#' # rate
#' rate <- 0.1
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # get waiting time
#' t <- rexp.var(n = 1, rate, now, tMax)
#' t
#' 
#' ###
#' # another simple exponential
#' 
#' # rate
#' rate <- 0.5
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # find the waiting time
#' t <- rexp.var(n = 1, rate, now, tMax)
#' t
#' 
#' ###
#' # now let us try a linear function for the rate
#' 
#' # rate
#' rate <- function(t) {
#'   return(0.01*t + 0.1)
#' }
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # find the waiting time
#' t <- rexp.var(n = 1, rate, now, tMax)
#' t
#' 
#' ###
#' # what if rate is exponential?
#' 
#' # rate
#' rate <- function(t) {
#'   return(0.01 * exp(0.1*t) + 0.02)
#' }
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # find the waiting time
#' t <- rexp.var(n = 1, rate, now, tMax)
#' t
#' 
#' ###
#' # rexp.var also works for a weibull
#' 
#' # scale
#' rate <- 2
#' 
#' # shape
#' shape <- 1
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # speciation time
#' TS <- 0
#' 
#' # find the vector of waiting time
#' t <- rexp.var(n = 1, rate, now, tMax,
#'               shape = shape, TS = TS)
#' t
#' 
#' ###
#' # when shape = 1, the Weibull is an exponential, we could do better
#' 
#' # scale
#' rate <- 10
#' 
#' # shape
#' shape <- 2
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # speciation time
#' TS <- 0
#' 
#' # find the vector of waiting times - it doesn't need to be just one
#' t <- rexp.var(n = 5, rate, now, tMax,
#'               shape = shape, TS = TS)
#' t
#' 
#' ###
#' # shape can be less than one, of course
#' 
#' # scale
#' rate <- 10
#' 
#' # shape
#' shape <- 0.5
#' 
#' # current time
#' now <- 3
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # speciation time - it will be greater than 0 frequently during a simulation,
#' # as it is used to represent where in the species life we currently are and
#' # rescale accordingly
#' TS <- 2.5
#' 
#' # find the vector of waiting times
#' t <- rexp.var(n = 3, rate, now, tMax,
#'               shape = shape, TS = TS)
#' t
#' 
#' ###
#' # both rate and shape can be time varying for a Weibull, but since we have
#' # only been able to test time-varying rate effectively, we do not recommend
#' # using shape as a function
#' 
#' # scale
#' rate <- function(t) {
#'   return(0.25*t + 5)
#' }
#' 
#' # shape
#' shape <- 3
#' 
#' # current time
#' now <- 0
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # speciation time
#' TS <- 0
#' 
#' # find the vector of waiting times - it doesn't need to be just one
#' t <- rexp.var(n = 5, rate, now, tMax,
#'               shape = shape, TS = TS)
#' t
#' 
#' ###
#' # rate can be any function of time, remember
#' 
#' # scale
#' rate <- function(t) {
#'   return(0.2*exp(0.1*t) + 5)
#' }
#' 
#' # shape
#' shape <- 3
#' 
#' # current time - remember rate will only be considered starting from time now
#' now <- 2.5
#' 
#' # maximum time to check
#' tMax <- 40
#' 
#' # speciation time
#' TS <- 1.2
#' 
#' # find the vector of waiting times - it doesn't need to be just one
#' t <- rexp.var(n = 2, rate, now, tMax,
#'               shape = shape, TS = TS)
#' t
#'
#' @name rexp.var
#' @rdname rexp.var
#' @export

rexp.var <- function(n, rate, now = 0, tMax = Inf, shape = NULL, 
                   TS = 0, fast = FALSE) {
  # some error checking
  if (tMax == Inf & fast) {
    stop("Need a valid tMax for fast computation")
  }
  
  if (now < TS) {
    stop("TS must be greater than the current time")
  }
  
  # make a vector to hold the results
  vars <- rep(0, n)

  # default is not age dependent, will change this later
  AD <- FALSE

  # make rate a function if it is a constant
  if (is.numeric(rate)) {
    r <- rate
    rate <- Vectorize(function(t) r)
  }
  
  # same for shape
  if (!is.null(shape)) {
    AD <- TRUE
    if (is.numeric(shape)) {
      s <- shape
      shape <- Vectorize(function(t) s)
    }
  }

  # if tMax is Inf, need another upper for uniroot
  upper <- ifelse(tMax == Inf, 10 * now + 10, tMax)
  
  for (i in 1:n) {
    # draw an uniform random variable from 0 to 1
    p <- runif (1)

    if (AD) {
      # if it is age dependent, find the current species time
      spnow <- now - TS

      # calculate the probability that the event will happen at all
      total <- 1 - exp(-(integrate(
        Vectorize(function(x) 1/rate(x + TS)), lower = spnow, 
        upper = upper - TS, subdivisions = 2000)$value) ^ shape(upper))

      # if the probability is lower than p, the event will not happen
      if (total < p & fast) {
        vars[i] <- tMax + 0.01
      }

      else {

        # create a function to hold the CDF of the distribution minus the
        # uniform variable - if we find t where this is 0, this t is
        # distributed as a weibull
        f <- Vectorize(function(t) 
          {
          1 - p - exp(-(integrate(Vectorize(function(x) 1/rate(x + TS)), 
                                  lower = spnow, upper = t, 
                                  subdivisions = 2000)$value) ^ shape(t))})

        # if f(t) = 0, t is distributed as a Weibull
        vars[i] <- suppressWarnings(uniroot(f, c(spnow, upper), 
                                            extendInt="yes"))$root - spnow
        
        # if rate is really high and the integral goes to +-infinity (computationally
        # speaking), uniroot substitutes it for a really high/low value instead. Since
        # this does not change our results, we accept it and simply suppress the warning
      }
    }
    else {
      # calculate the probability that the event will happen at all
      total <- 1 - exp(-integrate(Vectorize(function(x) rate(x)), 
                                  lower = now, upper = upper, 
                                  subdivisions = 2000)$value)
      
      # if the probability is lower than p, the event will not happen
      if (total < p & fast) {
        vars[i] <- tMax + 0.01
      }
      
      else {
        # if f(t) = 0, t is exponentially distributed
        f <- Vectorize(function(t) {
          1 - p - exp(-integrate(Vectorize(function(x) rate(x)), lower = now, 
                                 upper = t, subdivisions = 2000)$value)})

        # if rate is really high and the integral goes to +-infinity (computationally
        # speaking), uniroot substitutes it for a really high/low value instead. Since
        # this does not change our results, we accept it and simply suppress the warning
        vars[i] <- suppressWarnings(uniroot(f, c(now, upper), 
                                            extendInt="yes"))$root - now
      }
    }
  }
  return(vars)
}
