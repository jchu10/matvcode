function [diffDays, outdates] = datediff(date1, date2)
% Computes difference between two dates (mac Excel/yyyy-(m)m-(d)d)
%
% [diffDays, outdates] = datediff(date1, date2)
%
% diffDays: date2-date1 in days.  If a date is an integer it is assumed to be
% a Mac Excel date, otherwise it is assumed to be formatted yyyy-(m)m-(d)d.
%
% outdates: [date1, date2] as Matlab date numbers (datenum)

dates = {date1, date2};
outdates = [];

for i = 1:2
    thisDate = dates{i};
    if isnumeric(thisDate) % Mac Excel offset
        d1 = mac_excel_to_ml(thisDate);
    elseif length(thisDate) == 0 % treat empty strings as Inf
        d1 = Inf;
    else 
        pieces = strsplit(thisDate, '-');
        if length(pieces{1}) == 4
            formatStr = 'yyyy';
        else
            formatStr = 'yy';
        end
        if length(pieces{2}) == 1
            pieces{2} = ['0', pieces{2}];
        end
        if length(pieces{3}) == 1
            pieces{3} = ['0', pieces{3}];
        end
        formatStr = [formatStr, '-mm-dd'];
        d1 = datenum([pieces{1}, '-', pieces{2}, '-', pieces{3}], formatStr);
    end
    outdates(i) = d1;
end

diffDays = outdates(2) - outdates(1);