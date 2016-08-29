function codePresent = detect_code(codeStr, codeCell)
% Detect whether the string codeStr is in each cell codeCell or not
%
% codePresent = detect_code(codeStr, codeCell)
%
% codeStr: string to find (e.g. 'peek')
% codeCell: a cell array (indexed by trial) where each element is either 
%   empty or a cell array of strings that apply to that trial 
%   ('peek', 'talk', etc.); length T
% 
% codePresent: binary array (length T); codePresent(i) is true if
%   codeStr is an element of codeCell{i}
%
% Simple wrapper written to make dealing with empty codeCell elements 
% readable.

for i = 1:length(codeCell)
    if isempty(codeCell{i})
        codePresent(i) = false;
    else
        codePresent(i) = ismember({codeStr}, codeCell{i});
    end
end
