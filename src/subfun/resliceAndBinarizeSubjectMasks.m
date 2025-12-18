function resliceAndBinarizeSubjectMasks(subLabel, opt)
% Reslice and binarize all masks for one subject
%
% Usage:
%   resliceAndBinarizeSubjectMasks('sub-ctrl001', opt)
%
% Inputs:
%   subLabel        - subject label (e.g., 'sub-ctrl001')
%   opt             - options struct with:
%       opt.session         - session (e.g., 'ses-001')
%       opt.taskName        - task name
%       opt.reslice.do      - whether to reslice
%       opt.save.roi        - whether to save ROI
%       opt.threshold       - binarization threshold
%       opt.mainDir         - main fMRI directory
%       opt.space           - space name (e.g., 'MNI152NLin2009cAsym')
%       opt.statsBaseDir    - base directory for stats
%       opt.maskBaseDir     - base directory for masks

%% Define subject-specific paths
% Input: warped masks per subject (from bash warp script)
maskInputDir = fullfile(opt.maskBaseDir, subLabel);

% Output: resliced subfolder
maskOutputDir = fullfile(maskInputDir, 'resliced');

% Reference stats directory (for 4D image)
refStatsDir = fullfile(opt.statsBaseDir, subLabel, ...
                       sprintf('task-%s_space-%s_FWHM-2', opt.taskName, opt.space));

% Check input directory exists
if ~exist(maskInputDir, 'dir')
    fprintf('  ✗ Mask input directory not found: %s\n', maskInputDir);
    return;
end

% Check reference stats directory
if ~exist(refStatsDir, 'dir')
    fprintf('  ✗ Reference stats directory not found: %s\n', refStatsDir);
    return;
end

% Create output directory if it doesn't exist
if ~exist(maskOutputDir, 'dir')
    mkdir(maskOutputDir);
end

%% Load reference 4D image and check dimensions
refImageName = sprintf('%s_task-%s_space-%s_desc-4D_tmap.nii', ...
                       subLabel, opt.taskName, opt.space);
refImage = fullfile(refStatsDir, refImageName);

if ~exist(refImage, 'file')
    fprintf('  ✗ Reference 4D tmap not found: %s\n', refImage);
    return;
end

% Get reference dimensions
hdr = spm_vol(refImage);
refDim = hdr(1).dim;  % Get first volume's dimensions
fprintf('  Reference 4D: %s\n', refImageName);
fprintf('  Reference dims: [%d %d %d]\n', refDim(1), refDim(2), refDim(3));

%% Find all .nii masks in input directory
niiMasks = spm_select('FPList', maskInputDir, '^.*\.nii$');

if isempty(niiMasks)
    fprintf('  ✗ No .nii masks found in: %s\n', maskInputDir);
    return;
end

niiMasks = cellstr(niiMasks);
fprintf('  Found %d mask(s) to process\n\n', length(niiMasks));

%% Create temporary directory for intermediate files
tempDir = fullfile(maskOutputDir, 'temp');
if ~exist(tempDir, 'dir')
    mkdir(tempDir);
end

%% Process each mask
for iMask = 1:length(niiMasks)
    originalMask = niiMasks{iMask};
    [~, maskName, maskExt] = fileparts(originalMask);
    
    % Reslice and binarize this individual mask
    resliceAndBinarizeSingleMask(originalMask, maskName, maskExt, refDim, refImage, ...
                                 maskOutputDir, tempDir, opt);
end

%% Clean up temp directory
if exist(tempDir, 'dir')
    rmdir(tempDir, 's');
end

fprintf('  ✓ Subject complete. Output: %s\n', maskOutputDir);

end
