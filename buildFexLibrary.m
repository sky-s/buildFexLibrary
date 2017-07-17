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
%   BUILDFEXLIBRARY will use a specified directory instead of prompting the user
%   for a destination directory if the 'directory' name/value pair is provided.
%   The destination should be a full path, and the directory must already exist.
%   
%   Optional flags may be passed to BUILDFEXLIBRARY:
% 
%   -noPath
%     Unless noPath is set, BUILDFEXLIBRARY will add everything in the
%     destination folder to the end of the current search path as save the new
%     path.
% 
%   -noShortcut
%     Unless noShortcut is set, BUILDFEXLIBRARY will crete an internet shortcut
%     to the FEX entry webpage in the created entry's folder.
% 
%   -silent
%     If set, only failed download information is displayed in the command
%     window during execution.
% 
%   -useCheckVersion
%     If set, BUILDFEXLIBRARY will attempt to use checkVersion and only use its
%     internal installer if checkVersion fails. Note: the subfolder will be
%     created (but not populated) even if checkVersion finds the entry on the
%     path elsewhere.
% 
%   Example: Download the latest version of this tool.
%     buildFexLibrary({'build FEX library',54832},'destination',pwd,'-silent');
% 
%   See also addpath, path, 
%     checkVersion - www.mathworks.com/matlabcentral/fileexchange/39993.

% Copyright 2015-2017 Sky Sartorius
% Contact: www.mathworks.com/matlabcentral/fileexchange/authors/101715

%% Parse inputs.
% Parse flags:
noPath = strcmpi('-noPath',varargin); varargin = varargin(~noPath);
addToPath = ~any(noPath);

noShortcut = strcmpi('-noShortcut',varargin); varargin = varargin(~noShortcut);
makeShortcut = ~any(noShortcut);

silent = strcmpi('-silent',varargin); varargin = varargin(~silent);
silent = any(silent);

useCheckVersion = strcmpi('-useCheckVersion',varargin); 
varargin = varargin(~useCheckVersion);
useCheckVersion = any(useCheckVersion);

% Parse other inputs:
p = inputParser;
p.FunctionName = 'buildFexLibrary';

p.addOptional('fileList',myFexList,@(x) validateattributes(x,...
    {'cell'},{'ncols',2}));

p.addParameter('destination','',@(x) exist(x,'dir'));

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
if useCheckVersion && ~exist('checkVersion.m','file')
    if ~silent
        disp('checkVersion not available - installing...')
    end
    buildFexLibrary({'checkVersion',39993},'destination',r.destination)
end

%% 
s = pwd; % To come back here later.
cd(r.destination) % Move to destination directory.
warning off MATLAB:MKDIR:DirectoryExists

%% Get files
for i = 1:size(files,1)
    f = files{i,1};
    id = files{i,2};
    
    mkdir(f)
    cd(f)
        
    if useCheckVersion
        [status,message] = checkVersion(f,id,'silent');
    else
        status = 'version check skipped';
    end
        
    switch status
        case {'up-to-date' 'downloaded'}
            % checkVersion did its thing; do nothing.
            if ~silent
                fprintf('%s (version %s): %s\n',status,message,f)
            end
        otherwise % 'unknown','error','version check skipped'
            fileUrl = sprintf('%s%i?download=true',baseURL,id);
            
            if useCheckVersion
                prefix = sprintf('checkVersion failed with status: %s | ',...
                    status);
            else
                prefix = '';
            end
            if ~silent
                fprintf('%sdownloading: %s\n',prefix,f)
            end
            
            tmp_name = tempname;
            try
                unzip(websave(tmp_name,fileUrl),pwd); 
                % Save first to handle GitHub redirect.
                
            catch
                % Could be a non-zipped download (very old FEX entries).
                if ~silent
                    fprintf(['%s failed; making attempt assuming old-style '...
                        'non-zipped m-file\n'],f)
                end
                try
                    nonZipName = [f '.m'];
                    websave(nonZipName,fileUrl);
                catch
                    try delete(nonZipName); end %#ok
                    
                    webUrl = sprintf('%s%i',baseURL,id);
                    command = sprintf('matlab:web(''%s'',''-browser'')',webUrl);
                    linkTxt = sprintf('FEX page of failed download: %s',f);
                    fprintf('%s | <a href="%s">%s</a>\n',...
                        'something went wrong', command, linkTxt);
                end
            end  
            try delete(tmp_name); end %#ok
            
            
    end % switch
    
    if makeShortcut
        % Add internet shortcut (overwrites).
        fid = fopen(['_' f ' on FEX.url'],'w');
        fprintf(fid,'[InternetShortcut]\nURL=%s%i',baseURL,id);
        fclose(fid);
    end
    
    cd(r.destination)
end

if addToPath
    % Add FEX functions to end of path.
    addpath(genpath(r.destination),'-end');
    savepath
end

% Go back to original directory where we started.
cd(s);
