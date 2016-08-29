function mark_significance(barStarts, pVals, labelColor)
% Utility to display significance level of p-values on a plot; used in 
% Testimony_Lookit.
%
% barStarts: centers of bars on x-axis
% pVals: 1D array of same size as barStarts with the p-values to display
% labelColor: color descriptor for the text
%
% Text is displayed a fixed distance to the left of center and at y=0.15.
% Levels are ***, **, *, marginal (show p values under 0.25), ns.
    
    for i = 1:length(barStarts)
        if pVals(i) < 0.005
            textP = '***';
        elseif pVals(i) < 0.01
            textP = '**';
        elseif pVals(i) < 0.05
            textP = '*';
        elseif pVals(i) < 0.2
            textP = ['p=' num2str(pVals(i),2)];
        else
            textP = 'ns';
        end
        text(barStarts(i)-.3, .15, textP, 'Color', labelColor);
    end
    
end