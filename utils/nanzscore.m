function z = nanzscore(v)

z = (v - nanmean(v)) / nanstd(v);