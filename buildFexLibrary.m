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
%   for a destination directory if the 'destination' name/value pair is
%   provided. The destination should be a full path, and the directory must
%   already exist.
%
%   Optional flags may be passed to BUILDFEXLIBRARY:
%
%   -noPathAppend
%     Unless noPathAppend is set, BUILDFEXLIBRARY will add everything in the
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
noPath = strcmpi('-noPathAppend',varargin); varargin = varargin(~noPath);
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

p.addOptional('fileList',cell(0,2));
p.addParameter('destination','',@(x) exist(x,'dir'));

parse(p,varargin{:});
r = p.Results;
files = r.fileList;

if isempty(files)
    % Nothing provided - try using myFexList (prioritizing function over var).
    if exist('myFexList','file')
        files = myFexList;
    else
        % May be variable. If not, will throw exception.
        files = evalin('caller','myFexList');
    end
end

% Do checks on file list:
validateattributes(files,{'cell'},{'ncols',2});
validateattributes([files{:,2}],{'numeric'},{'integer','positive'},...
    mfilename,'second column of fileList');
if ~iscellstr(files(:,1))
    error('Column 1 of fileList must contain strings.')
end

if isempty(r.destination)
    r.destination = uigetdir('','Choose destination for FEX library files.');
end

%%
siteBaseUrl = 'http://www.mathworks.com/matlabcentral/fileexchange/';
dlBaseUrl = ['http://www.mathworks.com/matlabcentral/mlc-downloads/'...
    'downloads/submissions/'];%[version#]/versions/1/download/zip

%% Download and add to path checkVerion if needed and not available already:
if useCheckVersion && ~exist('checkVersion.m','file')
    if ~silent
        disp('checkVersion not available - installing...')
    end
    buildFexLibrary({'checkVersion',39993},'destination',r.destination)
end

%%
startingDirectory = pwd; % To come back here later.
cd(r.destination) % Move to destination directory.
warning off MATLAB:MKDIR:DirectoryExists
warning off MATLAB:DELETE:FileNotFound

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
    
    if any(strcmp(status,{'up-to-date' 'downloaded'}))
        % checkVersion did its thing; do nothing.
        if ~silent
            fprintf('%s (version %s): %s\n',status,message,f)
        end
    else % 'unknown','error','version check skipped'
        
        if useCheckVersion && ~silent
            disp('checkVersion failed with status: %s',status);
        end
        
        %% Get website contents to check version and build proper URL.
        siteUrl = sprintf('%s%i',siteBaseUrl,id);
        
        try
            webSite = webread(siteUrl);
        catch ME
            if strcmp(ME.identifier,...
                    'MATLAB:webservices:HTTP404StatusCodeError')
                fprintf('File identifier %i for %s not found.\n',id,f)
                disp(ME.message)
                cd(r.destination); continue
            else
                ME.rethrow
            end
        end
        
        % web(siteUrl,'-browser')
        % downloadUrl = sprintf('%s%i?download=true',siteBaseUrl,id); % Old.
        
        verPattern = ['/' num2str(id) '/versions/(?<version>\d+)/'];
        verMatches = regexp(webSite,verPattern,'names');
        
        tmp_name = tempname;
        
        if numel(verMatches)
            % Version found.
            version = verMatches(1).version;
            if numel(verMatches) > 1 && ~isequal(verMatches.version)
                warning('Multiple version numbers found. Using %s v %s.',...
                    f,version);
            end
            if ~silent
                fprintf('downloading: %20s (version id: %2s)\n',f,version)
            end
            
            downloadUrl = sprintf('%s%i/versions/%s/download/zip',...
                dlBaseUrl,id,version);
            try
                unzip(websave(tmp_name,downloadUrl),pwd);
            catch
                % Could be a non-zipped download (very old FEX entries).
                if ~silent
                    disp([f ' normal download failed.'])
                    disp('Trying assuming old-style non-zipped m-file.')
                end
                try
                    nonZipName = [f '.m'];
                    websave(nonZipName,downloadUrl);
                catch
                    failureaction('Non-zipped attempt failed.')
                end
            end
            
        elseif contains(webSite,['/matlabcentral/fileexchange/assets'...
                '/ico-github-logo.png"']) ...
                && contains(webSite,'://github.com/')
            % Version not found, but there's probably a github repo to try.
            ghPattern = '<a href="(?<ghUrl>https?://github.com/\S+/\S+)/?"';
            ghMatches = regexp(webSite,ghPattern,'names');
            if numel(ghMatches)
                if ~silent
                    fprintf('downloading: %20s (from GitHub)\n',f)
                end
                
                downloadUrl = [ghMatches(1).ghUrl '/archive/master.zip'];
                try
                    unzip(websave(tmp_name,downloadUrl),pwd);
                catch
                    failureaction('Failed attempt to get from GitHub.')
                end
                
            else
                failureaction();
       
            end
            
        else
            % No clues to the version number. Trying version 1 works in some
            % cases, but it is safer to just throw an error to avoid the
            % risk to getting an old version.
            
            failureaction('Required version information not found.')
            
        end
        
        
        try delete(tmp_name); end %#ok
        
        
    end 
    
    if makeShortcut
        % Add internet shortcut (overwrites).
        fid = fopen(['_' f ' on FEX.url'],'w');
        fprintf(fid,'[InternetShortcut]\nURL=%s',siteUrl);
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
cd(startingDirectory);


    function failureaction(msg)
        if nargin < 1
            msg = 'Something went wrong.';
        end

        disp(msg)
        fprintf('<a href="matlab: web %s -browser">%s</a>\n',...
            siteUrl,['FEX page of failed download: ' f]);
    end
end