function p = chisquare(countsA, countsB)
% countsA: [cat1, cat2]

% http://www.mathworks.com/matlabcentral/answers/96572-how-can-i-perform-a-chi-square-test-to-determine-how-statistically-different-two-proportions-are-in
N1 = sum(countsA);
N2 = sum(countsB);

% Pooled estimate of proportion

p0 = (countsA(1) + countsB(1)) / (N1 + N2);

% Expected counts under H0 (null hypothesis)

n10 = sum(countsA) * p0;

n20 = sum(countsB) * p0;

% Chi-square test, by hand

observed = [countsA(:)', countsB(:)'];

expected = [n10, N1-n10, n20, N2-n20];

chi2stat = sum((observed-expected).^2 ./ expected);

p = 1 - chi2cdf(chi2stat,1);