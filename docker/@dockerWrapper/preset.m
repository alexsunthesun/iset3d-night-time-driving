function preset(thisD, presetName,varargin)
%PRESET - Set dockerWrapper prefs from a list of preset computer/GPUs
%
% Synopsis
%   dockerWrapper.preset(name,'save',[false])
%
% Brief
%   We support a number of remote rendering configurations at
%   vistalab. Specifying one of these returns a dockerWrapper
%   configured to run on a specific machine and GPU
%
% Input
%  presetName -
%   localGPU, localGPU-alt - we determine your local machine (host) and
%           configure for GPU 0 or 1 (-alt)
%
%   'remoteMux','remoteMux-alt' - Run on MUX either GPU 0 or GPU 1
%   'remoteOrange','remoteOrange-alt - Run on orange on GPU 0 or GPU 1
%
% See also
%

% Examples
%{
thisD = dockerWrapper.humanEyeDocker;
%}
%{
thisD = dockerWrapper;
thisD.preset('remote orange');
thisD.prefsave;
%}
%{
thisD.preset('remote mux');
thisD.prefsave;
getpref('docker')
%}
%{
thisD = dockerWrapper;
thisD.preset('human eye');
%}
%{
thisD.prefload
%}
presetName = ieParamFormat(presetName);

validNames = {'localgpu','localgpu-alt','remotemux','remotemux-alt','remoteorange','remoteorange-alt','humaneye'}; 
if ~ismember(presetName,validNames)
    disp('Valid Names (allowing for ieParamFormat): ')
    disp(validNames);
    error('%s not in valid set %s\n',presetName); 
end

thisD.reset;

switch presetName
    case {'humaneye'}
        thisD.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
        thisD.gpuRendering = 0;
        return;

    % for use on Linux servers with their own GPU
    case {'localgpu', 'localgpu-alt'}
        % Render locally on Fastest GPU
        thisD.gpuRendering = true;
        thisD.localRender = true;
        thisD.remoteResources = true;
        thisD.renderContext = 'default';

        % Different machines have diffrent GPU configurations
        [status, host] = system('hostname');
        if status, disp(status); end
        
        host = strtrim(host); % trim trailing spaces
        switch host
            case 'orange'
                thisD.localImageName = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                switch presetName
                    case 'localgpu'
                        thisD.whichGPU = 1;
                    case 'localgpu-alt'
                        thisD.whichGPU = 0;
                end
            case {'mux', 'muxreconrt'}
                thisD.localImageName = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                switch presetName
                    case 'localgpu'
                        thisD.whichGPU = 0;
                    case 'localgpu-alt'
                        thisD.whichGPU = 1;
                end
            otherwise
                thisD.whichGPU=0;
        end
    case {'remotemux', 'remoteorange', 'remoteorange-alt', 'remotemux-alt'}
        % Render remotely on GPU
        thisD.gpuRendering = true;
        thisD.localRender = false;
        thisD.remoteResources = true;

        % find our current user name -- seems like Matlab doesn't have a
        % function?
        userName = char(java.lang.System.getProperty('user.name'));
        % pick the correct context
        switch presetName
            case {'remotemux', 'remotemux-alt'}
                thisD.renderContext = 'remote-mux';
                thisD.remoteMachine = 'muxreconrt.stanford.edu';
                thisD.remoteRoot = ['/home/' userName];
            case {'remoteorange', 'remoteorange-alt'}
                thisD.renderContext =  'remote-orange';
                thisD.remoteMachine = 'orange.stanford.edu';
                thisD.remoteRoot = ['/home/' userName];
        end

        % also pick GPU and docker image
        switch presetName
            case 'remotemux'
                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                thisD.whichGPU = 0;
            case 'remotemux-alt'
                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                thisD.whichGPU = 1;
            case 'remoteorange'
                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                thisD.whichGPU =1;
            case 'remoteorange-alt'
                thisD.remoteImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                thisD.whichGPU = 0;
        end
end
