function [birthdate, ageDays, missingBirthdate, countSlight, countModerate, ...
    countLarge, countOnly1, countMissing, ageDaysDB, ageDaysPS, ageDaysAS] ...
    = check_birthdates(data)
% Check whether database and poststudy DOBs agree; calculate ages
%
% [birthdate, ageDays, missingBirthdate] = check_birthdates(data)
%
% Input:
% data: data struct as created by read_lookit_results_xls; required fields
% are dobfromdatabase, dobpoststudy, dobassigned, date, userid, childid.
%
% Output:
% birthdate: cell array of cleaned birthdates
% ageDays: numeric array of ages in days based on cleaned birthdates and
%   study dates; NaN if missing
% missingBirthdate: logical array of whether a birthdate is missing
% countSlight, countModerate, countLarge: numbers of records with slight, 
%    moderate, large differences between age based on registration and
%    poststudy DOB
% countOnly1, countMissing: numbers of records with only one of
%   registration/poststudy DOB, and with neither, respectively
% ageDaysDB, ageDaysPS, ageDaysAS: arrays of ages in days for each record
%   based on database, poststudy, and assigned DOBs, respectively; -1 when
%   value is not available.
%
% Warnings will be shown for any differences between the database DOB and 
% the DOB entered post-study, and if there's no DOB in the database. 
% Small differences are averaged; for substantial differences we use the 
% one entered poststudy. Large differences are treated as missing
% birthdates. (See the first few lines to set how big a difference is
% substantial or large!) If an assigned birthdate (data.dobassigned) is 
% available, it's used instead of any other data.
%
% Important: DOBs are assumed to come from a Mac Excel spreadsheet, which 
% affects the date they're counted from! 

diffThresholdAvg = 31; % differences up to this many days will be averaged and called 'slight'
diffThresholdPS  = 366; % differences up to this many days we'll use poststudy and call 'substantial'
% Above this threshold, we call 'large' and treat as a missing birthdate unless we have a
% manually assigned birthdate

missingBirthdate = false(size(data.dobfromdatabase));
ageDays = NaN(size(data.dobfromdatabase))';

ageDaysDB = -1*ones(size(data.dobfromdatabase))';
ageDaysPS = -1*ones(size(data.dobfromdatabase))';
ageDaysAS = -1*ones(size(data.dobfromdatabase))';

countSlight = 0;
countModerate = 0;
countLarge = 0;
countOnly1 = 0;
countMissing = 0;

for i = 1:length(data.dobfromdatabase)

    [d, cleanedDates] = datediff(data.dobfromdatabase{i}, data.dobpoststudy{i});
    dateformat = 'dd-mmm-yyyy';
    
    if cleanedDates(1) ~= Inf
        ageDaysDB(i) = datediff(datestr(cleanedDates(1), 'yy-mm-dd'), data.date{i});
    end
    if cleanedDates(2) ~= Inf
        ageDaysPS(i) = datediff(datestr(cleanedDates(2), 'yy-mm-dd'), data.date{i});
    end

    if abs(d) == Inf
        if cleanedDates(1) == Inf
            birthdate{i} = datestr(cleanedDates(2), dateformat);
            fprintf(1, '\tNo DOB in database for user %i, child %s (using poststudy)\n', data.userid(i), data.childid{i});
        else
            birthdate{i} = datestr(cleanedDates(1), dateformat);
        end
        countOnly1 = countOnly1 + 1;
    elseif isnan(d)
        birthdate{i} = '';
        fprintf(1, '\tNo DOB for user %i, child %s\n', data.userid(i), data.childid{i});
        missingBirthdate(i) = true;
        countMissing = countMissing + 1;
    else
        if isnumeric(data.dobassigned)
            assigned = data.dobassigned(i);
        else
            assigned = data.dobassigned{i};
        end
        if isnumeric(assigned) && ~isnan(assigned)
            assigned = mac_excel_to_ml(assigned);
        end
        if isnan(assigned)
            assigned = [];
        end
        
        if abs(d) == 0 % poststudy, database agree
            if ~isempty(assigned)
                fprintf(1, '\tNo DOB difference for user %i, child %s: database %s (age %.2f), post-study %s (age %.2f) ', ...
                    data.userid(i), data.childid{i}, ...
                    datestr(cleanedDates(1), dateformat), datediff(data.dobfromdatabase{i}, data.date{i})/365, ...
                    datestr(cleanedDates(2), dateformat), datediff(data.dobpoststudy{i}, data.date{i})/365);
                birthdate{i} = datestr(assigned, dateformat);
                fprintf(1, '- but using assigned (nonstandard): %s\n', datestr(assigned, dateformat));
            else
                birthdate{i} = datestr(cleanedDates(2), dateformat);
            end            
        else % some discrepancy
            if abs(d) <= diffThresholdAvg
                fprintf(1, '\tSlight DOB difference for user %i, child %s: database %s (age %.2f), post-study %s (age %.2f) ', ...
                    data.userid(i), data.childid{i}, ...
                    datestr(cleanedDates(1), dateformat), datediff(data.dobfromdatabase{i}, data.date{i})/365, ...
                    datestr(cleanedDates(2), dateformat), datediff(data.dobpoststudy{i}, data.date{i})/365);
                countSlight = countSlight + 1;
                if ~isempty(assigned)
                    fprintf(1, '- using assigned (nonstandard): %s\n', datestr(assigned, dateformat));
                    birthdate{i} = datestr(assigned, dateformat);
                else
                    fprintf(1, '- using average\n');
                    birthdate{i} = datestr((cleanedDates(1)+cleanedDates(2))/2, dateformat);
                end
            elseif abs(d) <= diffThresholdPS
                fprintf(1, '\tSubstantial DOB difference for user %i, child %s: database %s (age %.2f), post-study %s (age %.2f)', ...
                    data.userid(i), data.childid{i}, ...
                    datestr(cleanedDates(1), dateformat), datediff(data.dobfromdatabase{i}, data.date{i})/365, ...
                    datestr(cleanedDates(2), dateformat), datediff(data.dobpoststudy{i}, data.date{i})/365);
                countModerate = countModerate + 1;
                if ~isempty(assigned)
                    fprintf(1, '- using assigned (nonstandard): %s\n', datestr(assigned, dateformat));
                    birthdate{i} = datestr(assigned, dateformat);
                else
                    fprintf(1, '- using poststudy\n');
                    birthdate{i} = datestr(cleanedDates(2), dateformat);
                end
            else
                fprintf(1, '\tLarge DOB difference for user %i, child %s: database %s (age %.2f), post-study %s (age %.2f)', ...
                    data.userid(i), data.childid{i}, ...
                    datestr(cleanedDates(1), dateformat), datediff(data.dobfromdatabase{i}, data.date{i})/365, ...
                    datestr(cleanedDates(2), dateformat), datediff(data.dobpoststudy{i}, data.date{i})/365);
                countLarge = countLarge + 1;
                if ~isempty(assigned)
                    fprintf(1, '- using assigned: %s\n', datestr(assigned, dateformat));
                    birthdate{i} = datestr(assigned, dateformat);
                else
                    fprintf(1, '- TREATING AS MISSING\n');
                    birthdate{i} = '';
                    missingBirthdate(i) = true;
                end
            end
        end
    end
    
    if ~missingBirthdate(i)
        ageDays(i) = datediff(datestr(birthdate{i}, 'yy-mm-dd'), data.date{i});
    end
    
    if ~isempty(assigned)
        ageDaysAS(i) = datediff(datestr(birthdate{i}, 'yy-mm-dd'), data.date{i});
    end
    
end

