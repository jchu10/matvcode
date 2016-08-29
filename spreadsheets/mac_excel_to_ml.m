% Simple utility to convert a Mac Excel date number to a Matlab date
% number. Set is1904sys to true to start counting at Jan 1, 1904; otherwise
% use Jan 1, 1900.
function d = mac_excel_to_ml(datenum, is1904sys)

if nargin < 2
    is1904sys = false;
end

if is1904sys
    d = datenum + 695422;
else
    d = datenum + 693960;
end