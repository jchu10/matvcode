function [durations, leftLookTime, rightLookTime, oofTime, soundTimes, msArray, trialStarts] = ...
    read_preferential_vcode(filename, interval, lastTrialLength, whichTrials)
% Reads preferential looking data from a VCode text file
% 
% Usage: 
% durations = read_preferential_vcode(filename, interval, lastTrialLength)
%
%   filename: full path to the VCode text file
%   interval: section of each trial to use. Options:
%     []: use whole trial
%     [msA, msB]: use from (trialStart + msA) to (trialStart + msB); e.g.
%         set this to [2000, 6000] to use from second 2 to second 6.
%     [msA, 0]: use the period from (trialEnd + msA) to trialEnd; e.g. set
%         this to [-5000, 0] to use the last five seconds of the trial
%     {[msA, msB], 'sound'/'nosound', [maxLength1, ..., maxLengthN]/[]}: First element
%         as above--can be [msA, msB], [msA, 0], or []. Include 'sound' 
%         in the cell array to start from the 'sound' event in this trial
%         if it's available. Include an array with one element per trial
%         specifying the maximum trial duration in ms to first cap trial
%         length there. For instance if we specify a length of 10000
%         and the actual trial length is 12000, we'll start at 'start' if
%         appropriate, then just the interval [0, 10000], THEN if using 
%         [msA, 0] we'll take [10000+msA, 10000].
%   lastTrialLength: minimum length of last trial to assume, in ms (VCode files 
%     are expected to have trial markers only at the start of each trial). 
%     If a vector is given instead, override any trial markers and instead use the list of
%     video lengths (in ms) to determine trial boundaries. VCode file is expected
%     to have one event 'end' which marks the end of the trial, and trial lengths are
%     scaled accordingly.
%
%   durations: array of durations of trials (in ms)
%
% [durations, leftLookTime, rightLookTime, oofTime, soundTimes, msArray] = ...
%    read_preferential_vcode(filename, interval, lastTrialLength, whichTrials)
% 
%   As above, but also returns:
%   leftLookTime: array of ms coded as 'left' per trial, indexed
%     by trial number; only valid for non-looking-time trials
%   leftLookTime: array of ms coded as 'right' per trial, indexed
%     by trial number; only valid for non-looking-time trials
%   oofTime: array of ms coded as 'right' per trial, indexed
%     by trial number; only valid for non-looking-time trials
%   soundTimes: array of times at which 'sound' events occur, relative to 
%     the trial start (ms)
%   msArray: which direction the child is coded as looking, per ms. 
%     1 = left, 2 = right, 3 = away, 4 = out of frame, NaN = not coding
%     this trial.
% 
% [...] = read_preferential_vcode(filename, interval, lastTrialLength, ...
%     whichTrials)
%
% Only computes looking times and msArray for the trials
%     specified in whichTrials. If whichTrials is empty, all are used.
%     Output variables are still indexed by trial (rather than index into 
%     whichTrial).
%
% If only 'durations' is specified as an output, the preferential-looking
% calculations are skipped. msArray is computed only if specified as an 
% output.
%
% Expects a VCode file with trial types 'trial', 'left', 'right', 'away',
% 'sound' (point), and possibly 'outofframe'. Marks with 'x' or 'delete'
% notes will be ignored. Some misspellings are allowed (see start of
% function) and 'looking', 'nosound' are accepted but not used.
% 
% Where a child is looking can be determined from these marks: if it's in
% an 'outofframe' mark, we can't tell because we can't see the child's
% eyes. If the current frame has mark X or the most recent mark is X, then
% the child is looking at X (where X may be left, right, or away). Marks
% during outofframe are still used to determine where the child is looking
% once the outofframe event ends. 

    doMsArray = nargout > 5;
    doOnlyDurations = nargout == 1;

    % Case-insensitive
    acceptable_trial_names = {'Trial', 'Trials', 'trail', 'trails'};
    acceptable_left_names = {'left'};
    acceptable_right_names = {'right'};
    acceptable_away_names = {'away'};
    acceptable_outofframe_names = {'outofframe', 'outoframe', 'outoffame'};
    acceptable_delete_names = {'x', 'delete'};
    acceptable_sound_names = {'sound'};
    acceptable_end_names = {'end', 'End'};
    other_acceptable = {'looking', 'look', 'looking time', 'nosound', ...
        'distract', 'peek', 'point', 'talk', 'fuss'};

    fid = fopen(filename);

    % header
    for i = 1:3
        fgetl(fid);
    end

    formatString = '%d %d %s %s';
    if ispc % different line ending for PCs; none required on Mac
        formatString = [formatString, '\r\n'];
    end
    
    C = textscan(fid, formatString, 'Delimiter', ',');
    fclose(fid);
    
    starts = C{1};
    [starts, order] = sort(starts);
    durations = C{2}; durations = durations(order);
    types = C{3}; types = types(order); types = strtrim(types);
    marks = C{4}; marks = marks(order); marks = strtrim(marks);
    
    % Remove any marks with a delete note
    exclude = cellfun(@(s)(any(strcmpi(s, acceptable_delete_names))), marks);
    
    % Update the lists of start/type 
    starts = starts(~exclude);
    durations = durations(~exclude);
    types = types(~exclude);
    
    trialInds = cellfun(@(s)(any(strcmpi(s, acceptable_trial_names))), types);
    leftInds = cellfun(@(s)(any(strcmpi(s, acceptable_left_names))), types);
    rightInds = cellfun(@(s)(any(strcmpi(s, acceptable_right_names))), types);
    awayInds = cellfun(@(s)(any(strcmpi(s, acceptable_away_names))), types);
    oofInds = cellfun(@(s)(any(strcmpi(s, acceptable_outofframe_names))), types);
    soundInds = cellfun(@(s)(any(strcmpi(s, acceptable_sound_names))), types);
    otherInds = cellfun(@(s)(any(strcmpi(s, other_acceptable))), types);
    endInds   = cellfun(@(s)(any(strcmpi(s, acceptable_end_names))), types);
    allLookInds = leftInds | rightInds | awayInds;
    
    endTime = 0;
    if any(endInds)
        if sum(endInds) > 1
            warning('multiple end events listed; using first');
        end
        endTime = double(starts(endInds));
        endTime = endTime(1);
    end
    
    if all(~trialInds) && length(lastTrialLength) == 1
        error(['No trials marked in file ' filename]);
    elseif all(~allLookInds)
        error(['No looks right, left, or away marked in file ' filename]);
    end
    
    knownInds = allLookInds | trialInds | soundInds | otherInds | oofInds | endInds;
    if not(all(knownInds))
        unknownTypes = unique(types(~knownInds));
        for i = 1:length(unknownTypes)
            warning('Unknown mark type: %s', unknownTypes{i})
        end
    end
    
    allLooks = starts(allLookInds);
    allLookTypes = 1*leftInds + 2*rightInds + 3*awayInds;
    allLookTypes = allLookTypes(allLookInds);
    
    % Adjust looking times based on out-of-frame coding
    oofStarts = starts(oofInds);
    oofEnds = oofStarts + durations(oofInds);
    for i = 1:length(oofStarts)
        % Where is the child looking at the end of this period?
        lastLook = find(allLooks <= oofEnds(i), 1, 'last');
        if isempty(lastLook)
            lastLookType = 3; % looking away
        else
            lastLookType = allLookTypes(lastLook);
        end
        
        % Delete any marks within the period
        removeInds = allLooks >= oofStarts(i) & allLooks <= oofEnds(i);
        allLooks(removeInds) = [];
        allLookTypes(removeInds) = [];
        
        % Move that mark to the end of the period
        allLooks(end+1) = oofEnds(i);
        allLookTypes(end+1) = lastLookType;
        
        % & resort
        [allLooks, order] = sort(allLooks);
        allLookTypes = allLookTypes(order);
    end
    
    % Add OOF events to look array and re-sort
    allLooks = [allLooks; oofStarts];
    allLookTypes = [allLookTypes; 4*ones(size(oofStarts))];
    [allLooks, order] = sort(allLooks);
    allLookTypes = allLookTypes(order);

    % Determine trial start and end times based on lastTrialLength
    if length(lastTrialLength) > 1
        % Scale trial lengths based on end
        if endTime
            if abs(endTime - sum(lastTrialLength)) > 1000
                warning('Disparity over 1 s between trial length sum and end marker');
            end
            lastTrialLength = lastTrialLength * endTime / sum(lastTrialLength);
        else
            warning('Trial lengths given but no end marker provided; not scaling trial lengths');
        end
        trialBounds = round([1, 1 + cumsum(lastTrialLength)]);
        trialStarts = trialBounds(1:end-1)';
        trialEnds   = trialBounds(2:end)';
    else
        trialStarts = starts(trialInds);
        trialLengthsInit = diff(trialStarts);
        trialEnds = [trialStarts(2:end); trialStarts(end)+max(lastTrialLength, max(trialLengthsInit(end-1:end)))];
    end
        
    % Find first sound in each trial
    soundTimes = NaN(length(trialStarts), 1);
    sounds = starts(soundInds);
    for iT = 1:length(trialStarts)
        trialSounds = sounds(sounds >= trialStarts(iT) & sounds < trialEnds(iT));
        if ~isempty(trialSounds)
            soundTimes(iT) = trialSounds(1);
        end
    end
    
    % Determine trial boundaries to use based on input
    trialStarts = max(trialStarts, 1);
    
    useSound = false;
    maxTrialLength = [];
    if iscell(interval)
        if ~(length(interval) == 3)
            error('Invalid interval argument; if using cell array length should be 3 {interval, "sound"/"nosound", maxLengths}');
        end
        useSound = any(strcmp('sound', interval));
        maxTrialLength = interval{3};
        interval = interval{1};
    end
    
    origTrialStarts = trialStarts;

    % First, start at 'sound' if available
    if useSound 
        trialStarts(~isnan(soundTimes)) = soundTimes(~isnan(soundTimes));
    end
    
    % soundTimes are relative to trial start time actually marked
    soundTimes = double(soundTimes) - double(origTrialStarts);
    
    % Next, clip trials if needed
    if ~isempty(maxTrialLength)
        maxTrialLength = cast(maxTrialLength(:), 'int32'); % to match coding
        clipTrials = find((trialStarts + maxTrialLength) < trialEnds);
        for i = 1:length(clipTrials)
            fprintf(1, '\t\tWarning: %s,\n\t\t\ttrial  %i is %i ms - using first %i ms \n', ...
                filename, clipTrials(i), ...
                trialEnds(clipTrials(i))-trialStarts(clipTrials(i)), ...
                maxTrialLength(clipTrials(i)));
        end
        trialEnds = min(trialEnds, trialStarts + maxTrialLength);
    end
    
    % Finally, use the correct interval
    if ~isempty(interval)
        if interval(2) ~= 0 % use from (trialStart + msA) to (trialStart + msB)
            trialStarts = trialStarts + interval(1);
            trialEnds = min(trialStarts + interval(2), trialEnds);
        else % use the period from (trialEnd + msA) to trialEnd
            trialStarts = max(trialStarts, trialEnds + interval(1));
            trialStarts = max(trialStarts, 1);
        end
    end
    
    durations = double((trialEnds - trialStarts)');
    
    if doOnlyDurations == 1
        return;
    end
    
    if nargin < 4 || isempty(whichTrials)
        whichTrials = 1:length(trialStarts);
    end
    
    for iT = whichTrials
        startT = trialStarts(iT);
        endT = trialEnds(iT);

        leftLookTime(iT) = 0;
        rightLookTime(iT) = 0;
        oofTime(iT) = 0;

        for i = 1:(length(allLooks)-1)
            a = allLooks(i);
            b = allLooks(i+1);
            b = min(b, endT);
            a = max(a, startT);
            if b - a > 0
                if allLookTypes(i) == 1 % left look
                    leftLookTime(iT) = leftLookTime(iT) + b - a;
                elseif allLookTypes(i) == 2 % right look
                    rightLookTime(iT) = rightLookTime(iT) + b - a;
                elseif allLookTypes(i) == 4 % outofframe
                    oofTime(iT) = oofTime(iT) + b - a;
                end
            end
        end
    end
    leftLookTime = double(leftLookTime);
    rightLookTime = double(rightLookTime);
    oofTime = double(oofTime);
    
    % Finally make the ms-by-ms big array of looking-or-not, if needed
    if doMsArray
        % First make giant array
        msArray = zeros(1, trialEnds(end)+1);
        for iLookEvent = 1:length(allLooks)
            if iLookEvent == length(allLooks)
                msArray((allLooks(iLookEvent)+1):end) = allLookTypes(iLookEvent);
            else
                msArray((allLooks(iLookEvent)+1):allLooks(iLookEvent+1)) = allLookTypes(iLookEvent);
            end
        end
        msArray = msArray(2:end);
        % Then restrict to the trial periods 
        for iT = 1:length(trialStarts)
            if ~ismember(iT, whichTrials)
                msArray(trialStarts(iT):trialEnds(iT)) = NaN;
%                 smallMsArray = [smallMsArray, msArray(trialStarts(iT):trialEnds(iT))];
            end
        end
%        % msArray = smallMsArray;
    end