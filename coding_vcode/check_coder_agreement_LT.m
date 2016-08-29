function [data, nMissingCoding, allFracSame] = ...
    check_coder_agreement_LT(codingDir, data, NTRIALS, lookawayThresh, ...
    disagreeThresh, showEmpty, conflictDir, saveConflictsFile, useConflictsFile)
% Read and check looking time VCODE files for agreement betweeen two coders
%
% [data, nMissingCoding] = check_coder_agreement_NV(codingDir, ...
%    data, interval, disagreeThresh, showEmpty, ...
%    conflictDir, saveConflictsFile, useConflictsFile)
%
% codingDir: main directory to expect coder directories in. Path to the 
%    coding file 'filename' by 'coder' will be codingDir/coder/filename.
% data: a struct as created by read_lookit_results_xls, with at least 
%    fields allcoders (a cell array of cell arrays of coder names per 
%    record) and filenames (either a cell array of filenames or a cell
%    array of possible cell arrays of filenames, in preference order),
%    missingCoding (binary), filenamesByCoder (indexed {iF}{iC} where iC 
%    matches allcoders{iF}), userid, childid
% NTRIALS: trials to expect in each file (files without exactly this many 
%    trials will be treated as invalid)
% lookawayThresh: define looking time as time from max(start of trial,
%    first look) to the start of the first continuous lookawayThresh-ms
%    lookaway. Use 'total' to compute total looking time per trial instead.
% disagreeThresh: Mark a looking-time disagreement if the coders disagree
%    by more than disagreeThresh ms.
% showEmpty: binary - show plots where there aren't any coders yet?
% conflictDir: where to find conflict directories
% saveConflictsFile: filename to save conflicts mat-file to. Will have one
%    variable, 'conflicts', an array of structs (one per disagreement) with
%    fields userid, recSet, coders (cell array of the two coder names), 
%    child, trial, and type.
% useConflictsFile: filename of conflicts file to use; if a conflict is
%    detected and it's already in this file it will be marked as 'KNOWN' in
%    the display
%
% This function reads VCode files by each available coder per file and checks
% for substantial disagreements in looking time. Disagreements on trial
% marker placement, validity of trials (was there at least a lookawayThresh-ms
% lookaway?), and looking time are displayed in the console, saved to a
% file if indicated, and marked on a plot of each coder's judgments. The 
% figures created have one plot per record; the y-axis is looking time.
%
% Only the first two coders are used if there are more than two.
%
% Output:
% data: the following fields are added or adjusted:
%    allcoders - updated to include only coders with usable files (as per
%       get_actual_coders)
%    missingCoding - binary array indicating which records have no coders
%       (as per get_actual_coders)
%    
%    The fields below are all indexed (iF, trial), in ms if applicable, 
%    and averaged  across the first two coders if possible:
% 
%    allLookingTimes - looking time per trial
%    allValid - binary, whether each trial was valid (had a long-enough
%        lookaway before ending)
%    allOofDiffs - difference in looking time computed when treating 
%        out-of-frame time as looking vs. not looking. (This may be zero
%        even with out-of-frame time if that happens after a valid
%        lookaway.)
%    allTrialStarts - trial start times, relative to start of first trial
%    hasConflict - binary, whether there is any conflict between the two
%        coders on this file.
%    allRightTimes - looking time to child's right
%    allOofTimes - time spent out of frame/indeterminate gaze direction
%    trialLengths - total length of each trial
%    coderLookingDiffs - coder 1 value - coder 2 value
%    soundTimes - time of first syllable in trials 2,3,4,6,7,8,11,12,13
%        relative to trial start
%
%    Indexed just by (iF):
%    signs - time spent looking to the left during the first segments of 
%        calibration trials  + time spent looking to the right during the 
%        second segments - (time spent looking right, segment 1 + time
%        spent looking left, segment 2): i.e., "correct" - "incorrect"
%        looking time, in ms.
%    
% nMissingCoding: number of records without any usable coders
%
% allFracSame: array of ms-by-ms percent agreement between coders

TRIAL_TOLERANCE = 500; % mark any disagreements about where trial markers
% are if the two coders disagree by this many ms

% First check that we actually have all the coding expected
data = get_actual_coders(data, codingDir, NTRIALS, ...
    @(filename)read_lookingtime_vcode(filename, lookawayThresh));
nMissingCoding = sum(data.missingCoding);
nRecords = length(data.filenames);
masterListCoders = unique(horzcat(data.allcoders{:}));

% Parameters for big plots of coder agreement
coderColors = [204 0 0; ...
               102 204 0; ...
               0 128 255; ...
               204 204 0; ...
               153 51 155; ...
               0 0 0; ...
               160 160 160]/255;
coderColors((end+1):length(masterListCoders), :) = ...
    jet(length(masterListCoders) - size(coderColors, 1));
incompleteColor = [160 160 160]/255;
defaultYLim = [0 30];
figpos = [-1200 400 1000 600];
NCOLS = 6;
MAXROWS = 6;
NROWS = min(ceil(length(data.age) / NCOLS), MAXROWS);

fprintf(1, 'Checking looking time coding...\n');

% If we already have a conflict file, load to use in display
existingConflicts = [];
if ~isempty(useConflictsFile)
    fprintf(1, '\tExisting conflict file listed...');
    useConflictsFile = fullfile(conflictDir, useConflictsFile);
    if exist(useConflictsFile, 'file')
        fprintf(1, ' found file\n');
        existingConflicts = load(useConflictsFile, 'conflicts');
        existingConflicts = existingConflicts.conflicts;
    else
        fprintf(1, ' could not find file\n');
    end
end

allFracSame = [];
f = figure;
set(f, 'Position', figpos);
figNo = 0;
conflicts = [];



% Now compare coding
data.hasConflict = false(nRecords, NTRIALS);
plotNum = 1;

for iF = 1:nRecords

    nCoders = length(data.allcoders{iF});
    theseLookingTimes = [];
    theseValid = [];
    theseOofDiffs = [];
    theseTrials = [];
    msArrays = {};
    
    if nCoders == 0 && ~showEmpty
        continue;
    end
    
    % Add a plot for this subject
    newplot(plotNum);
    plotNum = plotNum + 1;

    % Gather data from coders & plot as we go
    for iC = 1:nCoders

        thisCoder = data.allcoders{iF}{iC};
        filename = fullfile(codingDir, thisCoder, data.filenamesByCoder{iF}{iC});
        [lookingTimes, valid, oofDiffs, msArray, trialStarts] = ...
            read_lookingtime_vcode(filename, lookawayThresh);

        theseLookingTimes(iC,:) = lookingTimes;
        theseValid(iC,:)        = valid;
        theseOofDiffs(iC,:)     = oofDiffs;
        theseTrials(iC,:)       = trialStarts;
        msArrays{iC}            = msArray;
        
        % Plot these looking times
        masterCoderInd = find(strcmp(thisCoder, masterListCoders));
        c = coderColors(masterCoderInd, :);
        if iC <= 2 % bold the first two, which are used in analysis
            weight = 2;
            ls = '.-';
        else
            weight = 2;
            ls = '.--';
        end
        plot(lookingTimes/1000, ls, ...
            'Color', c, 'LineWidth', weight, 'MarkerSize', 10); hold on;
        plot(0.25, masterCoderInd*((defaultYLim(2)-1)/length(masterListCoders)), ...
            '.', 'Marker', 'o', 'MarkerFaceColor', c, 'MarkerEdgeColor', c, ...
            'MarkerSize', 10); % just  indicate who the coders are
    end
    
    % Finish up this plot once we have all the coders on it
    xlim([0, NTRIALS + 0.5]);
    ylim(defaultYLim);
    
    titleText = data.filenames{iF}{1}(9:(strfind(data.filenames{iF}{1}(9:end), '_')+7));
    titleText(1:find(titleText=='_')) = [];
    
    % Compare coding and warn about problems (only use first 2 coders)
    if nCoders >= 2
        
        % Criteria for flagging
        disagreeValid   = find(theseValid(1,:) ~= theseValid(2,:));
        disagreeLT      = find(abs(theseLookingTimes(1,:) - theseLookingTimes(2,:)) > disagreeThresh);
        disagreeOOF     = find(abs(theseOofDiffs(1,:) - theseOofDiffs(2,:)) > disagreeThresh);
        disagreeTrials  = find(abs(theseTrials(1,:) - theseTrials(2,:)) > TRIAL_TOLERANCE);

        if ~isempty([disagreeValid, disagreeLT,disagreeOOF, disagreeTrials])
            fprintf(1, '-------- User %i, %s (%s and %s) \n', ...
                data.userid(iF), data.childid{iF}(2:end-1), data.allcoders{iF}{1}, ...
                data.allcoders{iF}{2});
        end

        % Display and plot warnings based on criteria
        warn_about_disagreement(iF, disagreeValid,  'Validity', 'k', [0.2, -0.2], [-5 0])
        warn_about_disagreement(iF, disagreeTrials, 'Trial timing', 'g', [0.2, -0.2], [-2.5 -2.5])
        warn_about_disagreement(iF, disagreeLT,     'Looking time', 'c', [0,    0],   [-5 0])
        warn_about_disagreement(iF, disagreeOOF,    'Out of frame', 'r', [-0.2, 0.2], [-5 0])

        % use the average of the two looking times and of OOFdiffs, 
        % and the min of valid.
        data.allLookingTimes(iF,:) = mean(theseLookingTimes(1:2,:), 1);
        data.allOofDiffs(iF,:)     = mean(theseOofDiffs(1:2,:), 1);
        data.allValid(iF,:)        = all(theseValid(1:2,:),1);
        data.allTrialStarts(iF,:)  = mean(theseTrials(1:2,:),1);
        hasConflict = false(1, NTRIALS);
        hasConflict(disagreeValid) = true;
        hasConflict(disagreeLT) = true;
        hasConflict(disagreeOOF) = true;
        data.hasConflict(iF,:)     = hasConflict;
        
        % get percent agreement, ms-by-ms
        msArray1 = msArrays{1};
        msArray2 = msArrays{2};
        if length(msArray1) > length(msArray2)
            msArray2 = [msArray2, -1*ones(1, length(msArray1) - length(msArray2))];
        else
            msArray1 = [msArray1, -1*ones(1, length(msArray2) - length(msArray1))];
        end
        msArrayBoth = [msArray1; msArray2];
        msArrayBoth(:, isnan(msArray1) | isnan(msArray2)) = [];
        fracSame = sum(~logical(msArrayBoth(1,:) - msArrayBoth(2,:)))/size(msArrayBoth,2);
        
        titleText = {titleText, [num2str(fracSame*100, 2) '%']};
        allFracSame(end+1) = fracSame;
        
        data.coderLookingDiffs(iF,:) = theseLookingTimes(1,:) - theseLookingTimes(2,:);
        
    else
        set(gca, 'Color', incompleteColor);
        
        if nCoders == 1
            data.allLookingTimes(iF,:) = theseLookingTimes(1,:);
            data.allOofDiffs(iF,:)     = theseOofDiffs(1,:);
            data.allValid(iF,:)        = theseValid(1,:);
            data.allTrialStarts(iF,:) = theseTrials(1,:);
        end
    end
    
    title(titleText); 
    setfonts(12);
end


% Add a legend to the plot so we can see which color corresponds to which
% coder.
h = newplot(plotNum);
for iC = 1:length(masterListCoders)
    plot([1 NTRIALS], [iC iC], 'LineWidth', 3, 'Color', coderColors(iC,:)); hold on;
end
set(allchild(h),'visible','off'); 
set(h,'visible','off'); 
legend(masterListCoders);
setfonts(12);

% Save the conflicts.
if ~isempty(saveConflictsFile)
    conflictFilepath = fullfile(conflictDir, saveConflictsFile);
    save(conflictFilepath, 'conflicts');
end

    function warn_about_disagreement(iF, disagreeByArray, label, color, xOffset, yOffset)
        % Display a warning message about these disagreements, 
        % add to the list of conflicts, and plot on the figure.
        % 
        % iF: index into fields in data
        % disagreeByArray: binary array, length NTRIALS
        % label: type of disagreement to display and to store in conflicts
        % color: color to use for mark on plot
        % xOffset: [x1, x2] values for line to mark the disagreement on the
        %   plot; [0 0] for vertical. Max abs. value about .2
        % yOffset: [y1, y2] values for line to mark the disagreement on the
        %   plot; [0 0] for horizontal. Max abs. value about .2
        if ~isempty(disagreeByArray)
            fprintf(1, '%s disagreement: \ttrial ', label);
            for iT = 1:length(disagreeByArray)
                % Store this disagreement
                thisConflict = store_disagreement(disagreeByArray(iT), ...
                                   label, ...
                                   {data.allcoders{iF}(1:2)}, ...
                                   data.userid(iF), ...
                                   data.childid{iF}, ...
                                   data.recordingSet{iF});
                isKnownConflict = false;
                for iEC = 1:length(existingConflicts)
                    if thisConflict.userid == existingConflicts(iEC).userid && ...
                       strcmp(thisConflict.recSet, existingConflicts(iEC).recSet) && ...
                       all(ismember(thisConflict.coders, existingConflicts(iEC).coders)) && ...
                       strcmp(thisConflict.child, existingConflicts(iEC).child) && ...
                       thisConflict.trial == existingConflicts(iEC).trial && ...
                       strcmp(thisConflict.type, existingConflicts(iEC).type)
                        
                        isKnownConflict = true;
                        %conflicts(end)=[]; % don't save known conflicts
                        continue;
                    end
                end
                
                if isKnownConflict
                    fprintf(1, '%i(KNOWN) ', disagreeByArray(iT));
                    plot(disagreeByArray(iT)*[1 1]+xOffset, defaultYLim(2)+yOffset, ...
                        'Color', color, 'LineWidth', 2, 'LineStyle', ':');
                else
                    fprintf(1, '%i ', disagreeByArray(iT));
                    plot(disagreeByArray(iT)*[1 1]+xOffset, defaultYLim(2)+yOffset, ...
                        'Color', color, 'LineWidth', 2);
                end
            end
            fprintf(1, '\n');
        end
    end

    function handles = newplot(plotNum)
        % Create a new coder-agreement plot within the big figure
        if mod(plotNum, NCOLS * MAXROWS) == 1 && plotNum > 1
            figure;
            set(gcf, 'Position', figpos);
            figNo = figNo + 1;
        end
        handles = subplot(NROWS, NCOLS, plotNum - figNo*NCOLS*MAXROWS);
    end

    function thisConflict = store_disagreement(trial, disagreeType, coders, id, child, recSet)
        % add a record of the disagreement
        thisConflict = struct('userid', id, ...
                              'recSet', recSet, ...
                              'coders', coders, ...
                              'child', child, ...
                              'trial', trial, ...
                              'type', disagreeType);
        if isempty(conflicts)
            conflicts = [thisConflict];
        else
            conflicts(end+1) = thisConflict;
        end
    end

end
