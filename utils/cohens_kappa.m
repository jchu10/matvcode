function [kappa, agree] = cohens_kappa(judgeA, judgeB)
% Compute fraction agreement and Cohen's kappa for two judgement arrays
%
% [kappa, agree] = cohens_kappa(judgeA, judgeB)
%
% judgeA, judgeB should be binary judgements (0/1 or false/true) of the 
% same dimensions.
%
% kappa: Cohen's kappa statistic for agreement controlling for chance
% agree: Fraction agreement, raw
%
% Use caution if judgements may contain NaN values. NaN values are counted 
% as not agreeing but are not used in computing fraction of chance
% agreement.

judgeA = judgeA(:);
judgeB = judgeB(:);

agree = sum(judgeA == judgeB) / length(judgeA);
fracA = nansum(judgeA) / sum(~isnan(judgeA));
fracB = nansum(judgeB) / sum(~isnan(judgeB));
agreeChance = fracA * fracB + (1-fracA) * (1 - fracB);
kappa = (agree - agreeChance) / (1 - agreeChance);
if agreeChance == 1
    kappa = 0;
end