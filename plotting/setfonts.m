function setfonts(fontSize)
% Utility to set all fonts on the current figure to fontSize.
%
% setfonts(fontSize)

set(findall(gcf,'type','text'), ...
    'FontName', 'Helvetica', ...
    'FontSize', fontSize, ...
    'Color', 'k')

allAxesInFigure = findall(gcf,'type','axes');
for ax = allAxesInFigure
    set(ax, 'FontName', 'Helvetica', ...
            'FontSize', fontSize);
end