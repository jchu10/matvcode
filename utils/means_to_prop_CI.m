function CI = means_to_prop_CI(meanA, steA, meanB, steB, alpha, N)
% Compute [proportion meanA/(meanA + meanB], alpha/2 percentile, 1-alpha/2 percentile,
% standard deviation of proportion] based on assuming meanA and meanB are 
% normally distributed with standard deviations steA and steB respectively.
% Uses N samples.

sampsA = meanA + steA .* randn(N, 1);
sampsB = meanB + steB .* randn(N, 1);
props  = sampsA ./ (sampsA + sampsB);

actualProp = meanA / (meanA + meanB);

CI = [actualProp, prctile(props, [100*alpha/2, 100-100*alpha/2]), std(props)];

end