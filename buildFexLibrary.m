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
%   addToPath
%     If set, BUILDFEXLIBRARY will add everything in the destination folder to
%     the end of the current search path as save the new path. Default addToPath
%     = true.
% 
%   makeShortcut
%     If set, BUILDFEXLIBRARY will crete an internet shortcut to the FEX entry
%     webpage in the created entry's folder. Default makeShortcut = true.
% 
%   silent
%     If set, only failed download information is displayed in the command
%     window during execution. Default silent = false.
% 
%   useCheckVersion
%     If set, BUILDFEXLIBRARY will attempt to use checkVersion and only use its
%     internal installer if checkVersion fails. Default useCheckVersion = false.
%     Note: the subfolder will be created (but not populated) even if
%     checkVersion finds the entry on the path elsewhere.
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
p.addParameter('silent',false,@(x) validateattributes(x,...
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
    if ~r.silent
        disp('checkVersion not available - installing...')
    end
    buildFexLibrary({'checkVersion',39993},'destination',r.destination,...
        'useCheckVersion',false,... % Don't rely on defaults.
        'addToPath',true,...
        'silent',r.silent)
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
        
    if r.useCheckVersion
        [status,message] = checkVersion(f,id,'silent');
    else
        status = 'version check skipped';
    end
        
    switch status
        case {'up-to-date' 'downloaded'}
            % checkVersion did its thing; do nothing.
            if ~r.silent
                fprintf('%s (version %s): %s\n',status,message,f)
            end
        otherwise % 'unknown','error','version check skipped'
            fileUrl = sprintf('%s%i?download=true',baseURL,id);
            
            if r.useCheckVersion
                prefix = sprintf('checkVersion failed with status: %s | ',...
                    status);
            else
                prefix = '';
            end
            if ~r.silent
                fprintf('%sdownloading: %s\n',prefix,f)
            end
            
            tmp_name = tempname;
            try
                unzip(websave(tmp_name,fileUrl),pwd); 
                % Save first to handle GitHub redirect.
                
            catch
                % Could be a non-zipped download (very old FEX entries).
                if ~r.silent
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
2017-02-09 See git.
%}