clear;
clc;

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% spm fmri
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

% then add cpp repo to prevent repo version compatibility issue
run ../lib/bidspm/initCppSpm.m;

% lastly, we add all the subfunctions that are in the sub directories
opt = getOptionMoebiusMvpa();



%% prepare the rois

opt.unzip.do = false;
opt.save.roi = true;
opt.outputDir = []; % if this is empty new masks are saved in the current directory.
if opt.save.roi
  opt.reslice.do = true;
else
  opt.reslice.do = false;
end

ffxDir = getFFXdir('pil011', funcFWHM, opt);
dataImage = fullfile(ffxDir, ['4D_beta_',num2str(funcFWHM),'.nii']);
roiPath = '/Users/battal/Cerens_files/fMRI/Processed/MoebiusProject/derivatives/roi/atlases/spmAnatomy/';
binaryMap = fullfile(roiPath,'ROI_PSC_3a_R_MNI.nii');

% rename & reslice if needed
roiName = prepareRoi(opt, binaryMap, dataImage);

% get some data from roi
dataMask = spm_summarise(dataImage, roiName);
[voxelNb, dimRoi] = voxelCountAndDimensions(roiName);

% out of curiosity look at voxelNb before the reslicing
rawmask = fullfile(roiPath, 'source', 'ROI_PSC_3a_L_MNI.nii');
[voxelNbRaw, dimRaw] = voxelCountAndDimensions(rawmask);

%get data from your 4D beta mask
dataImageMask = fullfile(ffxDir, 'mask.nii');
[~, dimData] = voxelCountAndDimensions(dataImageMask);

% dimData and dimRoi should match
% consider adding a warning message here for that 

% combine 3a and 3b:
roiInfo = combineMasks(roiPath);


