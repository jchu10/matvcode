function limitedData = set_inclusion(data, include, reason)
% Replicates data struct with each field including only the 'include'
% indices
%
% data: a struct with all values taking one of the following forms:
%           1D arrays of length N (cell or numeric arrays)
%           multidimensional arrays of first dimension length N
% include: a 1D logical array of length N; true means that the
%   corresponding values in each data field will be preserved
%
% limitedData: a struct with all of the same fields as data, all of whose
%   values have been indexed by 'include' (so that N is now sum(include))
%   Any 1xN fields will also be changed to Nx1.
%    
% limitedData updates these additional fields or adds them if needed:
%     origData: the data structure we started out with, before any
%       exclusion. If this field already exists it's left unchanged 
%       except that any new fields in data but not origData are added
%       (values for the records not in data are NaN or empty).
%       otherwise it's just data. origData.reasonExcluded is updated to 
%       label excluded indices with 'reason'
%     indsIntoOrig: a vector of length N giving the indices of the current
%        records in limitedData.origData

limitedData = struct();

if isfield(data, 'userid')
    nRecords = length(data.userid);
else
    fields = fieldnames(data);
    nRecords = length(data.(fields{1}));
end



fields = fieldnames(data);

for iF = 1:length(fields)
    old = getfield(data, fields{iF});
    
    % Skip the origData and indsIntoOrig fields for now
    if any(strcmp(fields{iF}, {'origData', 'indsIntoOrig'}))
        continue;
    end
    
    % cell array with arrays inside it
    if iscell(old) && length(old{1}) == nRecords && ~ischar(old{1}) 
        new = {};
        for i = 1:length(old) % 2D array--index 1st dimension
            if size(old{i},2) > 1 && size(old{i},1) > 1 
                new{i} = old{i}(include,:);
            else % 1D array
                disp(fields{iF});
                disp(old{i})
                new{i} = old{i}(include(:));
            end
        end
        limitedData = setfield(limitedData, fields{iF}, new);
    elseif size(old,2) > 1 && size(old,1) > 1 % 2D array--index 1st dimension
        limitedData = setfield(limitedData, fields{iF}, old(include,:));
    else % 1D array
        limitedData = setfield(limitedData, fields{iF}, old(include(:)));
    end
end

% Add the 'origData' field if necessary (first exclusion)
if isfield(data, 'origData') % Already have one?

    % Add it, unchanged, to the current data struct
    limitedData = setfield(limitedData, 'origData', data.origData);
    % How many records in origData?
    if isfield(data.origData, 'userid')
        nOrig = length(data.origData.userid);
    else
        fields = fieldnames(data.origData);
        nOrig = length(data.origData.(fields{1}));
    end

    % For any fields that data has but origData doesn't, add them to origData
    dataFields = fieldnames(data);
    origFields = fieldnames(data.origData);
    fieldsToAdd = setdiff(dataFields, ...
        {origFields{:}, 'reasonExcluded', 'origData', 'indsIntoOrig'});

    for iField = 1:length(fieldsToAdd)
        fieldData = data.(fieldsToAdd{iField});

        if size(fieldData, 1) == 1 || size(fieldData, 2) == 1
            fieldData = fieldData(:);
        end

        if iscell(fieldData)
            origFieldData = cell(nOrig, size(fieldData,2));
        else
            origFieldData = nan(nOrig, size(fieldData,2));
        end

        if size(fieldData, 1) == 1 || size(fieldData, 2) == 1
            origFieldData(data.indsIntoOrig) = fieldData;
        else
            origFieldData(data.indsIntoOrig, :) = fieldData;
        end

        limitedData.origData.(fieldsToAdd{iField}) = origFieldData;
    end
    

else % Need to start out
    data.indsIntoOrig = 1:nRecords;
    limitedData = setfield(limitedData, 'origData', data);
    
    limitedData.origData.reasonExcluded = cell(1, nRecords);
end

% Add the reason these records were excluded, if given
if nargin > 2
    if any(~include)
        for i = find(~include(:)')
            if iscell(reason)
                r = reason{i};
            else
                r = reason;
            end
            limitedData.origData.reasonExcluded{data.indsIntoOrig(i)} = r;
        end
    end
end

% Only now update indsIntoOrig (want original indices for update above)
limitedData.indsIntoOrig = data.indsIntoOrig(include);

