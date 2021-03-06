################################################################################
# exactMatch: create InfinitySparseMatrices from factors
################################################################################

setGeneric("exactMatch", 
  def = function(x, ...) {
    tmp <- standardGeneric("exactMatch")
    tmp@call <- match.call()
    return(tmp) 
})

setMethod(exactMatch, "vector", function(x, treatment) {
  if (length(x) != length(treatment)) {
    stop("Splitting vector and treatment vector must be same length")  
  }

  # ham-handed way of saying, use x's names or use treatments's name
  # which ever is not null
  nms <- names(x)
  if (is.null(nms) & is.null(names(treatment))) {
    stop("Blocking or treatment factor must have names")  
  } else {
    if(is.null(nms)) {
      nms <- names(treatment)  
    }
  }

  # defensive programming
  x <- as.factor(x)
  treatment <- toZ(treatment)

  # the upper level is the treatment condition
  xT <- x[treatment]
  xC <- x[!treatment]

  csForTs <- lapply(xT, function(t) {
    which(t == xC)
  })

  cols <- unlist(csForTs)
  tmp <- sapply(csForTs, length)
  rows <- rep(1:(length(csForTs)), tmp)

  rns <- nms[treatment]
  cns <- nms[!treatment]

  tmp <- makeInfinitySparseMatrix(rep(0, length(rows)), cols = cols, rows =
    rows, rownames = rns, colnames = cns) 

  tmp <- as(tmp, "BlockedInfinitySparseMatrix")
  tmp@groups <- x
  names(tmp@groups) <- nms
  return(tmp)
})

setMethod(exactMatch, "formula", function(x, data = NULL, subset = NULL, na.action = NULL, ...) {
  # lifted pretty much verbatim from lm()
  mf <- match.call(expand.dots = FALSE)
  m <- match(c("data", "subset", "na.action"), names(mf), 0L)
  mf <- mf[c(1L, m)]
  mf$drop.unused.levels <- TRUE
  mf$formula <- x
  mf[[1L]] <- as.name("model.frame")

  mf <- eval(mf, parent.frame())

  blocking <- interaction(mf[,-1])
  treatment <- mf[,1]

  names(blocking) <- rownames(mf)
  names(treatment) <- rownames(mf)

  # formula is expected to be Z ~ B, where b is the blocking factor
  # and Z is treatment, Z ~ B1 + B2 ... is also allowed
  exactMatch(blocking, treatment) # use the factor based method
})
