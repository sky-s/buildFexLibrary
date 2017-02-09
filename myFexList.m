function fileList = myFexList()
% List of file exchange files.
% 
%   See also buildFexLibrary.

% Must return n x 2 or n x 3 cell array.

% 3-column cell array: { folder_name | FEX_ID | GitHubUser/Repository }

% Default list for variety of general uses:
fileList = {'carpetplot',52272,'OdonataResearchLLC/CarpetPlotClass'
    'CopyPaste',28016,''
    'cprintf',24093,''
    'disperse',33866,''
    'explorestruct',7828,''
    'export_fig',23629,'altmany/export_fig'
    ...'ezyfit',10176,''
    'git',29154,'manur/MATLAB-git'
    'polygeom',319,''
    'progressbar',6922,''
    'regexpBuilder',41899,''
    'validatedinput',53553,''
    'fevaln',53552,''
    'bisection',28150,''
    'blend',56530,''
    'buildFEXlibrary',54832,''
    'Link',48638,''
    'units',38977,''
    'dispdisp',48637,''
    'tau',48636,''
    'lyt',44040,''
    'cch',43264,''
    'speedtester',43250,''
    'mcd',44043,''
    'mkxlsfunc',40404,''
    'randraw',7309,''
    'randt',61261,''
    'is___',61262,''
    'cosspace',28337,''
    'sinspace',28358,''
    'linspace3',28553,''
    'search_luckysearch',41357,''
    'simps',25754,''
    'styleguide',40795,''
    'txtmenu',28285,''
    'vgrid',56529,''};