function strCell = strsplit_empty(s, sep)

if isempty(s)
    strCell = {};
else
    strCell = strsplit(s, sep);
end