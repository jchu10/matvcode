% Quickly count and display number of unique *accounts* across studies

basedir = '/Users/kms/ECCL/Lookit project/Results/150921/';

studies = {'consent_novelverbs.xls', 'consent_testimony.xls', ...
    'consent_oneshot.xls'};

ids = [];
hasConsent = [];

for iStudy = 1:length(studies)
    data = read_lookit_results_xls(fullfile(basedir, studies{iStudy}));
    ids = [ids, data.userid];
    hasConsent = [hasConsent; strcmpi(data.consent, 'yes')];
end

allConsentIDs = unique(ids(logical(hasConsent)));

fprintf('%i unique accounts with at least one valid consent video\n', length(allConsentIDs));