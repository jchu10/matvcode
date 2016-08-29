function [data, allCoderBinaries, fracAgree, kappas, colLabels] = get_fdp_coding(data, headers, trials, acceptable, ...
    displayFormat, arbiter)
% Combines qualitative coding marks from up to two coders per record
%
% [data, allCoderBinaries] = get_fdp_coding(data, headers, trials, acceptable, ...
%    displayFormat, arbiter)
%
% This function reads and checks qualitative coding (in our case, generally
% whether a child was fussy/distracted each trial, and what sorts of parent
% interaction occurred). Only up to two coders are used per file.
% 
% data: struct as created by read_lookit_results_xls; needs to have fields 
%    named CoderHeaderTrial (e.g. KatyP11) where Header corresponds to the
%    values in 'headers' and Trial corresponds to the values in
%    trials{iHeader}.
% headers: cell array of coding headers expected, e.g. {'F', 'D', 'P'}
% trials: cell array of trials where each header is expected to be coded.
%   E.g. for oneshot, we code fussiness (F) and distraction (D) for each of
%   8 trials, but parent interference (P) only for the last 4, so we
%   use {1:8, 1:8, 5:8}
% acceptable: cell array with, for each header, a list of acceptable codes.
%   This list can either be a numeric array of all possible values (for
%   fussiness and distraction, just [0 1] or a cell array of strings. If
%   it's a cell array of strings, then coder responses are expected to be
%   a comma-separated list of values in this cell array.
% displayFormat: 0 = short, 1 = long. If short, don't display which files
%   need more FDP coding or disagreements that have been resolved by the
%   arbiter already.
% arbiter: '' = none, otherwise a coder's name. This coder will NOT be used
%   as a regular FDP coder, but will instead be used to (a) settle
%   disagreements (any disagreements where the arbiter has no coding will be
%   displayed) and (b) override single coders.
%
% This function makes the following changes to data:
% data.fdpCoders{iF} is a cell array of coders with valid markings for the
%   iFth record
% data.fdpByCoder{iF}{iCoder}{iH} is either a cell array or a numeric
%   array, as appropriate, of the iCoder'th markings, indexed by trial;
%   corresponds to the coder data.fdpCoders{iF}{iCoder}
% data.(headers{iH}){iF} is the combined data for the iHth header and the
%   iFth file. It's either a cell array or numeric array as appropriate,
%   indexed by trial. Where there is disagreement and no arbitration, the
%   average of numeric codes and the union of string codes is used.
%
% allCoderBinaries: array of only the cases where there are two 
%   coders. It's a numeric array, indexed kids x categories x trials x 2. 
%   String marks other than 'no' are each given their own categories and
%   transformed to binary - e.g. if possible codes are 'talk' and 'peek',
%   then 'talk' is [1 0], 'peek' is [0, 1], and 'talk, peek' or 'peek,
%   talk' are [1 1].
% fracAgree: array of agreement percentages, based on cases where there are
%   at least two coders, per category.
% kappas: array of Cohen's kappa agreement per category
% colLabels: labels for each category

fprintf(1, 'Checking qualitative (FDP) coding...\n');

% Who are all the potential coders? Look for fields of the form
% coderName_headerTrial, e.g. Katy_P11.
fields = fieldnames(data);
exampleSuffix = [headers{1} num2str(trials{1}(1))];
coders = {};
for iF = 1:length(fields)
    f = fields{iF};
    if length(f) > length(exampleSuffix) && ...
            strcmp(f(end+1-length(exampleSuffix):end), exampleSuffix)
        coders{end+1} = f(1:(end-length(exampleSuffix)));
    end
end

% Display a list of potential coders
fprintf(1, '\tFound these potential FDP coders: ');
for iC = 1:(length(coders)-1)
    fprintf(1, '%s, ', coders{iC});
end
fprintf(1, '%s\n', coders{end});

% For each file, make a list of coders who have done FDP coding.  Store
% the coding and give a warning if it's incomplete or incorrect.
fprintf(1, '\n\tChecking for invalid coding marks... \n');
[fdpcoders, fdpdata] = check_fdp_coding(coders, data);
data = setfield(data, 'fdpByCoder', fdpdata);
data = setfield(data, 'fdpCoders', fdpcoders);

% Flag records with incomplete double-coding or extra coders:
nCoders = cellfun(@(c)length(c), fdpcoders); nCoders = nCoders(:)';
fprintf(1, '\n\tRecords with no FDP coding yet: %i \n', sum(nCoders==0));
if displayFormat
    for i =find(~nCoders)
       fprintf(1, '\t  User %i, recording set %s \n', data.userid(i), data.recordingSet{i});
    end
end
fprintf(1, '\tRecords with only 1 FDP coder: %i \n', sum(nCoders==1));
if displayFormat
    for i = find(nCoders == 1)
        fprintf(1, '\t  User %i, recording set %s (%s)\n', data.userid(i), data.recordingSet{i}, data.fdpCoders{i}{1});
    end
end
fprintf(1, '\tRecords with at least 2 FDP coders: %i (of %i) \n', sum(nCoders>=2), length(nCoders));
if displayFormat
    for i = find(nCoders > 2)
        fprintf(1, '\t\tExtra FDP coder found for user %i:', data.userid(i));
        for iC = 1:nCoders(i)
            fprintf(1, ' %s', data.fdpCoders{i}{iC});
        end
        fprintf(1, '\n');
    end
end

% Make combined FDP coding fields based on all coder input.
fdpCodesCombined = cell(length(headers), length(data.age)); % fdpCodesCombined{iH, iF}
fprintf(1, '\n\tComparing FDP coding...\n');

% Show disagreements and use arbiter values if available
if displayFormat
    fprintf(1, '.');
end

% Track ratings done by two coders, for calculating agreement. Convert 
% non-numerical values into binary per code.

allCoderBinaries = []; % kids x categories x trials x 2

for iF = 1:length(data.age)
    foundProblem = false;
    if nCoders(iF) == 0
        for iH = 1:length(headers)
            fdpCodesCombined{iH, iF} = [];
        end
    % If there is only one FDP coder, use that value unless there's also an
    % arbiter value (then use the arbiter value!)
    
    elseif nCoders(iF) == 1
        for iH = 1:length(headers)
            marks{iH} = setdiff(acceptable{iH}, 'no'); 
            fdpCodesCombined{iH, iF} = data.fdpByCoder{iF}{1}{iH};
            if ~isempty(arbiter)
                for t = trials{iH}
                    fieldName = [arbiter, headers{iH}, num2str(t)];
                    arbiterData = data.(fieldName);
                    arbiterVal = get_element(arbiterData, iF);
                    if ~isempty(arbiterVal) && ~any(isnan(arbiterVal))
                        [okayType, okayVal, isStr, cleaned] = ...
                            is_code_okay(arbiterVal, acceptable{iH}, 1, ...
                                [arbiter '(arbiter)'], data.userid(iF), headers{iH}, t);
                        if okayType && okayVal
                            fprintf(1, '\t\tUser %i, %s.%i: Coder %s says ''%s'' \n', ...
                               data.userid(iF), headers{iH}, t, ...
                               data.fdpCoders{iF}{1}, ...
                               num2str(get_element(data.fdpByCoder{iF}{1}{iH}, t)));                                    
                            fprintf(1, '\t\t\tUsing arbiter value ''%s''\n', num2str(arbiterVal));
                            
                            if isStr
                                fdpCodesCombined{iH, iF}{t} = cleaned;
                            else
                                fdpCodesCombined{iH, iF}(t) = cleaned;
                            end
                        end
                    end
                end
            end
        end
        
    % If there are two or more coders, use the first two and an arbiter if available.
    else 
        % Keep track of where we are in allCoderBinaries
        thisRow = size(allCoderBinaries,1) + 1;
        thisCol = 0;
        
        for iH = 1:length(headers)
            thisCol = thisCol + 1;
            
            if iscell(acceptable{iH})
                % start with the first coder.
                theseP = data.fdpByCoder{iF}{1}{iH};
                combinedP = {};
                % for each additional coder, add trial by trial:
                
                % Keep track of the possible markings
                marks{iH} = setdiff(acceptable{iH}, 'no'); 
                
                for t = trials{iH}
                    foundProblemThisTrial = false;
                    currentNotes = strsplit(theseP{t}, ',');
                    for iC = 2 %:nCoders(iF) % only use two coders
                        
                        newNotes = strsplit(data.fdpByCoder{iF}{iC}{iH}{t}, ',');
                        toprint = '';
                        
                        for iMark = 1:length(marks{iH})
                            allCoderBinaries(thisRow, thisCol + iMark - 1, t, 1) = ...
                                any(ismember(marks{iH}{iMark}, currentNotes));
                            allCoderBinaries(thisRow, thisCol + iMark - 1, t, 2) = ...
                            	any(ismember(marks{iH}{iMark}, newNotes));
                            % Use second coder as "real" answer, as
                            % placeholder (switch to arbiter if there's a
                            % disagreement)
                            allCoderBinaries(thisRow, thisCol + iMark - 1, t, 3) = ...
                            	any(ismember(marks{iH}{iMark}, newNotes));
                            colLabels{thisCol + iMark - 1} = marks{iH}{iMark};
                        end
                        
                        if any(~ismember(currentNotes, newNotes)) || ...
                           any(~ismember(newNotes, currentNotes))
                           foundProblem = true;
                           foundProblemThisTrial = true;
                           toprint = sprintf('\t\tUser %i, %s.%i: ''%s'' (%s) vs. ''%s'' (%s).\n', ...
                               data.userid(iF), headers{iH}, t, ...
                               data.fdpByCoder{iF}{iC}{iH}{t}, ...
                               data.fdpCoders{iF}{iC}, ...
                               strjoin(currentNotes, ','), ...
                               data.fdpCoders{iF}{1});
                           
                           % Store the union of the two marking sets,
                           % except remove 'no' if anyone has something
                           % else.
                           if strcmpi(currentNotes{1}, 'no')
                               currentNotes = newNotes;
                           elseif ~strcmpi(newNotes{1}, 'no')
                               currentNotes = unique([currentNotes, newNotes]);
                           end
                        end
  
                    end
                    combinedP{t} = currentNotes;
                    
                    % If there's a problem, check whether the arbiter has
                    % something to say
                    if foundProblemThisTrial
                        
                        if isempty(arbiter) % always show issues if we're not doing arbitration at all
                            fprintf(1, [toprint '\n']);
                        else
                            fieldName = [arbiter, headers{iH}, num2str(t)];
                            arbiterData = data.(fieldName);
                            if ~iscell(arbiterData) % also display if there's no arbiter coding
                                fprintf(1, toprint);
                                fprintfif(1, '\t\t\tNo arbiter coding yet\n');
                            else
                                arbiterVal = arbiterData{iF};
                                if isempty(arbiterVal)
                                    fprintf(1, toprint);
                                    fprintfif(1, '\t\t\tNo arbiter coding yet\n');
                                else
                                    allStrs = strsplit(arbiterVal, ',');
                                    if (~all(ismember(lower(allStrs), lower(acceptable{iH})))) % or if it's invalid
                                        fprintf(1, toprint);
                                        fprintf(1, '\t\t\tInvalid arbiter coding ''%s''\n', arbiterVal);
                                    else % but if we're using an arbiter value and it's okay, only show if display==1
                                        combinedP{t} = allStrs;
                                        fprintfif(1, toprint);
                                        fprintfif(1, '\t\t\tUsing arbiter value ''%s''\n', arbiterVal);
                                        allCoderBinaries(thisRow, thisCol + iMark - 1, t, 3) = ...
                                            any(ismember(marks{iH}{iMark}, allStrs));
                                    end
                                end
                            end
                        end
                    end
                end
                
                thisCol = thisCol + length(marks{iH}) - 1;
      
                
                fdpCodesCombined{iH, iF} = combinedP;
    
            else % i.e., ~iscell(acceptable{iH})
                
               % make a numeric array of the data for this subject
               theseData = NaN(2, max(trials{iH}));
               for iC = 1:2 
                   theseData(iC, :) = data.fdpByCoder{iF}{iC}{iH};
               end
               allCoderBinaries(thisRow, thisCol, trials{iH}, 1) = data.fdpByCoder{iF}{1}{iH};
               allCoderBinaries(thisRow, thisCol, trials{iH}, 2) = data.fdpByCoder{iF}{2}{iH};
               % use second coder as "real" value (just as placeholder; if
               % disagreement, will look to arbiter)
               allCoderBinaries(thisRow, thisCol, trials{iH}, 3) = data.fdpByCoder{iF}{2}{iH};
               
               colLabels{thisCol} = headers{iH};
               fdpCodesCombined{iH, iF} = mean(theseData);
               
               trialDisagreements = find(any(theseData ~= repmat(fdpCodesCombined{iH, iF}, 2, 1)));
               
               for t = trialDisagreements(:)'
                    foundProblem = true;
                    toprint = sprintf('\t\tUser %i, %s.%i disagreement (', ...
                               data.userid(iF), headers{iH}, t);
                    for iC = 1:2
                        toprint = [toprint, sprintf('%s: %i ', data.fdpCoders{iF}{iC}, ...
                            data.fdpByCoder{iF}{iC}{iH}(t))];
                    end
                    toprint = [toprint, ')\n'];
                    
                    % Use arbiter judgment if available
                    if  ~isempty(arbiter)
                        fieldName = [arbiter, headers{iH}, num2str(t)];
                        arbiterData = data.(fieldName);
                        if ~isnumeric(arbiterData)
                            fprintf(1, toprint);
                            fprintfif(1, '\t\t\tNo arbiter coding yet\n');
                        else
                            arbiterVal = arbiterData(iF);
                            if isempty(arbiterVal) || isnan(arbiterVal)
                                fprintf(1, toprint);
                                fprintfif(1, '\t\t\tNo arbiter coding yet\n');
                            else
                                if ~ismember(arbiterVal, acceptable{iH})
                                    fprintf(1, toprint);
                                    fprintf(1, '\t\t\tInvalid arbiter coding ''%s''\n', num2str(arbiterVal));
                                else
                                    fdpCodesCombined{iH, iF}(t) = arbiterVal;
                                    fprintfif(1, toprint);
                                    fprintfif(1, '\t\t\tUsing arbiter value ''%i''\n', arbiterVal);
                                    allCoderBinaries(thisRow, thisCol, t, 3) = arbiterVal;
                                end
                            end
                        end
                    end
               end
                
            end
        end
    end
    
    if foundProblem && displayFormat
        fprintf(1, '.');
    end
    
end

fprintf('\n\tSummary of coder agreement before arbitration (%i records):\n', sum(nCoders>1));
kappas = [];
fracAgree = [];
for iType = 1:size(allCoderBinaries, 2)
    judgments = squeeze(allCoderBinaries(:,iType,trials{min(iType, length(trials))},:));
    judgmentsA = judgments(:,:,1); judgmentsA = judgmentsA(:);
    judgmentsB = judgments(:,:,2); judgmentsB = judgmentsB(:);
    judgmentsC = judgments(:,:,3); judgmentsC = judgmentsC(:);
    
    agree = sum(judgmentsA==judgmentsB)/length(judgmentsA);
    fracA = nansum(judgmentsA)/sum(~isnan(judgmentsA));
    fracB = nansum(judgmentsB)/sum(~isnan(judgmentsB));
    agreeChance = fracA * fracB + (1-fracA) * (1-fracB);
    kappa = (agree - agreeChance) / (1 - agreeChance);
    if agreeChance == 1
        kappa = 0;
    end
    
    fracAgree(iType) = agree;
    kappas(iType) = kappa;
    freq = sum(judgmentsC)/length(judgmentsC) * 100;
    
    fprintf(1, ['\t\t%s:\t%.2f agreement, kappa = %.2f,', ...
        'frequency (percent)=%.1f, N=%i\n'], ...
        colLabels{iType}, agree, kappa, freq, length(judgmentsC));
end

% Store combined codes in data by their header labels
for i = 1:length(headers)
    data.(headers{i}) = fdpCodesCombined(i,:);
end

    function fprintfif(out, varargin)
    % Simple utility--print to console only if displayFormat
        if displayFormat
            fprintf(out, varargin{:});
        end
    end

    function [fdpcoders, fdpdata] = check_fdp_coding(coders, data)
    % Compile a list of actual FDP coders and their responses per record
    %
    % [fdpcoders, fdpdata] = check_fdp_coding(coders, data)
    %
    % coders: cell array of all possible FDP coders
    % data: struct with fields userid and [coder][header][trial] for all
    %     valid combinations of coders, headers, trials.
    %
    % fdpcoders is a cell array, indexed as data.userid, with a cell array of 
    %     fdp coders for each record. (Coders who had valid data on ALL
    %     marks are included. Note that even one invalid or missing coding
    %     mark will invalidate all of that coder's
    %     marks for this record until it's fixed--this is deliberate, to
    %     make it simpler to check that there are enough valid coders and
    %     to check agreement.)
    % fdpdata: fdpdata{iF}{iCoder}{iHeader} is either a cell array or a 
    %     numeric array of the codes given by coders{iCoder} for the iFth 
    %     record in data on the headers{iHeader} mark, indexed by 
    %     trial (actual trial, not index in trials{iH})
    %
    % Uses values of headers, trials, acceptable.

        fdpcoders = {};
        fdpdata = {};
        
        for iF = 1:length(data.userid)
            theseCoders = {};
            allCoderData = {}; % allCoderData{iCoder}{iHeader} = [F1, ..., FN] 
            for iC = 1:length(coders) % for each coder...
                includeThisCoder = false;
                observedAnyMissing = false;
                
                thisCoderInvalid = false;
                thisCoderData = {};

                for iH = 1:length(headers) % for each type of coding...
                    for t = trials{iH} % for each column expected...
                        thisCol = data.([coders{iC}, headers{iH}, num2str(t)]);
                        if iscell(thisCol)
                            thisVal = thisCol{iF};
                        else
                            thisVal = thisCol(iF);
                        end
                        % If we have a value, include this coder and check for correctness.
                        if ~isempty(thisVal) && ~any(isnan(thisVal))
                            includeThisCoder = true; % include this coder for the file if we have ANY coding
                            [okayType, okayVal] = is_code_okay(thisVal, acceptable{iH}, 1, coders{iC}, data.userid(iF), headers{iH}, t);
                            if okayType && okayVal
                                if ischar(thisVal)
                                    thisCoderData{iH}{t} = thisVal; % todo; check this shouldn't have been allstrs
                                else
                                    thisCoderData{iH}(t) = thisVal;
                                end
                            else
                                thisCoderInvalid = true;
                            end
                        else % empty value observed!
                            observedAnyMissing = true;
                        end
                    end
                end
                
                if includeThisCoder && observedAnyMissing && ~strcmp(coders{iC}, arbiter)
                    fprintf(1, '\t\t%s, subject %i: Missing some coding (will not be used until complete)\n', ...
                        coders{iC}, data.userid(iF));
                end

                % Now if we have proper coding from this coder, fill in any
                % blanks at the end only
                if includeThisCoder && ~thisCoderInvalid && ~strcmp(coders{iC}, arbiter) && ~observedAnyMissing
                    theseCoders{end+1} = coders{iC};

                    for iH = 1:length(headers)
                        if length(thisCoderData{iH}) < max(trials{iH})
                            for j = (length(thisCoderData{iH})+1):max(trials{iH})
                                if iscell(thisCoderData{iH})
                                    thisCoderData{iH}{j} = 'empty';
                                else
                                    thisCoderData{iH}(j) = NaN;
                                end
                            end
                        end
                    end

                    allCoderData{end+1} = thisCoderData;
                end

            end

            fdpdata{iF} = allCoderData;
            fdpcoders{iF} = theseCoders;

        end
    end

    function [okayType, okayVal, isStr, cleaned] = is_code_okay(thisVal, accept, display, coder, userid, header, trial)
    % Checks whether a code marking (e.g. 0 or 'peek, talk') is acceptable
    %
    % [okayType okayVal] = is_code_okay(thisVal, accept)
    %
    % thisVal: what the coder entered (any type)
    % accept: the acceptable values for this code (from acceptable{iH})
    % display: binary -- whether to display warning messages. If so, must
    % also include the arguments coder (string), userid (int), header
    % (string), and trial (int) for display purposes.
    %
    % okayType: binary--is the type of thisVal acceptable?
    % okayVal: binary--is the value of thisVal acceptable?
    % isStr: binary--is thisVal a string?
    % cleaned: value of thisVal (if numeric) or cell array of string codes
    %   (if string); if type was incorrect, NaN (if should have been
    %   numeric) or '' (if should have been string)
    %
    % If accept is a cell array, thisVal needs to be a string consisting of
    % comma-separated entries all in accept (case ignored). 
    % If accept is a numeric array, thisVal has to be in that array.
    
        % For string data, expect strings of comma-separated
        % values in acceptable list
        isStr = ischar(thisVal);
        
        if isStr
            thisVal = lower(thisVal);
            okayType = iscell(accept);
            if okayType
                allStrs = strsplit(thisVal, ',');
                cleaned = allStrs;
                okayVal = all(ismember(allStrs, lower(accept))) && ~isempty(allStrs) && ~isempty(allStrs{1});
                if ~okayVal
                    ifdisplay('\t\t%s, subject %i: Unexpected string ''%s'' in %s coding, trial %i\n', ...
                        coder, userid, thisVal, header, trial);
                end
            else
                okayVal = false;
                cleaned = NaN;
                ifdisplay('\t\t%s, subject %i: Expected numeric but have string data for %s coding, trial %i\n', ...
                    coder, userid, header, trial);
            end
        % For numeric data, expect a value in the acceptable list
        elseif isnumeric(thisVal)
            okayType = isnumeric(accept);
            if okayType
                okayVal = ismember(thisVal, accept);
                cleaned = thisVal;
                if ~okayVal
                    ifdisplay('\t\t%s, subject %i: Unexpected code %i in %s coding, trial %i\n', ...
                        coder, userid, thisVal, header, trial);
                end
            else
                okayVal = false;
                cleaned = '';
                ifdisplay('\t\t%s, subject %i: Expected string and got numeric data %i for %s coding, trial %i\n', ...
                    coder, userid, thisVal, header, trial);
            end
        else
            okayType = false;
            okayVal = false;
            if isnumeric(accept)
                cleaned = NaN;
            else
                cleaned = '';
            end
            ifdisplay('\t\t%s, subject %i: Expected code type %s coding, trial %i\n', ...
                coder, userid, header, trial);
        end
        
        function ifdisplay(varargin)
            if display
                fprintf(1, varargin{:});
            end
        end
    
    end

    function el = get_element(cellOrArray, index)
        if iscell(cellOrArray)
            el = cellOrArray{index};
        else
            el = cellOrArray(index);
        end
    end

end