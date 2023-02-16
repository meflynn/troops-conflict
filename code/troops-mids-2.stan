// generated with brms 2.18.0
functions {
  /* integer sequence of values
   * Args:
   *   start: starting integer
   *   end: ending integer
   * Returns:
   *   an integer sequence from start to end
   */
  array[] int sequence(int start, int end) {
    array[end - start + 1] int seq;
    for (n in 1 : num_elements(seq)) {
      seq[n] = n + start - 1;
    }
    return seq;
  }
  // compute partial sums of the log-likelihood
  real partial_log_lik_lpmf(array[] int seq, int start, int end,
                            data array[] int Y, vector bQ, real Intercept,
                            data matrix XQ, data matrix Xs, vector bs,
                            data matrix Zs_1_1, vector s_1_1, real shape,
                            data array[] int J_1, data vector Z_1_1,
                            vector r_1_1) {
    real ptarget = 0;
    int N = end - start + 1;
    // initialize linear predictor term
    vector[N] mu = rep_vector(0.0, N);
    mu += Intercept + Xs[start : end] * bs + Zs_1_1[start : end] * s_1_1;
    for (n in 1 : N) {
      // add more terms to the linear predictor
      int nn = n + start - 1;
      mu[n] += r_1_1[J_1[nn]] * Z_1_1[nn];
    }
    ptarget += neg_binomial_2_log_glm_lpmf(Y[start : end] | XQ[start : end], mu, bQ, shape);
    return ptarget;
  }
}
data {
  int<lower=1> N; // total number of observations
  array[N] int Y; // response variable
  int<lower=1> K; // number of population-level effects
  matrix[N, K] X; // population-level design matrix
  // data for splines
  int Ks; // number of linear effects
  matrix[N, Ks] Xs; // design matrix for the linear effects
  // data for spline s(year)
  int nb_1; // number of bases
  array[nb_1] int knots_1; // number of knots
  // basis function matrices
  matrix[N, knots_1[1]] Zs_1_1;
  int grainsize; // grainsize for threading
  // data for group-level effects of ID 1
  int<lower=1> N_1; // number of grouping levels
  int<lower=1> M_1; // number of coefficients per level
  array[N] int<lower=1> J_1; // grouping indicator per observation
  // group-level predictor values
  vector[N] Z_1_1;
  int prior_only; // should the likelihood be ignored?
}
transformed data {
  int Kc = K - 1;
  matrix[N, Kc] Xc; // centered version of X without an intercept
  vector[Kc] means_X; // column means of X before centering
  // matrices for QR decomposition
  matrix[N, Kc] XQ;
  matrix[Kc, Kc] XR;
  matrix[Kc, Kc] XR_inv;
  array[N] int seq = sequence(1, N);
  for (i in 2 : K) {
    means_X[i - 1] = mean(X[ : , i]);
    Xc[ : , i - 1] = X[ : , i] - means_X[i - 1];
  }
  // compute and scale QR decomposition
  XQ = qr_thin_Q(Xc) * sqrt(N - 1);
  XR = qr_thin_R(Xc) / sqrt(N - 1);
  XR_inv = inverse(XR);
}
parameters {
  vector[Kc] bQ; // regression coefficients at QR scale
  real Intercept; // temporary intercept for centered predictors
  vector[Ks] bs; // spline coefficients
  // parameters for spline s(year)
  // standarized spline coefficients
  vector[knots_1[1]] zs_1_1;
  real<lower=0> sds_1_1; // standard deviations of spline coefficients
  real<lower=0> shape; // shape parameter
  vector<lower=0>[M_1] sd_1; // group-level standard deviations
  array[M_1] vector[N_1] z_1; // standardized group-level effects
}
transformed parameters {
  // actual spline coefficients
  vector[knots_1[1]] s_1_1;
  vector[N_1] r_1_1; // actual group-level effects
  real lprior = 0; // prior contributions to the log posterior
  // compute actual spline coefficients
  s_1_1 = sds_1_1 * zs_1_1;
  r_1_1 = sd_1[1] * z_1[1];
  lprior += normal_lpdf(bQ | 0, 2);
  lprior += normal_lpdf(Intercept | 0, 3);
  lprior += normal_lpdf(bs | 0, 2);
  lprior += student_t_lpdf(sds_1_1 | 3, 0, 2.5)
            - 1 * student_t_lccdf(0 | 3, 0, 2.5);
  lprior += gamma_lpdf(shape | 1, 1);
  lprior += normal_lpdf(sd_1[1] | 0, 3) - 1 * normal_lccdf(0 | 0, 3);
}
model {
  // likelihood including constants
  if (!prior_only) {
    target += reduce_sum(partial_log_lik_lpmf, seq, grainsize, Y, bQ,
                         Intercept, XQ, Xs, bs, Zs_1_1, s_1_1, shape, J_1,
                         Z_1_1, r_1_1);
  }
  // priors including constants
  target += lprior;
  target += std_normal_lpdf(zs_1_1);
  target += std_normal_lpdf(z_1[1]);
}
generated quantities {
  // obtain the actual coefficients
  vector[Kc] b = XR_inv * bQ;
  // actual population-level intercept
  real b_Intercept = Intercept - dot_product(means_X, b);
}

