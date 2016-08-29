function filenames = generate_filenames(accounts, children, prefix, recordingSet)
% Generate a cell array of filenames to expect for VCode files
%
% filenames = generate_filenames(accounts, children, prefix, recordingSet)
%
% accounts: array of userids (length N--one per record)
% children: cell array of child IDs, including quotes, e.g. {'"child0"",
%   ...}, corresponding to accounts
% prefix: expected start of filename (e.g. 'novelverbs_')
% recordingSet(optional): cell array of recordingSet strings for each
%   record. If this is included, each element of filenames will itself be
%   a cell array containing both the plain filename and one with the
%   appropriate recordingSet appended.
%
% filenames: cell array of filenames, one element per record, corresponding
%   to accounts.
%
% filenames are of the form '[prefix][account][child].txt', e.g. 
% 'novelverbs_231child0.txt'. If recordingSet is provided, then each 
% element is instead a cell array e.g. 
% {'novelverbs_231child0.txt', 'novelverbs_231child0_GhNm8i.txt'} including
% both the plain and extended filenames.

includeRecSet = nargin > 3;

filenames = cell(size(accounts));
for iF = 1:length(accounts)
    plainName = [prefix, num2str(accounts(iF)), children{iF}(2:end-1) '.txt'];
    if includeRecSet
        recSet = recordingSet{iF};
        recSet(recSet=='"') = [];
        filenames{iF} = {[plainName(1:end-4) '_' recSet '.txt'], plainName};
    else
        filenames{iF} = plainName;
    end
end