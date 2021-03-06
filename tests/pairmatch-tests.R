require('optmatch')

data(plantdist)
# warnings about lacking data argument are expected
pairmatch(plantdist)
pairmatch(plantdist, controls=2)
## Not run: pairmatch(plantdist + caliper(plantdist, 1)) # Matching fails everywhere
pairmatch(plantdist + caliper(plantdist, 5, compare = `<`), remove.unmatchables=TRUE) # Matching works after removing plant 'F'

data(nuclearplants)
# in both of match_on calls below use sd to maintain backwards compatibility with
# pscore.dist, which used sd by default. match_on has used mad as the std. scale
# since it was added to the package, so the use of match_on should be consistent
# for users going forward.
psm <- glm(pr~.-(pr+cost), family=binomial(), data=nuclearplants)
psd <- match_on(psm, standardization.scale = sd)
pm <- pairmatch(psd, controls=2, data = nuclearplants)

# the pm match immediately above was giving slightly different answers in some environment
# the problem allowed multiple optimal solutions, and different choices were picked in different environments
# the sum of matched distances should be the same across all environments

summary(pm)$total.distance

# Also not run: again an error would be thrown (which R CMD CHECK does not like)
# pairmatch(caliper(match_on(psm, standardization.scale = sd,
#   within = exactMatch(pr ~ pt, data =
#   nuclearplants)), width=2)) # Fails in subclass '1'

