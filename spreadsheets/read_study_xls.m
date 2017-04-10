function data = read_study_xls(xlsName, coderPreferenceList)
% Reads an excel spreadsheet with subject information about a study.
%
% data = read_study_xls(xlsName, coderPreferenceList)
%
% xlsName: full path to Excel file to read; has one header row and N data
% entries. The xls file should be saved in Excel 98 format (Excel 95 
% format required on Mac). It is essentially a CSV file: one header 
% row that names the fields and after that each row is one record. 
%
% coderPreferenceList (optional): ordered cell array of coders to use, in priority
% order. This will sort the entries in the field 'allcoders' if provided.
%
% data: a struct with field names according to the xls headers (with
% punctuation and special characters removed, but capitalization
% preserved: e.g. coded-Katy becomes codedKaty, user_id becomes userid). 
% Values of the fields are either a 1xN double array (when no
% nonnumeric data was found) or an Nx1 cell array (when at least one entry
% was not a number).
% 
% Several additional fields are added to data:
%   If 'allcoders' field is present, then each 'allcoders' entry
%      will be transformed from the string "['coder1', 'coder2', ...]" into
%      the cell array {'coder1', 'coder2', ...}. Additionally, the coders
%      will be sorted according to the priority listed in
%      coderPreferenceList, so that first come coders on that list in the
%      order they appear, and then come any coders not on the list in their
%      original order. 
%   If 'allcoders' fields is present, then a field 'useCoder'
%      is also created which is the first element of allcoders (after
%      transformation above).

[num,txt,raw]   = xlsread(xlsName);

firstLine = 2;
headers = txt(1,:);

data = struct();

for iH = 1:length(headers)
    h = headers{iH};
    % Assign this column to a same-name field of 'data' (with punctuation
    % removed)
    h(ismember(h, ' -:;,!?><.[]{}\|@~`$%^&*()+=/_')) = '';
    cellArray = raw(firstLine:end, iH);
    data = setfield(data, h, cellArray);
    % Based on the first nonempty field, choose to keep a cell array of
    % strings or convert to numeric array
    currentInd = 1;
    foundNonnumeric = false;
    convert = false;
    
    for iData = 1:length(cellArray)
        entry = cellArray{iData};

        if ~strcmp(class(entry), 'double')
            foundNonnumeric = true;
        end
    end

    if ~foundNonnumeric
        for iData = 1:length(cellArray)
            if isempty(cellArray{iData})
                numArray(iData) = NaN;
            else
                numArray(iData) = cellArray{iData};
            end
        end
        data = setfield(data, h, numArray);
    else % if strings, make NaN entries into ''
        for iData = 1:length(cellArray)
            if isnan(cellArray{iData})
                cellArray{iData} = '';
            end
        end
        data = setfield(data, h, cellArray);
    end

end

% Use the coded fields to decide which coder (if any) to use for each file

if isfield(data, 'allcoders')
    
    allcoders = cell(1, length(data.allcoders));
    useCoder = cell(1, length(data.allcoders));

    for iRec = 1:length(data.allcoders)
        if ~strcmp(data.allcoders{iRec}, '[]') 
            thisList = data.allcoders{iRec};
            thisList = thisList(~ismember(thisList, '[]'''));
            thisList = strsplit(thisList, ',');
            allcoders{iRec} = thisList;
            useCoder{iRec} = thisList{1};
            % If there's a specified priority for coders
            if nargin >= 2
                allcodersPriority = {};
                for iCoder = length(coderPreferenceList):-1:1
                    coder = coderPreferenceList{iCoder};
                    if any(strcmp(thisList, coder))
                        useCoder{iRec} = coder;
                    end
                end
            end
        else
            allcoders{iRec} = {};
            useCoder{iRec} = '';
        end
    end
    
    data = setfield(data, 'allcoders', allcoders);
    data = setfield(data, 'useCoder', useCoder);
    
end

function limitedStr = remove_chars(str, charList)
    limitedStr = str(~ismember(str, charList));
end

end