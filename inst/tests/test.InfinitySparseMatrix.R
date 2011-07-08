################################################################################
### Tests for the InfinitySparseMatrix class
###############################################################################
library(testthat)

context("InfinitySparseMatrix tests")

test_that("ISM Basics", {
  A <- makeInfinitySparseMatrix(c(1,2,3), cols = c(1,2, 2), rows = c(1,1,2))
  expect_is(A, "InfinitySparseMatrix")
  expect_equal(dim(A), c(2,2))
  
  # converting to the equivalent matrix
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  expect_equivalent(as.matrix(A), m)

  # converting from a matrix to a ISM
  expect_equivalent(as.InfinitySparseMatrix(m), A)
  # and back again
  expect_equivalent(as.matrix(as.InfinitySparseMatrix(m)), m)
  # expect_equal(as(m, "InfinitySparseMatrix"), A)

  # a more complicated examples, missing an entire row/col
  w <- matrix(c(1,Inf,2, 3, Inf, 4), nrow = 3)
  B <- as.InfinitySparseMatrix(w)
  expect_equivalent(as.matrix(B), w)

  y <- matrix(c(1,2,3,Inf, Inf, Inf), nrow = 3)
  D <- as.InfinitySparseMatrix(y)
  expect_equivalent(as.matrix(D), y)

  # the as() technique should be equivalent
  expect_equivalent(as(D, "matrix"), y)
  expect_equivalent(A, as(m, "InfinitySparseMatrix"))

})

test_that("ISM Handles Names", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  rownames(m) <- c("A", "B")
  colnames(m) <- c("C", "D")

  expect_equal(as.matrix(as(m, "InfinitySparseMatrix")), m)
  
})

test_that("Math Ops", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  A <- as.InfinitySparseMatrix(m)

  # scalar math
  expect_equivalent(as.matrix(A + 1), m + 1)
  expect_equivalent(as.matrix(A - 1), m - 1)
  expect_equivalent(as.matrix(A * 2), m * 2)
  expect_equivalent(as.matrix(A / 2), m / 2)
  
  # matrix element wise math
  expect_equivalent(as.matrix(A + A), m + m)

  # Inf - Inf or Inf / Inf gives NA
  mm <- m - m
  mm[is.na(mm)] <- Inf

  md <- m / m
  md[is.na(md)] <- Inf

  expect_equivalent(as.matrix(A - A), mm)
  expect_equivalent(as.matrix(A * A), m * m)
  expect_equivalent(as.matrix(A / A), md)

  # The harder case is when the matrix has non-identical row/col ids

  q <- matrix(c(1, 2, Inf, 4), nrow = 2, ncol = 2)
  B <- as.InfinitySparseMatrix(q)

  expect_equivalent(as.matrix(A + B), m + q)
  expect_equivalent(as.matrix(A * B), m * q)

  # TODO, make up temp matrices for sub and div

  # dense + sparse => sparse
  Aq = A + q
  expect_is(Aq, "InfinitySparseMatrix")
  expect_equivalent(as.matrix(Aq), m + q)

  # make sure it works the other direction (and with mult)
  qA = q * A
  expect_is(qA, "InfinitySparseMatrix")
  expect_equivalent(as.matrix(qA), q * m)

  # names should be sticky across arithmatic
  # TODO, math should reorder by names in case that changes things
  colnames(A) <- paste("C", 1:2, sep = "")
  rownames(A) <- paste("T", 1:2, sep = "")
  colnames(q) <- paste("C", 1:2, sep = "")
  rownames(q) <- paste("T", 1:2, sep = "")

  Aq = A + q
  expect_equal(colnames(Aq), c("C1", "C2"))
  expect_equal(rownames(Aq), c("T1", "T2"))

})

test_that("Subsetting", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  rownames(m) <- c("A", "B")
  colnames(m) <- c("C", "D")
  A <- as.InfinitySparseMatrix(m)
  
  res.sub <- subset(A, A == 2)
  expect_equal(res.sub@.Data, 2)
  expect_equal(res.sub@cols, 2)
  expect_equal(res.sub@rows, 1)

})

test_that("cbinding ISMs and matrices", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  rownames(m) <- c("A", "B")
  colnames(m) <- c("C", "D")
  A <- as.InfinitySparseMatrix(m)

  res.AA <- cbind(A, A)
  expect_equal(length(res.AA), 6)
  expect_equal(dim(res.AA), c(2, 4))

  res.Am <- cbind(A, m)
  expect_equal(res.Am, res.AA)
  
  m2 <- m
  rownames(m2) <- c("B", "A")
  res.Am2 <- cbind(A, m2)
  m3 <- matrix(c(1,Inf,2,3, Inf, 1, 3,2), nrow = 2)
  rownames(m3) <- c("A", "B")
  colnames(m3) <- c("C", "D", "C", "D") # this seems like a bad idea!
  expect_equal(as.matrix(res.Am2), m3)

  m4 <- matrix(1, nrow = 2, ncol = 3)
  rownames(m4) <- c("A", "C")
  colnames(m4) <- c("X", "Y", "Z")
  expect_error(cbind(A, m4))

  m5 <- matrix(1, nrow = 3, ncol = 2)
  rownames(m5) <- c("A", "B", "C")
  colnames(m5) <- c("X", "Y")
  expect_error(cbind(A, m5))

})

test_that("rbinding ISMs and matrices", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  rownames(m) <- c("A", "B")
  colnames(m) <- c("C", "D")
  A <- as.InfinitySparseMatrix(m)

  res.AA <- rbind(A, A)
  expect_equal(length(res.AA), 6)
  expect_equal(dim(res.AA), c(4,2))

  res.Am <- rbind(A, m)
  expect_equal(res.Am, res.AA)
  
  m2 <- m
  colnames(m2) <- c("D", "C")
  res.Am2 <- rbind(A, m2)
  m3 <- matrix(c(1,Inf,2,3,2,3,1,Inf), ncol = 2)
  rownames(m3) <- c("A", "B", "A", "B")
  colnames(m3) <- c("C", "D")
  expect_equal(as.matrix(res.Am2), m3)

  m4 <- matrix(1, nrow = 2, ncol = 2)
  rownames(m4) <- c("A", "B")
  colnames(m4) <- c("X", "Y")
  expect_error(rbind(A, m4))

  m5 <- matrix(1, nrow = 2, ncol = 3)
  rownames(m5) <- c("A", "B")
  colnames(m5) <- c("C", "D", "E")

  expect_error(rbind(A, m5))

})


test_that("t(ransform) function", {
  m <- matrix(c(1,Inf, 2, 3), nrow = 2, ncol = 2)
  rownames(m) <- c("A", "B")
  colnames(m) <- c("C", "D")
  A <- as.InfinitySparseMatrix(m)

  expect_equal(as.matrix(t(A)), t(m))
  
})
