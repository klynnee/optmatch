# Optmatch: Optimal Fullmatching for R

The `optmatch` package implements the optimal full matching algorithm for
bipartite matching problems. Given a matrix describing the distances between
two groups (where one group is represented by row entries, and the other by
column entries), the algorithm finds a matching between units that
minimizes the average within grouped distances. This algorithm is a popular
choice for covariate balancing applications (e.g. propensity score matching),
but it also can be useful for design stage applications such as blocking. For
more on the application and its implementation, see:

    Hansen, B.B. and Klopfer, S.O. (2006) Optimal full matching and
     related designs via network flows, JCGS 15 609-627.

`optmatch` is available on [CRAN](http://cran.r-project.org):

    > install.packages("optmatch")
    > library("optmatch")

## Using Optmatch

In addition to the optimal full matching algorithm, the package contains
useful functions for generating distance specifications, combining and editing
distance specifications, and summarizing and displaying matches. This walk
through shows how to use these tools in your matching workflow.

### Simulated data

Before we start, let's generate some simulated data. We will have two groups,
the "treated" and "control" groups. Without our knowledge, nature assigned
units from a pool into one of these two groups. The probability of being a
treated unit depends on some covariates. In the vector `Z`, let a 1 denote
treated units and 0 denote control units

    set.seed(20120111) # set this to get the exact same answers as I do
    n <- 26 # chosen so we can divide the alphabet in half
    W <- data.frame(w1 = rbeta(n, 4, 2), w2 = rbinom(n, 1, p = .33))

    # nature assigns to treatment
    tmp <- numeric(n)
    tmp[sample(1:n, prob = W$w1^(1 + W$w2), size = n/2)] <- 1
    W$z <- tmp

    # for convenience, let's give the treated units capital letter names
    tmp <- character(n)
    tmp[W$z == 1] <- LETTERS[1:(n/2)]
    tmp[W$z == 0] <- letters[(26 - n/2 + 1):26]
    rownames(W) <- tmp

As we can see with a simple table and plot, these groups are not balanced on
the covariates, as they would be (in expectation) with a randomly assigned
treatment.

    table(W$w2, W$z)
    library(lattice) ; densityplot(W$w1, groups = W$z)

The next steps use the covariates to pair up similar treated and control
units. For more on assessing the amount and severity of imbalance between
groups on observed covariates, see the
[RItools](http://github.com/markmfredrickson/RItools) `R` package.

### Setting up distances

These two groups are different, but how different are individual treated units
from individual control units? In answering this question, we will produce
several distance specifications: matrices of treated units (rows) by control
units (columns) with entries denoting distances. `optmatch` provides several
ways of generating these matrices so that you don't have to do it by hand.

Let's begin with a simple Euclidean distance on the space defined by `W`:

    distances <- list()
    distances$euclid <- match_on(z ~ w1 + w2, data = W, method = "euclidean")

The `method` argument tells the `match_on` function how to compute the
distances over the space defined by the formula. The default method extends the
simple Euclidean distance by rescaling the distances by the covariance of the
variables, the [Mahalanobis
distance](http://en.wikipedia.org/wiki/Mahalanobis_distance):

    distances$mahal <- match_on(z ~ w1 + w2, data = W)

You can write additional distance computation functions. See the documentation
for `match_on` for more details on how to create these functions.

To create distances, we could also try regressing the treatment indicator on
the covariates and computing the difference distance for each treated and
control pair. To make this process easier, `match_on` has methods for `glm`
objects (and for big data problems, `bigglm` objects):

    propensity.model <- glm(z ~ w1 + w2, data = W, family =
      binomial())
    distances$propensity <- match_on(propensity.model)

The `glm` method is a wrapper around the `numeric` method for `match_on`. The
`numeric` method takes a vector of scores (for example, the linear prediction
for each unit from the model) and a vector indicating treatment status (`z`)
for each unit. This method returns the absolute difference between each
treated and control pair on their scores (additionally, 
the `glm` method rescales the data before invoking the `numeric` method). If
you wish to fit a "caliper" to your distance matrix, a hard limit on allowed
distances between treated and control units, you can pass a `caliper`
argument, a scalar numeric value. Any treated and control pair that is larger
than the caliper value will be replaced by `Inf`, an unmatchable value. The
`caliper` argument also applies to `glm` method. Calipers are covered in more
detail in the next sction.

The final convenience method of `match_on` is using an arbitrary function. This
function is probably most useful for advanced users of `optmatch`. See the
documentation of the `match_on` function for more details on how to write your
own arbitrary computation functions. 

### Combining and editing distances

We have created several representations of the matching problem, using
Euclidean distance, Mahalanobis distance, the estimated propensity score, and
an arbitrary function. We can combine these distances into single metric using
standard arithmetic functions:

    distances$all <- with(distances, euclid + mahal + propensity)

You may find it convenient to work in smaller pieces at first and then stitch
the results together into a bigger distance. The `rbind` and `cbind` functions let us
add additional treated and control entries to a distance specification for
each of the existing control and treated units, respectively. For example, we
might want to combine a Mahalanobis score for units `n` through `s` with a
propensity score for units `t` through `z`:

    W.n.to.s <- W[c(LETTERS[1:13], letters[14:19]),]
    W.t.to.z <- W[c(LETTERS[1:13], letters[20:26]),]
    mahal.n.to.s <- match_on(z ~ w1 + w2, data = W.n.to.s)
    ps.t.to.z <- match_on(glm(z ~ w1 + w2, data = W.t.to.z, family = binomial()))
    distances$combined <- cbind(mahal.n.to.s, ps.t.to.z)

The `exactMatch` function creates "stratified" matching problems, in which
there are subgroups that are completely separate. Such matching problems are
often much easier to solve than problems where a treated unit could be
connected to any control unit.

There is another method for creating reduced matching problems. The `caliper`
function compares each entry in an existing distance specification and
disallows any that are larger than a specified value. For example, we can trim
our previous combined distance to anything smaller than the median value:

    distances$median.caliper <- caliper(distances$all, median(distances$all))
    distances$all.trimmed <- with(distances, all + median.caliper)

Like the `exactMatch` function, the results of `caliper` used the sparse
matrix representation mentioned above, so can be very efficient for large,
sparse problems. As noted previously, if using the `glm` or `numeric` methods
of `match_on`, passing the caliper's width in the `caliper` argument can be more
efficient.

### Speeding up computation

In addition to the space advantages of only storing the finite entries in a
sparse matrix, the results of `exactMatch` and `caliper` can be used to speed
up computation of *new* distances. The `match_on` function that we saw earlier
has an argument called `within` that helps filter the resulting
computation to only the finite entries in the `within` matrix. Since `exactMatch` and `caliper`
use finite entries denote valid pairs, they make excellent sources of
the `within` argument.

Instead of creating the entire Euclidean distance matrix and *then* filtering
out cross-strata matches, we use the results of `exactMatch` to compute only
the interesting cases:

    tmp <- exactMatch(z ~ w2, data = W) 
    distances$exact <- match_on(z ~ w1, data = W, within = tmp)

Users of previous versions of `optmatch` may notice that the `within`
argument is similar to the old `structure.formula` argument. Like
`within`, `structure.formula` focused distance on within strata pairs.
Unlike `structure.formula`, the `within` argument allows using *any*
distance specification as an argument, including those created with `caliper`. For
example, here is the Mahalanobis distance computed only for units that differ
by less than one on the propensity score.

    distances$mahal.trimmed <- match_on(z ~ w1 + w2, data = W,
      within = match_on(propensity.model, caliper = 1))

### Generating the match

Now that we have generated several distances specifications, let's put them to
use. Here is the simplest way to evaluate all distances specifications:

    matches <- lapply(distances, function(x) { fullmatch(x, data = W) })

The result of the matching process is a named factor, where the names
correspond to the units (both treated and control) and the levels of the
factors are the matched groups. Including the `data` argument is highly
recommended. This argument will make sure that the result of `fullmatch` will
be in the same order as the original `data.frame` that was used to build the
distance specification. This will make appending the results of `fullmatch`
on to the original `data.frame` much more convenient.

The `fullmatch` function as several arguments for fine tuning the allowed
ratio of treatment to control units in a match, and how much of the pool to
throw away as unmatchable. One common pattern for these arguments are pairs:
one treated to one control unit. Not every distance specification is amendable
to this pattern (e.g. when there are more treated units than control units in
`exactMatch` created stratum). However, it can be done with the Mahalanobis
distance matrix we created earlier:

    mahal.match <- pairmatch(distances$mahal, data = W)

Like `fullmatch`, `pairmatch` also allows fine tuning the ratio of matches to
allow larger groupings. It is can be helpful as it computes what percentage of
the group to throw away, giving better odds of successfully finding a matching
solution.

Once one has generated a match, you may wish to view the results. The results
of calls to `fullmatch` or `pairmatch` produce `optmatch` objects (specialized
factors). This object has a special option to the `print` method which groups
the units by factor level:

    print(mahal.match, grouped = T)

If you wish to join the match factor back to the original `data.frame`: 

    W.matched <- cbind(W, matches = mahal.match)

Make sure to include the `data` argument to `fullmatch` or `pairmatch`,
otherwise results are not guaranteed to be in the same order as your original
`data.frame` or `matrix`. 


##  Using a development version of Optmatch

This section will help you get the latest development version of `optmatch` and
start using the latest features. Before starting, you should know which branch
you wish to install. Currently, the "master" branch is the main code base.
Additional features are added in their own branches. A list of branches is
available at (the optmatch project
page)[http://github.com/markmfredrickson/optmatch].

### Fetching and installing in a local directory

Chances are you already have an installation of `optmatch` that you use. These
directions will install the development version in a way that will not
overwrite your existing installation.

You must have the Fortran extensions for package building included. These can
be had from CRAN: [OS X](http://cran.r-project.org/bin/macosx/tools/),
[Windows](http://cran.r-project.org/bin/windows/Rtools/). You will also need a
copy of GNU `make` to create the package from source (standard on Linux,
included with [Apple's developer tools](http://developer.apple.com), included
with the [Cygwin](http://www.cygwin.com/) UNIX tools for Windows).

When these packages are installed, download a `.zip` of the `optmatch`
source, which is available from [the project download
tab](https://github.com/markmfredrickson/optmatch/archive/master.zip). Unzip
the package in a directory.

Alternatively, if you have a working installation of `git`
and all the software mentioned in the previous section, you can checkout a
copy of the source direclty.  Instead of downloading
the source directly, fork the project and github and clone a working copy from
your forked project:

    $ git clone git@github.com:YOURUSERNAME/optmatch.git

To download all dependencies and create a bundled package:

    $ cd /path/to/package
    $ make package

This should build a `optmatch_VERSION.tar.gz` file. You can install it in a
local directory (for example `~/R/optmatch.demo`) using:

    $ mkdir -p ~/R/optmatch.demo
    $ R CMD Install --no-multiarch --library=~/R/optmatch.demo ./optmatch_VERSION.tar.gz

You can then load the library in `R` using:

    > library("optmatch", lib.loc = "~/R/optmatch.demo") 

### Developing for Optmatch


We prefer changes that include unit tests demonstrating the problem or showing
how the new feature should be added. The test suite uses the
[testthat](http://github.com/hadley/test_that) package to write and run tests.
See the `inst/tests` directory for examples. To run the test suite, use:

    $ make test

New features should include documentation. We prefer inline
[Roxygen](http://roxygen.org/) style documentation to raw `.Rd` files. Any
`Makefile` task that builds the package will create the documentation. These
tasks are also useful for development:

- `R`: starts up an interactive session with `optmatch` loaded.
- `spell`: checks the spelling of all Rd files in the package using the
  []`aspell_*`
  functions](http://stat.ethz.ch/R-manual/R-patched/library/utils/html/aspell-utils.html)
  in the 'utils' package. - `check`: runs `R CMD Check` on a built package, includes the `test` and `spell` tasks
- `package`: creates a `tar.gz` of the package
- `check`: runs `R CMD check` on the package

If you need to edit the `DESCRIPTION` file (e.g. to add a suggested package),
edit `DESCRIPTION.template` instead. This file is used during the build process
to insert the version and date information.

You will need to have the `aspell` program installed and available on your
`$PATH` in order to use the `spell` task. If you introduce new words that are
not coveraged in the standard English dictionary, you can add them to the
`lexicon.txt` file. There is also a task to create the lexicon from all found
misspelled words (`make lexicon.txt`).  For more information on the use of
spell checkers in R, see [Watch your
spelling!](http://journal.r-project.org/archive/2011-2/RJournal_2011-2_Hornik+Murdoch.pdf)
in the R journal.

When your change is ready, make a pull request on github.

