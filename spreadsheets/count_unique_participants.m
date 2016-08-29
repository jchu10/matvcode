function [n, index] = count_unique_participants(data)
% Count the number of unique participants in the data structure
%
% [n, index] = count_unique_participants(data)
%
% data is a structure with at least fields userid and childid. userid
% should be an array of user ID numbers of length N; childid is a cell
% array of strings, of length N. Each element 1:N corresponds to one
% record. n is the number of unique id, child pairs. index indexes into
% fields of data to pick out each participant exactly once.
%
% Empty child ID strings are treated as 'child0'. Quotes in child ID
% strings are ignored (so '"child1"' is the same as 'child1').

ids = data.userid;
chs = data.childid;

comb = cell(size(ids));
for i = 1:length(ids)
    if isempty(chs{i})
        child = 'child0';
    else
        if chs{i}(1) == '"'
            child = chs{i}(2:end-1);
        else
            child = chs{i};
        end
    end
    comb{i} = [num2str(ids(i)), child];
end

[u, index] = unique(comb);

n = length(u);

