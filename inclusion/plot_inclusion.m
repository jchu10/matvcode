function isBestTake = plot_inclusion(origData, hierarchy, ignore, no_coding_yet_label, ...
    consent_uncoded_label, col2, col2labels, col3, col3labels)
% Create a nice plot of the data we start out with and where it ends up.
%
% plot_inclusion(origData, hierarchy, ignore, no_coding_yet_label, ...
%    consent_uncoded_label, col2, col2labels, col3, col3labels)
%
% origData: data structure as created by read_lookit_results_xls and 
%    set_inclusion; generally stored as data.origData. Must include at
%    least fields childid, userid, and reasonExcluded.
% hierarchy: cell array of values to find in reasonExcluded. participants
%    are classified according ot the HIGHEST (furthest towards end) label
%    they have, so if a child is both included and has an unusable-video
%    label, for instance, they'll be called included. Must include
%    'included'! Note that reasonExcluded values that START with a value in
%    the hierarchy will be classed as being that value--so we can use e.g.
%    unusable_ to cover unusable_novideo, unusable_incomplete4, etc.
% ignore: a single type of reasonExcluded to throw out before starting
%    plotting (generally 'testaccount')
% consent_uncoded_label: what is the reasonExcluded when consent hasn't
% been coded yet?
% no_coding_yet_label: what is the reasonExcluded when we don't have coding
%   yet? (either a string or cell array of strings)
% col2: cell array of reasonExcluded to show in the second column, along
%   with blanket sets 'coded' and 'not yet coded'.
% col2labels: what to call each group in col2
% col3: cell array of reasonExcluded to show in the third column. Include
%   'included' here!
% col3labels: what to call each group in col2
% 
% Makes a figure with three columns, labeled with Ns and descriptions: 
%  Column 1: is consent coded?
%  Column 2: (close-up of consent coded) is video usable?
%  Column 3: (close-up of video usable) is child included?
%
% Adds a field 'isBestTake' to origData that specifies whether this record
% is the one with the highest exclusion label in hierarchy for that child.
% (in case of a tie, only the earliest record has isBestTake true).
%
% Example call (from novelverbs)
% hierarchy = {'testaccount', ...
%              'noconsent', ...
%              'agerange', ...
%              'unusable_', ...
%              'triallength', ...
%              'fussy', ...
%              'parent', ...
%              'lowattention', ... (covers lowattentiontest and lowattentionconv)
%              'badtrainingdata', ...
%              'missingcoding', ...
%              'consent_uncoded'};
% ignore = 'testaccount';
% consent_uncoded_label = 'consent_uncoded';
% no_coding_yet_label = 'missingcoding';
% col2 = {'noconsent', 'agerange', 'unusable_'};
% col2labels = {'No consent', 'Out of age range', 'Unusable video'};
% col3 = {'triallength', 'fussy', 'parent', 'lowattention', 'badtrainingdata'};
% col3labels = {'Bad trial length', 'Fussy', 'Parent interference', 'Low attention', 'Bad training data'};

r = origData.reasonExcluded;

% Transform [] to 'included' in r
for i = 1:length(r)
    if isempty(r{i})
        r{i}='included';
    end
end
         
% Make a list of all unique participants.
ids = origData.userid;
chs = origData.childid;
origData.isBestTake = false(size(origData.userid));

for i = 1:length(ids)
    if chs{i}(1) == '"'
        child = chs{i}(2:end-1);
    elseif ~isempty(chs{i}) && ~strcmp(chs{i}, 'null')
        child = chs{i};
    else
        child = 'child0';
    end
    child = str2num(child(end));
    comb(i) = ids(i) + child/100;
end
[participantList, ~, participantNumber] = unique(comb);

vals = cell(1, length(participantList)); % will line up directly with participantList
% Go through each participant and see what 'highest' value they have
for p = 1:max(participantNumber)
    theseLabels = r(participantNumber==p);
    for iH = length(hierarchy):-1:1
        matches = strncmp(theseLabels, hierarchy{iH}, length(hierarchy{iH}));
        if any(matches)
            vals{p} = hierarchy{iH};
            iBestTake = find(matches, 1);
            allTakeInds = find(participantNumber==p);
            origData.isBestTake(allTakeInds(iBestTake)) = true;
            break;
        end
    end
    if isempty(vals{p})
        warning('unclassified label %s', theseLabels{1});
    end
end

isBestTake = origData.isBestTake;



% Count up values for each label
counts = struct();
for iH = 1:length(hierarchy)
    counts.(hierarchy{iH}) = sum(strcmp(vals, hierarchy{iH}));
end

% Set colors for plot. 3 columns: consent, usable, and coding-based
% exclusion.
width = .8; % width of each bar
consentCodedColors = [.9 .9 .9; 0.5 0.5 0.5]; % just consent coded/not (column 1)
fontSize = 11;

nUsableCategories = length(col2) + 2; % first round of exclusion: do we have usable video? 
% stated exclusion labels + coded + uncoded
usableColors = hsv(nUsableCategories);

nCodedCategories = length(col3); % second round of exclusion: based on child's behavior
baseColor = usableColors(end-1,:);
baseColor = .5+.5*baseColor; % make as light as possible first
codedColors = repmat(baseColor, nCodedCategories, 1) .* ...
              repmat(1-.5*(1/nCodedCategories:1/nCodedCategories:1)', 1, 3);
codedColors = [1 1 1; codedColors];

% Don't display testaccount records at all
counts = rmfield(counts, ignore);
N = sum(cell2mat(struct2cell(counts)));

%% 1. First column: Is consent even coded?
figure;

nConsentUncoded = counts.(consent_uncoded_label);
nConsentCoded = N - nConsentUncoded;
labels = {'Consent coded', 'Consent not coded'};
thisData = [nConsentCoded, nConsentUncoded];
h = bar([1,2],[thisData; 0 0;], width, 'stacked'); hold on;
for iH = 1:2
    set(h(iH), 'FaceColor', consentCodedColors(iH,:));
    if thisData(iH)
        text(1-width/2+ 0.02, sum(thisData(1:iH-1)) + thisData(iH)/2, [labels{iH} ' (' num2str(thisData(iH)) ')'], 'fontSize', fontSize);
    end
end

line([1+width/2, 2-width/2], [0, 0], 'Color', 'k');
line([1+width/2, 2-width/2], [nConsentCoded, nConsentCoded], 'Color', 'k');

%% 2. Second column: Is video usable?
counts = rmfield(counts, consent_uncoded_label);
coded = zeros(size(col3));
for i = 1:length(col3)
    coded(i) = counts.(col3{i});
end
nCoded = sum(coded);

for i = 1:length(col2)
    usableData(i) = counts.(col2{i});
end
if ~iscell(no_coding_yet_label)
    nNoCoding = counts.(no_coding_yet_label);
else
    nNoCoding = sum(cellfun(@(label)counts.(label), no_coding_yet_label));
end

usableData(end+1:end+2) = [nCoded, nNoCoding];
video_usable_labels = {col2labels{:}, 'Coded', 'Not yet coded'};
h = bar([2,1], [usableData; zeros(size(usableData))], width, 'stacked'); 
for iH = 1:length(h)
    set(h(iH), 'FaceColor', usableColors(iH,:));
    if usableData(iH)
        text(2-width/2+ 0.02, sum(usableData(1:iH-1)) + usableData(iH)/2, [video_usable_labels{iH} ' (' num2str(usableData(iH)) ')'], 'fontSize', fontSize);
    end
end

% Find bounds and center of 'nCoded' portion
codedBounds = [sum(usableData(1:(end-2))), sum(usableData(1:(end-1)))];
zoomedBounds = [codedBounds(1)-usableData(end), codedBounds(2)+usableData(end)];
zoomedBounds = [0, codedBounds(2)+usableData(end)];
zoomFactor = diff(zoomedBounds) / diff(codedBounds);

plotCoded = [zoomedBounds(1), coded * zoomFactor];
line([2+width/2, 3-width/2], [codedBounds(1), zoomedBounds(1)], 'Color', 'k');
line([2+width/2, 3-width/2], [codedBounds(2), zoomedBounds(2)], 'Color', 'k');


%% 3. Third column: Is subject included after coding?
h = bar([3,2], [plotCoded; zeros(size(plotCoded))], width, 'stacked'); 
labels = {'', col3labels{:}};

for iH = 1:length(h)
    if iH == 1 % Hide line for invisible 'padding' to position zoom
        set(h(iH), 'EdgeColor', [1 1 1]);
    else
        if plotCoded(iH)
            text(3-width/2+ 0.02, ...
                sum(plotCoded(1:iH-1)) + plotCoded(iH)/2, ...
                [labels{iH} ' (' num2str(coded(iH-1)) ')'], ...
                'fontSize', fontSize);
        end
        set(h(iH), 'EdgeColor', [0.8 0.8 0.8]);
    end
    if iH == length(h)
        set(h(iH), 'EdgeColor', 'b', 'LineWidth', 2);
    end
    set(h(iH), 'FaceColor', codedColors(iH,:));
    
end

xlim([0.6, 3.4]);
ylim([-2, N+2]);
set(gca, 'YGrid', 'off', 'YTick', [], 'box', 'off', ...
    'YColor', 'none', 'XColor', 'none', 'Position', [0.01, 0.01, 0.98, 0.98]);

p = get(gcf, 'Position');
p(3:4) = [400 600];
set(gcf, 'Position', p);
