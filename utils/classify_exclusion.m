function [classified, labels, counts] = classify_exclusion(criteria, displayFormat)
% Give each unique string in 'criteria' its own ID and displays mapping
%
% [classified, labels] = classify_exclusion(criteria[, displayFormat])
%
% criteria: cell array of strings or array of numbers
% displayFormat: show (1) or hide (0) the unique categories and counts
%
% labels: (cell) array of unique values in criteria
% classified: double array (same length as criteria) such that 
%   criteria{i} = labels{classified(i)}
%
% Strips whitespace and casts to lowercase.


if nargin < 2
    displayFormat = 1; % long
end

if iscell(criteria)
    criteria = lower(strtrim(criteria));
end

[labels, ~, classified] = unique(criteria);

if displayFormat
    fprintf(1, '\n');
    for i = 1:length(labels)
        if iscell(labels)
            fprintf(1, '\t %i \t %s \n', sum(strcmp(criteria, labels{i})), labels{i});
        else
            fprintf(1, '\t %i \t %i \n', sum(criteria==labels(i)), labels(i));
        end
    end
end

if nargout > 2 
    counts = zeros(size(labels));
    for i = 1:length(labels)
        counts(i) = sum(classified==i);
    end
end