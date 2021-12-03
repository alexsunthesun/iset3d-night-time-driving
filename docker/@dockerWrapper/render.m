function [status, result] = render(obj, renderCommand, outputFolder)

if obj.gpuRendering == true
    useContainer = obj.getContainer('PBRT-GPU');
    % okay this is a hack!
    renderCommand = replaceBetween(renderCommand, 1,4, 'pbrt --gpu ');
else
    useContainer = obj.getContainer('PBRT-CPU');
end

% Windows doesn't seem to like the t flag
if ispc
    flags = '-i ';
else
    flags = '-it ';
end

% ASSUME that if we supply a context it is on a Linux server
if ~isempty(obj.renderContext)
    useContext = obj.renderContext;
    outputFolder = dockerWrapper.pathToLinux(outputFolder);
else
    useContext = 'default';
end
        
% sync data over
if ispc
    rSync = 'wsl rsync'
else
    rSync = 'rsync'
end
% system(sprintf('%s -a %s %s',rSync, localScene, remoteScene);
containerRender = sprintf('docker --context %s exec %s %s sh -c "cd %s && %s"',useContext, flags, useContainer, outputFolder, renderCommand);
[status, result] = system(containerRender);
if status == 0
    % sync data back
    % system(sprintf('%s -a %s %s',rSync, remoteScene, localScene);
end
end