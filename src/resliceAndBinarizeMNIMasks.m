% Reslice and binarize MNI-space Glasser masks per subject
% 
% Workflow:
% - Loops through all subjects defined in 'subjects' list
% - Reads each subject's warped native masks from volumetric_MNI2009cAsym/<subject>/
% - Loads subject's reference 4D image to get canonical dimensions
% - Reslices masks to match reference dimensions (if needed)
% - Re-binarizes masks after reslicing (interpolation introduces values >0, <1)
% - Saves to volumetric_MNI2009cAsym/<subject>/resliced/
%
% This script reslices all masks to match the subject's task-specific 4D functional space
% Check if reslicing + re-binarization is necessary before committing to this step

clear;
clc;

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% SPM setup
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

this_dir = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                      'moebius_topo_analyses/code/src/mvpa');
addpath(fullfile(this_dir, '..', '..', 'lib', 'bidspm'), '-begin');

bidspm();

% Add helper functions
addpath(genpath(fullfile(pwd, 'subfun')));

%% Set options
opt.threshold = 0.0;  % Initial binary threshold for original masks
opt.reslice.do = true;
opt.save.roi = true;
opt.taskName = 'mototopy';  % or 'somatotopy'

%% Define participants
subjects = {'ctrl001', 'ctrl002', 'ctrl003', 'ctrl004', 'ctrl005', ...
            'ctrl007', 'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', ...
            'ctrl012', 'ctrl013', 'ctrl014', 'ctrl015', 'ctrl016', ...
            'ctrl017', 'mbs001', 'mbs002', 'mbs003', 'mbs004', ...
            'mbs005', 'mbs006', 'mbs007'};

% Uncomment to test on a subset:
subjects = {'ctrl001'};

%% Define base paths and add to opt
opt.mainDir = '/Volumes/extreme/Cerens_files/fMRI';
opt.space = 'MNI152NLin2009cAsym';

opt.statsBaseDir = fullfile(opt.mainDir, ...
                            '/moebius_topo_analyses/outputs/derivatives/', ...
                            'bidspm-stats');

opt.maskBaseDir = fullfile(opt.mainDir, ...
                           '/GlasserAtlas/Glasser_ROIs_sensorimotor/volumetric_MNI2009cAsym');

fprintf('\n========================================\n');
fprintf('RESLICE & BINARIZE MNI MASKS - BATCH\n');
fprintf('Task: %s | Space: %s\n', opt.taskName, opt.space);
fprintf('========================================\n');

%% Loop through subjects
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
fprintf('✓ BATCH RESLICING COMPLETE!\n');
fprintf('========================================\n\n');
