function exclude = find_repeats(data)
% Check for repeat participants in the struct data
%
% exclude = find_repeats(data)
% 
% data is a struct as created by read_lookit_results_xls; it needs at least
% fields userid, childid, recordingSet, DBID. Exclude is a binary array
% of the same length as data.userid; 'true' means the record should be 
% excluded as a repeat.
%
% Any records with userid AND childid will be displayed and the corresponding
% index in 'exclude' will be true. 
%
% If data has a field 'origData,' potential earlier participation that was 
% already excluded will also be displayed along with the reason for 
% exclusion. Often this will not disqualify participants (e.g. they tried
% to start the study, but it didn't work at all in one browser and they
% tried another) but we need to check these cases.

    % Exclude second (usable) repeat participant
    exclude = false(size(data.DBID));
    for iF = 1:length(data.DBID)
        if any((data.userid(1:(iF-1)) == data.userid(iF)) & ...
                strcmp(data.childid(1:(iF-1)), data.childid{iF})')
            fprintf(1, '\t\tRepeat: User %i, session %s excluded due to previous participation\n', ...
                            data.userid(iF), ...
                            data.recordingSet{iF});
            exclude(iF) = true;
        end
    end
    
    % If we have useData.origData, also warn about previous
    % participation for any data we plan to include

    if isfield(data, 'origData')
        origData = data.origData;
        for iF = 1:length(data.DBID)
            if ~exclude(iF)
                % Check for previous participation and reasons.
                for iOrig = 1:length(origData.DBID)
                    % Terminate once we reach this record
                    if strcmp(data.DBID{iF}, origData.DBID{iOrig})
                        break;
                    elseif data.userid(iF) == origData.userid(iOrig) && ...
                           strcmp(data.childid(iF), origData.childid(iOrig))
                       d = ' ';
                       if isfield(origData, 'date')
                           d = origData.date{iOrig};
                           if isnumeric(d)
                               d = mac_excel_to_ml(d);
                           end
                           d = datestr(d, 'mm-dd-yyyy');
                       end
                       
                        fprintf(1, '\t\tRepeat: User %i, %s may have previously participated (date %s, recSet %s, excluded?: %s)\n', ...
                            data.userid(iF), ...
                            data.childid{iF}, ...
                            d, ...
                            origData.recordingSet{iOrig}, ...
                            origData.reasonExcluded{iOrig});
                    end
                    
                end
            end
        end
    end

end