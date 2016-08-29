function export_to_csv(data, filename, includeFields)
% Utility to export data struct to a csv file for human to look through
%
% export_to_csv(data, filename, includeFields)
% 
% data: struct, as created by read_lookit_results_xls; needs at least
%    field DBID or age.
%
% filename: csv file to save (full path)
%
% includeFields: cell array of fields of data to include in the csv 
%    (in desired order). Prefixing a field with 'START_' will include 
%    all fields that start with this string.

fields = fieldnames(data);

if isfield(data, 'DBID')
    N = length(data.DBID);
else
    N = length(data.age);
end

vars = {}; % keep track of variables to save (N x cols)
varNames = {}; % and what to call them (col headers for csv file)
inds = []; % and the order they belong in

for iF = 1:length(fields)
    
    f = fields{iF};
    fieldMatch = strcmp(f, includeFields) | ... % either an exact match
        cellfun(@(s)(strncmp(s, 'START_', 6) && strncmp(s(7:end), f, length(s)-6)), includeFields);
        % ... or a start-of-string match if appropriate

    if any(fieldMatch)
        inds(end+1) = find(fieldMatch, 1);
        varNames{end+1} = f;
        thisField = data.(f);
        if numel(thisField) == N
            vars{end+1} = thisField(:);
        else
            thisField = data.(f);
            vars{end+1} = thisField;
        end
    end
end

% Then sort according to includeFields
[~, order] = sort(inds);
vars = vars(order);
varNames = varNames(order);

% Actually write the CSV file
t = table(vars{:}, 'VariableNames', varNames);
writetable(t,filename, 'QuoteStrings', true);

end