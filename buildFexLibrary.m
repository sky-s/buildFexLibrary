function buildFexLibrary(varargin)
% BUILDFEXLIBRARY  A tool to download a user-defined list of useful files from
% the MathWorks File Exchange (FEX).
%   
%   BUILDFEXLIBRARY(fileList) will prompt the user to select or create a
%   destination for the FEX library and then attempt to download each FEX entry
%   in the list into its own subfolder. fileList must be an n x 2 or n x 3 cell
%   array, where each row corresponds to a single FEX entry.
%     - The first element in each row contains a name for the entry. The name is
%       chosen by the user. A folder will be created in the destination with
%       this name. 
%     - The second element is the numeric identifier for the FEX entry, found in
%       the entry's URL.
%     - The third element is a string of the form 'GitHubUser/RepositoryName',
%       if the entry is hosted on GitHub.
%   If not provided, default fileList = myFexList.
%
% 
%   Optional parameters may be provided as name/value pairs. Available
%   parameters are:
% 
%   destination
%     If provided, BUILDFEXLIBRARY will use the directory provided instead of
%     prompting the user for a destination directory. An error is returned if
%     the directory does not exist.
% 
%   useCheckVersion
%     If set, BUILDFEXLIBRARY will first attempt to use checkVersion before
%     blindly downloading the entry. Default useCheckVersion = false. Note: the
%     subfolder will be created (but not populated) even if checkVersion finds
%     the entry on the path elsewhere.
%     
%   addToPath
%     If set, BUILDFEXLIBRARY will add everything in the destination folder to
%     the end of the current search path as save the new path. Default addToPath
%     = true.
% 
%   makeShortcut
%     If set, BUILDFEXLIBRARY will crete an internet shortcut to the FEX entry
%     webpage in the created entry's folder. Default makeShortcut = true.
% 
% 
%   Example: Download the latest version of this tool.
%     buildFexLibrary({'build FEX library',54832,'sky-s/buildFexLibrary'});
% 
%   See also addpath, path, 
%     checkVersion - www.mathworks.com/matlabcentral/fileexchange/39993.

% Copyright 2015-2017 Sky Sartorius
% Contact: www.mathworks.com/matlabcentral/fileexchange/authors/101715

%% Parse inputs.
p = inputParser;
p.FunctionName = 'buildFexLibrary';

p.addOptional('fileList',myFexList,@(x) validateattributes(x,{'cell'},{}));
p.addParameter('destination','',@(x) exist(x,'dir'));

p.addParameter('addToPath',true,@(x) validateattributes(x,...
    {'numeric','logical'},{'scalar'}));
p.addParameter('useCheckVersion',false,@(x) validateattributes(x,...
    {'numeric','logical'},{'scalar'}));
p.addParameter('makeShortcut',true,@(x) validateattributes(x,...
    {'numeric','logical'},{'scalar'}));


parse(p,varargin{:});
r = p.Results;
files = r.fileList;

% Do more checks on file list:
validateattributes([files{:,2}],{'numeric'},{'integer','positive'},...
    mfilename,'second column of fileList');
if ~iscellstr(files(:,1))
    error('Column 1 of fileList must contain strings.')
end
if size(files,2) < 3 
    % Third column missing, i.e. nothing in the list lives on GitHub.
    % (NB: the files{:,2} line above makes sure there are at least two colums.)
    files = [files cell(size(files,1),1)];
end


if isempty(r.destination)
    r.destination = uigetdir('','Choose destination for FEX library files.');
end

%%
baseURL = 'http://www.mathworks.com/matlabcentral/fileexchange/';

%% Download and add to path checkVerion if needed and not available already:
if r.useCheckVersion && ~exist('checkVersion.m','file')
    disp('checkVersion not available. Downloading and adding to path....')
    buildFexLibrary({'checkVersion',39993},'destination',r.destination,...
        'useCheckVersion',false,... % Don't rely on defaults.
        'addToPath',true)
end

%% 
s = pwd; % To come back here later.
cd(r.destination) % Move to destination directory.
warning off MATLAB:MKDIR:DirectoryExists

%% Get files
for i = 1:size(files,1)
    f = files{i,1};
    id = files{i,2};
    git = files{i,3};
    
    mkdir(f)
    cd(f)
    
    % don't even bother with git files
    if isempty(git)
        if r.useCheckVersion
            [status,message] = checkVersion(f,id,'silent');
        else
            status = 'version check skipped';
        end
    else
        status = 'git';
    end
        
    switch status
        case {'up-to-date' 'downloaded'}
            % do nothing.

            fprintf('%s (version %s): %s\n',status,message,f)
        
        case {'unknown','error','version check skipped'}
            fprintf('%s | attempting download: %s\n',status,f)            
            try
                fileUrl=sprintf('%s%i?controller=file_infos&download=true',...
                    baseURL,id);
                
                unzip(fileUrl);
                
            catch 
                % Could be a non-zip download. 
                try
                    fprintf('trying download of non-zipped m-file: %s\n',f)
                    websave([f '.m'],fileUrl);
                catch
                    beep
                    fprintf('\tFailed: <a href="%s">%s</a>.\n',...
                        sprintf('%s%i',baseURL,id),...
                        'try manual download');
                    web(sprintf('%s%i',baseURL,id),'-browser');
                end
            end
            
        case 'git'
            fprintf('attempting GitHub download: %s\n',f)
            try % try git download                
                fileUrl=sprintf...
                    ('https://github.com/%s/archive/master.zip',git);
                
                unzip(fileUrl);
                
            catch
                beep
                fprintf('\tGit failed: <a href="%s">%s</a>.\n',...
                    sprintf('%s%i',baseURL,id),...
                    'try manual download');
                web(sprintf('%s%i',baseURL,id),'-browser');
            end
    end
    
    if r.makeShortcut
        % Add internet shortcut (overwrites).
        fid = fopen(['_' f ' on FEX.url'],'w');
        fprintf(fid,'[InternetShortcut]\nURL=%s%i',baseURL,id);
        fclose(fid);
    end
    
    cd(r.destination)
end

if r.addToPath
    % Add FEX functions to end of path.
    addpath(genpath(r.destination),'-end');
    savepath
end

% Go back to original directory where we started.
cd(s);

% Revision History
%{
2016-01-10 First documented version created. Added this to default list.
2016-01-20 Allow for 2-column file list if nothing on GitHub. 
2017-01-24 Added some files to default list; some formatting.
2017-02-07
    Moved default list out of function file.
    Made fileList first argument instead of name/value pair.
    Name change for style.
2017-02-09 Revisino history now on git.
%}