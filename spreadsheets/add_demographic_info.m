function data = add_demographic_info(data, demo)
% Add cell/numeric arrays of demographic information to a data struct.
% 
% data = add_demographic_info(data, demo)
%
% Input: 
%
% data: a data struct as created by e.g. read_lookit_results_xls. It must
% have at least the field userid.
%
% demo: a data struct as created by e.g. read_lookit_results_xls,
% containing demographic information. It must have at least the field ID,
% which should correspond to the values in data to allow identification of
% a user.
% 
% Output:
% 
% All of the fields in demo will be added to data, prefixed with 'demo_'. 
% For each record i in data, 
% demographic field values will be added based on the row j in demo such
% that demo.ID(j) = data.userid(i). If there is no matching row in demo,
% demographic values will be NaN (for numeric arrays) or [] (for cell
% arrays).
%
% The fields 'demo_incomeNum' and 'demo_maternalEducation' are also added,
% as described below.

demoinds = zeros(size(data.userid));

for i = 1:length(data.userid)
    ind = find(demo.ID==data.userid(i));
    if ~isempty(ind)
        demoinds(i) = ind;
    end
end

fields = fieldnames(demo);
for i = 1:length(fields)
    f = fields{i};
    demoData = demo.(f);
    if iscell(demoData)
        theseValues = cell(size(data.userid));
    else
        theseValues = NaN(size(data.userid));
    end
    theseValues(demoinds ~= 0) = demoData(demoinds(demoinds ~= 0));
    
    data.(['demo_', f]) = theseValues;
end

% Get maternal education, actually an approximation--the education of female
% parents, and the education of partners of male parents. We're making the
% very heteronormative (but generally accurate) assumption that
% the partner of a male parent is the mother. In any event a male
% parent's partner isn't a worse proxy for "maternal education" than his own
% education, and a female parent's education is good enough for our purposes
% even if there are two moms. We chose not to ask for the gender of each 
% parent since we figured this would make parents uncomfortable due to 
% potential misuse of the data, and since this isn't important for any of our
% actual questions.

data.demo_maternalEducation = NaN(size(data.demo_gender));
for i = 1:length(data.demo_gender)
    ed = '';
    if strcmp(data.demo_gender{i}, 'Female')
        ed = data.demo_educationyou{i};
    elseif strcmp(data.demo_gender{i}, 'Male')
        ed = data.demo_educationspouse{i};
    end
    
    edIndex = find(strcmp(ed, {'Not applicable', '', 'Some (or attending) high school', ...
        'High school', 'Some (or attending) college', ...
        'Two-year college degree', 'Four-year college degree', ...
        'Some (or attending) graduate school', 'Graduate degree'}));
    if edIndex==0
        warning('Male parent, no maternal education data - using own education: %i', data.userid{i});
        ed = data.demo_educationyou{i};
        edIndex = find(strcmp(ed, {'Not applicable', '', 'Some (or attending) high school', ...
            'High school', 'Some (or attending) college', ...
            'Two-year college degree', 'Four-year college degree', ...
            'Some (or attending) graduate school', 'Graduate degree'}));
    end
    if isempty(edIndex) || edIndex <= 2
        edNum = NaN;
    elseif edIndex==3 || edIndex == 4 % (some) HS
        edNum = 1;
    elseif edIndex==5 || edIndex == 6 % 2-year degree or some college
        edNum = 2;
    elseif edIndex==7 || edIndex == 8 % 4-year degree or some grad school
        edNum = 3;
    else
        edNum = 4; % adv. degree
    end
    data.demo_maternalEducation(i) = edNum;
end

% Get income level
data.demo_incomeNum = NaN(size(data.demo_familyincome));
for i = 1:length(data.demo_familyincome)
    inc = data.demo_familyincome{i};
    incNum = find(strcmp(inc, {'Prefer not to answer', '', 'Select...', ...
        'Under $30000', '$30000-$50000', '$50000-$75000', '$75000-$100000', 'Over $100000'}));
    if isempty(inc) || incNum < 4
        incNum = NaN;
    elseif incNum == 4
        incNum = 15;
    elseif incNum == 5
        incNum = 30;
    elseif incNum == 6
        incNum = 50; 
    elseif incNum == 7
        incNum = 75;
    elseif incNum == 8
        incNum = 100;
    end
    data.demo_incomeNum(i) = incNum; % 15 = <30K, 30 = 30-50K, 50 = 50-75K, 75 = 75-100K, 100 = 100K+
end


    
