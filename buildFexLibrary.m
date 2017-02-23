function buildFexLibrary(varargin)
% BUILDFEXLIBRARY  A tool to download a user-defined list of useful files from
% the MathWorks File Exchange (FEX).
%   
%   BUILDFEXLIBRARY(fileList) will prompt the user to select or create a
%   destination for the FEX library and then attempt to download each FEX entry
%   in the list into its own subfolder. fileList must be an n x 2 cell array, 
%   where each row corresponds to a single FEX entry.
%     - The first element in each row contains a name for the entry. The name is
%       chosen by the user. A folder will be created in the destination with
%       this name. 
%     - The second element is the numeric identifier for the FEX entry, found in
%       the entry's URL.
%   If not provided, default fileList = myFexList.
%
% 
%   Optional parameters may be provided as name/value pairs. Available
%   parameters are:
% 
%   destination
%     If provided, BUILDFEXLIBRARY will use the directory provided instead of
%     prompting the user for a destination directory. The provided destination
%     should be a full path, and the directory must already exist.
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
%     buildFexLibrary({'build FEX library',54832});
% 
%   See also addpath, path, 
%     checkVersion - www.mathworks.com/matlabcentral/fileexchange/39993.

% Copyright 2015-2017 Sky Sartorius
% Contact: www.mathworks.com/matlabcentral/fileexchange/authors/101715

%% Parse inputs.
p = inputParser;
p.FunctionName = 'buildFexLibrary';

p.addOptional('fileList',myFexList,@(x) validateattributes(x,...
    {'cell'},{'ncols',2}));

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
    
    if r.useCheckVersion
        mkdir(f)
        cd(f)
        [status,message] = checkVersion(f,id,'silent');
        cd(r.destination)
    else
        status = 'version check skipped';
    end
        
    switch status
        case {'up-to-date' 'downloaded'}
            % checkVersion did its thing; do nothing.
            fprintf('%s (version %s): %s\n',status,message,f)
            
        otherwise % 'unknown','error','version check skipped'
            fileUrl = sprintf('%s%i?download=true',baseURL,id);
            
            fprintf('%s | attempting download: %s\n',status,f)
            
            tmp_name = tempname;
            try
                unzip(websave(tmp_name,fileUrl),f); 
                % Save first to handle GitHub redirect.
            catch
                % Could be a non-zipped download (very old FEX entries).
                try
                    fprintf(['%s failed; making attempt assuming old-style '...
                        'non-zipped m-file\n'],f)
                    websave([f filesep f '.m'],fileUrl);
                catch
                    beep
                    fprintf('\Something went wrong: <a href="%s">%s</a>.\n',...
                        sprintf('%s%i',baseURL,id),...
                        'opening FEX page of failed download');
                    web(sprintf('%s%i',baseURL,id),'-browser');
                end
            end  
            try delete(tmp_name); end %#ok<TRYNC>
            
            
    end % switch
    
    if r.makeShortcut
        % Add internet shortcut (overwrites).
        fid = fopen([f filesep '_' f ' on FEX.url'],'w');
        fprintf(fid,'[InternetShortcut]\nURL=%s%i',baseURL,id);
        fclose(fid);
    end
    
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
2017-02-09 Revision history now on git.
%}