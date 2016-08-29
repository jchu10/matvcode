function reassign_coders(input_conflict_file, output_conflict_file)

f = load(input_conflict_file);
conflicts = f.conflicts;

lastSetID = {};
lastSetCoders = {};
newConflicts = conflicts;

for iC = 1:length(conflicts)
    c = conflicts(iC);
    disp(c);
    thisSetID = {c.userid, c.recSet};
    
    % If this is the same set of problems, just tag along on who's coding
    if isequal(thisSetID, lastSetID)
        theseCoders = lastSetCoders;
    else
    
        coder1 = input(['Enter coder 1 name (', c.coders{1}, '): '], 's');
        if isempty(coder1)
            coder1 = c.coders{1};
        end

        coder2 = input(['Enter coder 2 name (', c.coders{2}, '): '], 's');
        if isempty(coder2)
            coder2 = c.coders{2};
        end
        
        theseCoders = {coder1, coder2};
        
        lastSetID = thisSetID;
        lastSetCoders = theseCoders;
    end
    
    newConflicts(iC) = c;
    newConflicts(iC).coders = theseCoders;
    
end

conflicts = newConflicts;
save(output_conflict_file, 'conflicts');