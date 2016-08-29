function h = plot_points(cellArray, width, offset, colors, markers) 
% Make a 'bar graph' with individual points shown (jittered slightly)
%
% h = plot_points(cellArray, width)
%
% cellArray: either a cell array of N data arrays to plot, or a cell array of
%    M such cell arrays for a grouped display. In the latter case the first
%    element of each of the M arrays will be grouped together, then the second
%    elements, etc. Each element of cellArray is one color. 
% width: Fraction of the space allotted to each 'bar' that the points
%   should occupy. (Closer to 1 for more jittering/wider bars, closer to 0 
%   for tight bars.)
%
% h: an array of handles to the N lineseries objects (or an MxN array if 
%   grouped). Use h(:,1) to get one handle per color.
% 
% Plots into the current axes or creates a new figure if none is available.
% Horizontal lines are drawn at each mean; NaN values are ignored.
%
% Examples:
%    plot_points({1+randn(100,1), randn(100,1)}, .8)
%    plot_points({{1+randn(100,1), 1+2*randn(200,1)}, ...
%                 {randn(100,1), 2*randn(200,1)}}, .8)

N = length(cellArray);

h = [];


if nargin < 3
    offset = 0;
    %colors = [0 0 153; 204 0 0; 0 153 0; 127 0 255]/255;
    colors = [178 178 178; 230 230 230; 120 120 120; 255 255 255]/255;
    markers = 'o^s<';
    if N > 4
        colors = cool(N);
    end
else
    colors = repmat(colors, N,1);
end


if iscell(cellArray{1})
    width = width/N;
    edges = -width : width : width;
    centers = (edges(1:end-1) + edges(2:end))/2;
    for i = 1:N
        h(i,:) = plot_points(cellArray{i}, width, centers(i), colors(i,:), markers(i));
    end
else
    locs = 1:N;
    
    for i = 1:N
        arr = sort(cellArray{i});
        
        granularity = 0.05 * width;
        
        jitter = round((width * 2/3 * rand(1, length(arr)))/granularity)*granularity - width/3;
        
        % Alternate between smaller and larger jitter values
        jitter = sort(jitter); 
        lowInds = randperm(floor(length(jitter)/2));
        highInds = floor(length(jitter)/2) + randperm(ceil(length(jitter)/2));
        jitterInds = zeros(size(jitter));
        jitterInds(2:2:end) = lowInds;
        jitterInds(1:2:end) = highInds;
        jitter = jitter(jitterInds);

        h(i) = plot(locs(i) +offset + jitter, arr, ...
            'Marker', markers(1), ...
            'MarkerSize', 4, ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerEdgeColor', 'k', ...
            'LineStyle', 'none'); 
        hold on;
    end
    
    for i = 1:N
        arr = cellArray{i};
        if ~isempty(arr)
            line(locs(i) + offset + width/2 * [-2/3, 2/3], ...
                 nanmean(arr) * [1 1], ...
                'Color', 'k', 'LineWidth', 1); 
        end
    end
    set(gca, 'XTick', locs, ...
         'XLim', [0 N+1]);
end