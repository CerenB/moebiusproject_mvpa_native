clear ;
clc;

%% set paths

  this_dir = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                      'moebius_topo_analyses/code/src/mvpa');
  addpath(fullfile(this_dir, '..', '..', 'lib', 'bidspm'), '-begin');

  % spm
  warning('off');
  addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
  % cosmo
  cosmo = '~/Documents/MATLAB/CoSMoMVPA';
  addpath(genpath(cosmo));
  cosmo_warning('once');

  % add mini-helper functions
  addpath(genpath(fullfile(pwd, 'subfun')));

  % libsvm
  addpath('~/Documents/MATLAB/libsvm/matlab');
  
  % add cpp repo
  bidspm();
  
  
  %% data 
  yoda_dir = fullfile(this_dir, '..', '..', '..');
  bids_dir = fullfile(yoda_dir, 'inputs', 'raw');

  % 4D files
  opt.dir.stats = fullfile(yoda_dir, 'outputs', 'derivatives', 'bidspm-stats');
  
  
  % output 
  opt.pathOutput = fullfile(opt.dir.stats,'..', 'cosmoMvpa', 'roi'); 
  
  % mask
  opt.maskPath = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                           'GlasserAtlas/Glasser_ROIs_sensorimotor/', ...
                           'volumetric_ROIs');
  

  % load your options
  opt.taskName = {'somatotopy'}; % mototopy somatotopy
  opt.space = {'MNI152NLin2009cAsym'};
  verbosity = 3;
  opt.bidsFilterFile.bold = struct('modality', 'func', 'suffix', 'bold');
  opt.fwhm.func = 2;
  opt.model.file = fullfile(this_dir, '..', 'bidspm-stats', 'models', ...
                            ['model-',opt.taskName{1}, ...
                            '_bidspm_mvpa_smdl.json']);
  opt.model.bm = BidsModel('file', opt.model.file);

  % no data collected: '06' 
  %  sub-ctrl014 only mototopy exp
  opt.subjects = {'ctrl001', 'ctrl002','ctrl003','ctrl004', 'ctrl005', ...
                  'ctrl007', 'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', ...
                  'ctrl012', 'ctrl013', 'ctrl015', 'ctrl016', ...
                  'ctrl017', 'mbs001', 'mbs002' , 'mbs003', 'mbs004', ...
                  'mbs005', 'mbs006', 'mbs007'}; 
  %opt.subjects = {'ctrl014'};            


% 'mbs001', 'mbs002' , 'mbs003', 'mbs004', 'mbs005', ...
% 'mbs006', 'mbs007', ...
% 'ctrl001', 'ctrl002','ctrl003','ctrl004', 'ctrl005', 'ctrl007', ...
% 'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', 'ctrl012', ...
% 'ctrl013','ctrl014', 'ctrl015', 'ctrl016','ctrl017'

% prep of 4D maps, and s2 smoothing happened in run_fmriprep_stats_somamototopy.m
% make sure those steps are done before running this script
  
  %% mvpa options
  % take the most responsive xx nb of voxels
  opt.mvpa.ratioToKeep = 150; % 100 150 250 300(364 min for combo)

  % set which type of ffx results you want to use
  opt.mvpa.map4D = {'tmap'}; % 'beta', 

  % design info
  opt.mvpa.nbRun = 6; %6 for somato, 3 for mototopy fir pilots
  if strcmp(opt.taskName{1}, 'somatotopy')
     opt.mvpa.nbRun = 12; 
  end

  opt.mvpa.nbTrialRepetition = 1;

  % cosmo options
  opt.mvpa.tool = 'cosmo';
  opt.mvpa.normalization = 'zscore';
  opt.mvpa.child_classifier = @cosmo_classify_libsvm;
  opt.mvpa.feature_selector = @cosmo_anova_feature_selector;

  % permute the accuracies
  opt.mvpa.permutate = 1;
  
  % do pairwise decoding
  opt.mvpa.pairs = 1;
  
  % multiple options exist for decoding conditions
  % 1: someselected binary decoding + multiclass decodings
  % 2: multiclass decoding allBodyParts and omitTongue 
  % 3: 6bodyparts and Forehead vs Forehead2 (for pilots)
  % 4: pairwise decoding
  opt.decodingType = [4]; %2

   % want to still run mvpa although the mask is smaller than desired
  % vx number? 
  opt.mvpa.useMaskVoxelNumber = 1;
  
  % needed for getffxdir function
  opt = checkOptions(opt); 
  
  %% run pairwise MVPA
  roiSource = 'glassier'; 
  opt.mvpa.pairs = 1;
  accuracy = calculatePairwiseMvpa(opt, roiSource);
  
  
  %% Optional: Create exclusive masks (remove overlapping voxels)
%   % Batch process all subjects to create exclusive masks:
%   
%   % Define which mask pairs to check for overlap
%   % Each pair removes overlapping voxels between area3a_3b and area4
%   maskPairs = {{'L_area3a_3b_binary.nii', 'L_area4_binary.nii'}, ...
%                {'R_area3a_3b_binary.nii', 'R_area4_binary.nii'}};
%   
%   % Run batch processing for all subjects
%   createExclusiveMasks(opt, maskPairs);
%   
%   % Alternative: area3a_3b_2_1 vs area4
%   maskPairs = {{'L_area3a_3b_2_1_binary.nii', 'L_area4_binary.nii'}, ...
%                {'R_area3a_3b_2_1_binary.nii', 'R_area4_binary.nii'}};
%   createExclusiveMasks(opt, maskPairs);
  
  
  % run pairwise MVPa with exclusive masks
  % note from 7/11/2025 - rerun somatotopy with glassierexclusive masks
  roiSource = 'glassierexclusive'; 
  opt.mvpa.pairs = 1; 
  accuracy = calculatePairwiseMvpa(opt, roiSource);
  
  
  
% prep for the group decoding
% 1. MASKS (input 1)
% first create the masks with bash script in the repo surface_geo_analysis
% they will be in MNI space
% then reslice them
interp = 'bspline';  % 'nearest', 'linear', or 'bspline' (must match warp step)
resliceAndBinarizeMNIMasks(opt, interp);

% 2. 4D MAPS (input 2)
% prepare the conditions/4D maps for group decoding
% Required opt fields (with defaults if missing):
  opt.taskName              = {'mototopy'};
  opt.groupMvpa.strategy    = 'average'; % | 'specific' | 'concatenate'
  opt.groupMvpa.imageType   = 'tmap'; % | 'beta'   % uses desc-4D_<imageType>.nii
  opt.groupMvpa.conditions  = {'hand'};        % pattern match (case-insensitive) for 'specific'
  opt.groupMvpa.sampleGranularity = 'per-run'; % | 'per-condition-avg'
  opt.groupMvpa.writeNifti  = true;       % write per-subject NIfTIs
  opt.spaceFolder           = 'MNI152NLin2009cAsym'; %| 'T1w' (folder name)
assembleGroupDecodingInputs(opt)


 % 3. perform group decoding
  opt.spaceFolder = 'MNI152NLin2009cAsym';
  opt.groupMvpa.condition = 'hand';
  opt.groupMvpa.imageType = 'tmap';
  roiSource = 'glassier';
  calculateGroupDecodingPerCondition(opt, roiSource);
  
  % note 18/12/2025 th masks are done in mototopy - and no task related
  % folders are created in the mask folder. technically MNI based masks
  % should be ok but something to consider.