toolboxpath = fileparts(mfilename('fullpath'));
addpath(genpath(toolboxpath));

% Where to look for the Excel summary and the coding directory
basedir = fileparts(toolboxpath);

% Main coder directory; individual studies have directories within
mainCodingDir = fullfile(basedir, 'Coding');

% Where to find/save conflict files for storing disagreements between VCode
% coders
conflictDir = fullfile(toolboxpath, 'studies/conflicts');

% Where to look for data spreadsheets
dataDir = fullfile(basedir, 'Raw data');

% Where to save csv spreadsheet with coding
processedDir = fullfile(basedir, 'Processed data');

% Where to put data for analysis in R
rDir = fullfile(basedir, 'R analysis testimony');