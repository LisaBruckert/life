function fe = feConnectomeInit(dwiFile,dtFile,fgFileName,feFileName,savedir,dwiFileRepeated,anatomyFile,varargin)
%
% Initialize a new connectome (fe) structure. 
%
%    fe = feConnectomeInit(dwiFile,dtFile,fgFileName,feFileName,savedir,dwiFileRepeated,anatomyFile,varargin);
%    
% We allow a set of (paramName,val) pairs in the varargin that will be
% executed as fe = feSet(fe,paramName,val)
%
% Example: 
%
%   baseDir    = fullfile(mrvDataRootPath,'diffusion','sampleData');
%   dtFile     = fullfile(baseDir,'dti40','dt6.mat');
%   dwiFile    = fullfile(baseDir,'raw','dwi.nii.gz');
%   fgFileName = fullfile(baseDir,'fibers','leftArcuate.pdb');
%   fe         = feConnectomeInit(dwiFile,dtFile,fgFileName);
% 
%   fe         = feConnectomeInit(dwiFile,dtFile,fgFileName,'name','test');
%
% Franco (c) 2012 Stanford VISTA Team.

% Handling parallel processing
poolwasopen=1; % if a matlabpool was open already we do not open nor close one
if (matlabpool('size') == 0), matlabpool open; poolwasopen=0; end

% Intialize the fe structure.
fe = feCreate;

% Set the based dir for fe, this dire will be used 
if notDefined('savedir'),  savedir = fullfile(fileparts(dtFile),'LiFE');
end
fe = feSet(fe,'savedir',savedir);

% Get the xforms. 
if isstruct(dtFile), dt = dtFile; clear dtFile
else                 dt = dtiLoadDt6(dtFile);
end
fe = feSet(fe,'dtfile',dtFile);
fe = feSet(fe, 'img2acpc xform', dt.xformToAcpc);
fe = feSet(fe, 'acpc2img xform', inv(dt.xformToAcpc));
clear dt

% Set up the fe name
if isstruct(fgFileName),  n  = fgFileName.name;
else                   [~,n] = fileparts(fgFileName);
end

if notDefined('feFileName'),
  feFileName = sprintf('%s-%s', datestr(now,30),n);
end
fe = feSet(fe, 'name',feFileName);

% Load a connectome
if isstruct(fgFileName), fg = fgFileName; clear fgFileName
else % A file name was passed load the fibers from disk
  fprintf('\n[%s]\n loading fiber from file: %s\n',mfilename,fgFileName)
  fg = fgRead(fgFileName);
end

% Set fg in the fe structure identifying the fg coordinate frame.
% Everything in LiFE is in img coordinates, but everyting in mrDiffusion is in acpc.  
% So here we assume the fibers are read in acpc and we xform them in img.
fe = feSet(fe,'fg from acpc',fg);

% When the ROI is set to empty, LiFE uses all of the voxels within the
% connectome as the ROI.
fe = feSet(fe,'roi fg',[]);
clear fg

% Precompute the canonical tensors for each node in each fiber.
tic
if ~isempty(varargin)
  axialDiffusion  = varargin{1}(1);
  radialDiffusion = varargin{1}(2);
else % Default to stick and ball
  axialDiffusion  = 1;
  radialDiffusion = 0;
end
dParms(1) =  axialDiffusion; 
dParms(2) = radialDiffusion; 
dParms(3) = radialDiffusion;

fe = feSet(fe,'model tensor',dParms);

fprintf('\n[%s] Computing fibers'' tensors... ',mfilename); 
fe = feSet(fe, 'tensors', feComputeCanonicalDiffusion(fe.fg.fibers, dParms));  
toc

% We disregard fibers that have identical trajectories within the ROI.
roi = feGet(fe,'roi coords');
fe  = feSet(fe,'voxel 2 fiber node pairs',fefgGet(feGet(fe,'fg img'),'v2fn',roi));
fe  = feGetConnectomeInfo(fe);

% Install the information about the diffusion data.
fe = feConnectomeSetDwi(fe,dwiFile,0);

% Install the information about a repeated measurement of the diffusion
% data.
if ~notDefined('dwiFileRepeated')
  fe = feConnectomeSetDwi(fe,dwiFileRepeated,1);
end

% Install the path tot he anatomical high-resolution file.
if ~notDefined('anatomyFile')
  fe = feSet(fe,'anatomy file',anatomyFile);
end

% Build LiFE tensors and key connection matrices
fe = feConnectomeBuildModel(fe);

return