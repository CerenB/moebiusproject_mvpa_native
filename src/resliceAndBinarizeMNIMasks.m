function resliceAndBinarizeMNIMasks(opt, interp)
% Reslice and binarize MNI-space Glasser masks per subject
% 
% INPUTS:
%   opt    - options structure from batchMvpa (must contain opt.subjects, opt.taskName)
%   interp - interpolation method used in warp step: 'nearest', 'linear', or 'bspline'
%
% Workflow:
% - Loops through all subjects from opt.subjects
% - Reads each subject's warped native masks from volumetric_MNI2009cAsym/<interp>/<subject>/
% - Loads subject's reference 4D image to get canonical dimensions
% - Reslices masks to match reference dimensions (if needed)
% - Re-binarizes masks after reslicing (interpolation introduces values >0, <1)
% - Saves to volumetric_MNI2009cAsym/<interp>/<subject>/resliced/
%
% NOTE: bidspm must be initialized before calling this function

% Add helper functions
addpath(genpath(fullfile(fileparts(mfilename('fullpath')), 'subfun')));


%% Define base paths (not present in batchMvpa.m)
% opt.space should already be set in batchMvpa; if not, default to MNI
if ~isfield(opt, 'space')
    opt.space = {'MNI152NLin2009cAsym'};
end
spaceLabel = opt.space{1};

% Build mask directory with interpolation method subfolder
% Use opt.maskPath from batchMvpa as base (volumetric_MNI2009cAsym)
if ~isfield(opt, 'maskPath')
    error('opt.maskPath must be defined in calling script (batchMvpa.m)');
end
opt.maskBaseDir = fullfile(opt.maskPath, interp);

% Stats base dir (should already be in opt.dir.stats from batchMvpa)
if ~isfield(opt, 'dir') || ~isfield(opt.dir, 'stats')
    error('opt.dir.stats must be defined in calling script (batchMvpa.m)');
end
opt.statsBaseDir = opt.dir.stats;

fprintf('\n========================================\n');
fprintf('RESLICE & BINARIZE MNI MASKS\n');
fprintf('Task: %s | Space: %s | Interp: %s\n', opt.taskName{1}, spaceLabel, interp);
fprintf('Mask source: %s\n', opt.maskBaseDir);
fprintf('========================================\n');

%% Loop through subjects from opt
subjects = opt.subjects;
for iSub = 1:length(subjects)
    subID = subjects{iSub};
    subLabel = ['sub-' subID];
    
    % Determine session based on subject ID
    opt.session = getSessionForSubject(subLabel);
    
    fprintf('\n----------------------------------------\n');
    fprintf('Processing %s (%d/%d)\n', subLabel, iSub, length(subjects));
    fprintf('Session: %s\n', opt.session);
    fprintf('----------------------------------------\n');
    
    % Reslice and binarize this subject's masks
    resliceAndBinarizeSubjectMasks(subLabel, opt);
    
end

fprintf('\n========================================\n');
fprintf('✓ RESLICING COMPLETE!\n');
fprintf('========================================\n\n');

end
