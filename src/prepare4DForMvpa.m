clear;
clc;

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% spm fmri
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

this_dir = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                      'moebius_topo_analyses/code/src/mvpa');
  addpath(fullfile(this_dir, '..', '..', 'lib', 'bidspm'), '-begin');

% add mini-helper functions
addpath(genpath(fullfile(pwd, 'subfun')));


% not sure if we need getOptionMoebiusMvpa here
% opt = getOptionMoebiusMvpa();
opt.taskName = {'somatotopy'}; % 'mototopy' somatotopy

%% Set options
opt.threshold = 0.0;  % Binary threshold: >0 becomes 1, <=0 becomes 0
opt.unzip.do = true;
opt.save.roi = true;
opt.outputDir = []; % if empty, saves in current directory
if opt.save.roi
  opt.reslice.do = true;
else
  opt.reslice.do = false;
end

%% Define participants
subjects = {'ctrl004', 'ctrl005', 'ctrl007', ...
            'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', 'ctrl012', ...
            'ctrl013', 'ctrl014', 'ctrl015', 'ctrl016', 'ctrl017', ...
            'mbs001', 'mbs002', 'mbs003', 'mbs004', 'mbs005', ...
            'mbs006', 'mbs007'};
subjects = {'ctrl001'}; % --- IGNORE ---

%% Define base paths
statsBaseDir = fullfile('/Volumes/extreme/Cerens_files/fMRI/', ...
                        'moebius_topo_analyses/outputs/derivatives/', ...
                        'bidspm-stats');

roiBasePath = fullfile('/Volumes/extreme/Cerens_files/fMRI/', ...
                       'GlasserAtlas/Glasser_ROIs_sensorimotor/', ...
                       'volumetric_ROIs');

%% Loop through subjects
for iSub = 1:length(subjects)
    subID = subjects{iSub};
    subLabel = ['sub-' subID];
    
    fprintf('\n========================================\n');
    fprintf('Processing %s (%d/%d)\n', subLabel, iSub, length(subjects));
    fprintf('========================================\n');
    
    % Define subject-specific paths
    ffxDir = fullfile(statsBaseDir, subLabel, ['task-', opt.taskName{1}, '_space-T1w_FWHM-2']);
    roiPath = fullfile(roiBasePath, subLabel);
    
    % Check if subject directories exist
    if ~exist(ffxDir, 'dir')
        warning('Stats directory not found for %s, skipping: %s', subLabel, ffxDir);
        continue;
    end
    
    if ~exist(roiPath, 'dir')
        warning('ROI directory not found for %s, skipping: %s', subLabel, roiPath);
        continue;
    end
    
    % 4D image (reference for reslicing)
    imageName = sprintf('%s_task-%s_space-T1w_desc-4D_tmap.nii', subLabel, opt.taskName{1});
    dataImage = fullfile(ffxDir, imageName);
    
    if ~exist(dataImage, 'file')
        warning('4D tmap not found for %s, skipping: %s', subLabel, dataImage);
        continue;
    end
    
    % Get functional data dimensions for verification
    maskImage = fullfile(ffxDir, 'mask.nii');
    if ~exist(maskImage, 'file')
        warning('Functional mask not found for %s, skipping', subLabel);
        continue;
    end
    [voxelNbMask, dim] = voxelCountAndDimensions(maskImage);
    fprintf('Functional data dimensions: [%d %d %d]\n', dimData);
    fprintf('Functional data dimensions: %d\n', voxelNbMask);
    
    %% Step 1: Find all NON-binary masks and binarize them
    fprintf('\n--- Step 1: Binarizing original masks ---\n');
    allMasks = spm_select('FPList', roiPath, '^(?!.*binary).*\.nii?$');
%     allMasks = spm_select('FPList', roiPath, '^(?!.*binary).*\.nii(\.gz)?$');
    
    if isempty(allMasks)
        warning('No masks found for %s in: %s', subLabel, roiPath);
        continue;
    end
    
    allMasks = cellstr(allMasks);
    fprintf('Found %d original mask(s) to binarize\n', length(allMasks));
    
    % Binarize each original mask
    for iMask = 1:length(allMasks)
        originalMask = allMasks{iMask};
        [maskDir, maskName, maskExt] = fileparts(originalMask);
        
        % Handle .nii.gz extension
        if strcmp(maskExt, '.gz')
            [~, maskName, ~] = fileparts(maskName);
        end
        
        fprintf('  Binarizing %d/%d: %s\n', iMask, length(allMasks), maskName);
        
        try
            % Create binary version with _binary suffix
            binaryName = [maskName, '_binary.nii'];
            optBinarize = opt;
            optBinarize.outputDir = maskDir;
            [voxelNb] = binarizeImage(originalMask, binaryName, optBinarize);
            fprintf('    ✓ Created %s with %d voxels\n', binaryName, voxelNb);
        catch ME
            warning('    Failed to binarize %s: %s', maskName, ME.message);
            continue;
        end
    end
    
    %% Step 2: Find all binary masks and reslice them
    fprintf('\n--- Step 2: Reslicing and re-binarizing binary masks ---\n');
    binaryMasks = spm_select('FPList', roiPath, '.*binary.*\.nii$');
    
    if isempty(binaryMasks)
        warning('No binary masks found for %s in: %s', subLabel, roiPath);
        continue;
    end
    
    binaryMasks = cellstr(binaryMasks);
    fprintf('Found %d binary mask(s) to process\n', length(binaryMasks));
    
    % Loop through each binary mask
    for iMask = 1:length(binaryMasks)
        binaryMap = binaryMasks{iMask};
        [~, maskName, maskExt] = fileparts(binaryMap);
        
        fprintf('\n  Processing mask %d/%d: %s\n', iMask, length(binaryMasks), [maskName, maskExt]);
        
        try
            % Check dimensions before reslicing
            [voxelNbRaw, dimRaw] = voxelCountAndDimensions(binaryMap);
            fprintf('    Original ROI dimensions: [%d %d %d], voxels: %d\n', dimRaw, voxelNbRaw);
            
            % Reslice the mask to match functional data dimensions
            fprintf('    Reslicing ROI to match functional data...\n');
            reslicedRoi = prepareRoi(opt, binaryMap, dataImage);
            
            % Re-binarize to ensure only 0s and 1s (reslicing can introduce interpolated values)
            opt.threshold = 0.2; % use higher threshold for resliced data
            fprintf('    Re-binarizing resliced ROI...\n');
            binarizeImage(reslicedRoi, reslicedRoi, opt);
            
            finalRoi = reslicedRoi;
            [voxelNb, dimRoi] = voxelCountAndDimensions(finalRoi);
            fprintf('    Final ROI dimensions: [%d %d %d], voxels: %d\n', dimRoi, voxelNb);
            
            % Verify dimensions match
            if ~isequal(dimRoi, dimData)
                warning(['    ROI and functional data dimensions do not match!\n' ...
                         '    ROI: [%d %d %d], Data: [%d %d %d]'], dimRoi, dimData);
            else
                fprintf('    ✓ Dimensions match! Ready for MVPA.\n');
            end
            
        catch ME
            warning('    Failed to process mask %s: %s', [maskName, maskExt], ME.message);
            continue;
        end
    end
end

fprintf('\n========================================\n');
fprintf('All subjects processed!\n');
fprintf('========================================\n');


