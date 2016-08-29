function [ coded ] = select_coding( useCoder, data, fieldname )
% Returns data.[useCoder{i} fieldname] for each record
%
% [ coded ] = select_coding( useCoder, data, fieldname )
%
% useCoder: cell array of coders to use for each file, indexed as
%   data.filenames etc.
% data: a struct as created by read_lookit_results_xls, with at least the
%    fields that will be accessed by this call, each of which should be a 
%    CELL ARRAY OF STRINGS of the same length as useCoder
% fieldname: the base fieldname we're looking for, e.g. 'F3'
%
% This is a simple utility to read the appropriate coder's mark from 
% a data structure created by reading a Lookit spreadsheet. For instance, 
% if we had three records and wanted to look up clip3cleaned using
% Annie's coding for the first two and Junyi's for the third, we could call
% select_coding({'Annie', 'Annie', 'Junyi'}, data, 'clip3cleaned'). 
% The result might be something like {'correct', 'incorrect', 'correct'},
% and the first two values would have come from the field
% 'Annieclip3cleaned' while the third came from 'Junyiclip3cleaned'.

coded = {};

for i = 1:length(useCoder)
    if data.useCoder{i}
        coded{i} = data.([useCoder{i}, fieldname]){i};
    else
        coded{i} = '';
    end
end

coded = coded';

end