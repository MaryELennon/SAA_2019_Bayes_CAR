//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// https://github.com/stan-dev/example-models/blob/master/knitr/car-iar-poisson/bym2.stan
//


data {
  int<lower=0> N;
  int<lower=0> N_test;
  int<lower=0> N_edges;
  int<lower=1, upper=N> node1[N_edges];  // node1[i] adjacent to node2[i]
  int<lower=1, upper=N> node2[N_edges];  // and node1[i] < node2[i]

  int<lower=0> y[N];                     // count outcomes
  vector<lower=0>[N] E;                  // exposure
  //vector<lower=0>[N_test] E_test;                  // exposure
  int<lower=1> K;                        // num covariates
  matrix[N, K] x;                        // design matrix
  matrix[N_test, K] x_test;                        // design matrix

  real<lower=0> scaling_factor; // scales the variance of the spatial effects
}
transformed data {
  vector[N] log_E = log(E);
  //vector[N_test] log_E_test = log(E_test);
}
parameters {
  real beta0;            // intercept
  vector[K] betas;       // covariates

  real<lower=0> sigma;        // overall standard deviation
  real<lower=0, upper=1> rho; // proportion unstructured vs. spatially structured variance

  vector[N] theta;       // heterogeneous effects
  vector[N_test] theta_test;       // heterogeneous effects
  
  vector[N] phi;         // spatial effects
  vector[N_test] phi_test;         // spatial effects
}
transformed parameters {
  vector[N] convolved_re;
  vector[N_test] convolved_re_test;
  
  // variance of each component should be approximately equal to 1
  convolved_re =  sqrt(1 - rho) * theta + sqrt(rho / scaling_factor) * phi;

  convolved_re_test =  sqrt(1 - rho) * theta_test + sqrt(rho / scaling_factor) * phi_test;
}
model {
  y ~ poisson_log(log_E + beta0 + x * betas + convolved_re * sigma);  // co-variates

  // This is the prior for phi! (up to proportionality)
  target += -0.5 * dot_self(phi[node1] - phi[node2]);

  beta0 ~ normal(0.0, 1.0); // og = 1
  betas ~ normal(0.0, 1.0); // og = 1
  theta ~ normal(0.0, 1.0); // og = 1 // this is what moves rho to right
  sigma ~ normal(0.0, 1.0);   // og = 1
  rho ~ beta(0.5, 0.5);
  // soft sum-to-zero constraint on phi)
  sum(phi) ~ normal(0, 0.001 * N);  // equivalent to mean(phi) ~ normal(0,0.001)
}
generated quantities {
  real logit_rho = log(rho / (1.0 - rho));
  vector[N] eta = log_E + beta0 + x * betas + convolved_re * sigma; // co-variates
  vector[N] mu = exp(eta);
  
  vector[N_test] eta_test = log(0.01) + beta0 + x_test * betas + convolved_re_test * sigma; // co-variates
  vector[N_test] mu_test = exp(eta_test);
 //vector[N_test] eta_test;
 //vector[N_test] mu_test;
 //for(i in 1:N_test) {
 //   eta_test[i]   = log(0.01) + beta0 + x_test[i] * betas + convolved_re_test[i] * sigma;
 //  mu_test[i]    = exp(eta_test[i]);
 //}

}

