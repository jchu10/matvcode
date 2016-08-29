function data = get_actual_coders(data, codingDir, NTRIALS, readFunction)
% Figure out which coders actually have valid files for each record
% 
% data = get_actual_coders(data, codingDir, NTRIALS, readFunction)
%
% data: a struct as created by read_lookit_results_xls, with at least 
%    fields allcoders (a cell array of cell arrays of coder names per 
%    record) and filenames (either a cell array of filenames or a cell
%    array of possible cell arrays of filenames, in preference order)
% codingDir: main directory to expect coder directories in. Path to the 
%    coding file 'filename' by 'coder' will be codingDir/coder/filename.
% NTRIALS: expected number of trials to be found when reading coding files.
%    If the expected number is not read, the coding file is treated as invalid
% readFunction: a function that takes a coding file name as an argument and
%    returns as a first output the looking times per trial (or some other 
%    variable with length equal to the number of trials read)
%
% This function updates data.allcoders to include only coders where the
% coding file actually exists, can be read without error, and has an
% appropriate number of trials. It also sets data.missingCoding to a binary
% array that's true wherever the number of actual coders is 0.

minTrials = NTRIALS;
maxTrials = NTRIALS;

for iF = 1:length(data.allcoders)
    actualCoders = {};
    for iC = 1:length(data.allcoders{iF})
        thisCoder = data.allcoders{iF}{iC};
        if ~iscell(data.filenames{iF})
            data.filenames{iF} = {data.filenames{iF}};
        end
        
        foundFile = false;
        for iFilename = 1:length(data.filenames{iF})
            
            if ~foundFile
                filename = fullfile(codingDir, thisCoder, data.filenames{iF}{iFilename});
                if ~exist(filename, 'file')
                    if iFilename == length(data.filenames{iF})
                        warning('No coding files: %s, %s', thisCoder, filename);
                    end
                else
                    try
                        lookingTimes = readFunction(filename);
                    catch
                        warning('Can''t read coding file %s', filename);
                        continue;
                    end
                    if length(lookingTimes) > maxTrials
                        warning('Too many trials, not using (%i, %s, %s)', ...
                            length(lookingTimes), thisCoder, filename);
                    elseif length(lookingTimes) < minTrials
                        warning('Too few trials, not using (%i, %s, %s)', ...
                            length(lookingTimes), thisCoder, filename);
                    else 
                        if length(lookingTimes) ~= maxTrials
                            warning('Too few trials, but using! (%i, %s, %s)', ...
                              length(lookingTimes), thisCoder, filename);
                        end
                        actualCoders{end+1} = thisCoder;
                        foundFile = true;
                        data.filenamesByCoder{iF}{length(actualCoders)} = data.filenames{iF}{iFilename};
                    end
                end
            end
        end
    end
    data.allcoders{iF} = actualCoders;
    data.missingCoding(iF) = length(actualCoders) == 0;
end