%% t_lightHeadlamp
%
%   Use Projected Light Headlamps
%   (with option to try Area light version)
%   Also try to evaluate radiance over the FOV
%
%   D. Cardinal, Stanford University, September, 2023
%
% See also
%  (based on) t_lightProjection
%  t_lightGonimetric
%  t_piIntro_lights

% TIP: Use fclose('all') if you get weird piWrite errors

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
% Use the flat surface as a simple test "wall"
% When we call ...Create it is generated without lights
thisR = piRecipeCreate('flatSurface');
thisR.set('name','Headlamp');  % Name of the recipe

%thisR.show('lights');

% Headlights have a much wider horizontal field
thisR.film.xresolution.value = 640;
thisR.film.yresolution.value = 320;

thisR.camera.fov.type = 'float';
thisR.camera.fov.value = 45.0;

%% show original
%piWRS(thisR,'mean luminance',-1);

%% Change the flat surface to a 'white' or 'gray'

%targetMaterial = 'glossy-white';
targetMaterial = 'diffuse-gray';
%targetMaterial = 'diffuse-white';
piMaterialsInsert(thisR,'name',targetMaterial);

% Assigning material to our target
cube = piAssetSearch(thisR,'object name','Cube');
thisR.set('asset', cube, 'material name', targetMaterial);

% Move it farther away and scale it into a 'wall'

wallDistance = 63 * 1/12 * 1/3.28; % 5'3" to meters
% wallDistance = 5;

thisR.set('asset', cube, 'translation', [0 0 wallDistance]);
% for 'scale' x is width, y is height
% wallWidth = 20;
% wallHeight = 8;
wallWidth = 20;
wallHeight = 8;
thisR.set('asset', cube, 'scale', [wallWidth wallHeight 1]);

%% Add Headlamp

% Use level beam, basically horizon cutoff
% Other option is 'high beam'

% we created the 'cheap-led-beam' and 'cheap-halogen-beam profiles
% usePreset = 'cheap-led-beam';
usePreset = 'cheap-halogen-beam';
% usePreset = 'low beam';

% EARLY experiment with Area light
%usePreset = 'area';

headlight = headlamp('preset',usePreset,'name', 'headlightLight',...
    'recipe', thisR);
headlightLight = headlight.getLight(usePreset);

%% NOTE:
% On the surface scale & power do "the same thing" but they
% definitely don't in the pbrt code.

% Example outputs:
% scale power meanluminance 
%  10,   20,   254
%  10,   10,   127
%  20,   10,   254
%  20,   -1,     5.9
%  10,   -1,     3
%  10,    1,    12.7
%  10,    0,     3

% Remove all the lights
thisR.set('light', 'all', 'delete');

% Add the Headlamp(s)
thisR.set('lights', headlightLight, 'add');

pLight_Left = piAssetSearch(thisR,'light name', headlightLight.name);
thisR.set('asset',pLight_Left,'translation', ...
    thisR.lookAt.from + [0 .05 0]); % move to camera for now

% Sample night sky (don't use when making pure measurements!)
thisR.set('skymap', 'night.exr');

thisR.show('lights');

%%
thisR.set('render type',{'radiance','depth','albedo'});

% add this line to render the scene onec first to get luminance values
scene = piRender(thisR,'mean luminance',-1, 'do_denoise','exr_albedo');
clear luminance
clear meanLuminance
[luminance, meanLuminance] = sceneCalculateLuminance(scene);

if ~ismac %code to add denoising for benchmarking
    piWrite(thisR);
    scene = piRender(thisR,'mean luminance',-1, 'do_denoise','exr_albedo');
    sceneWindow(scene)
else
    piWRS(thisR);
end

