# simulate some example data for the correlation/scatter vis

simData <-
function(n.ind=500, n.var=50, n.groups=3)
{
  group <- sample(1:n.groups, n.ind, repl=TRUE)
  qtleff <- sample(c(-1, 1), n.var, repl=TRUE)*runif(n.var, 0.5, 3)
  qtleff <- matrix(rep(qtleff, n.ind), nrow=n.ind, byrow=TRUE)
  err <- rnorm(n.ind, 0, 0.3)
  V <- matrix(0.3, ncol=n.var, nrow=n.var)
  diag(V) <- 1
  x <- matrix(rnorm(n.var*n.ind), ncol=n.var) %*% chol(V) + err + qtleff * group
  dimnames(x) <- list(paste0("ind", 1:n.ind), paste0("gene", 1:n.var))
  names(group) <- rownames(x)

  list(x=x, group=group)
}
