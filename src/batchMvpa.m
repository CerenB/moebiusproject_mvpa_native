clear ;
clc;

%% set paths

  this_dir = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                      'moebius_topo_analyses/code/src/moebiusproject_mvpa');
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
  setup_libsvm();
  
  % add cpp repo
  bidspm();
  
  
  %% data 
  yoda_dir = fullfile(this_dir, '..', '..', '..');
  bids_dir = fullfile(yoda_dir, 'inputs', 'raw');

  % 4D files
  output_dir = fullfile(yoda_dir, 'outputs', 'derivatives', 'bidspm-stats');

  model_file = fullfile(this_dir, 'models', 'model-mototopy_bidspm_audCueParts_smdl.json');
  
  % output 
  opt.pathOutput = fullfile(output_dir,'cosmoMvpa', 'roi'); 
  
  % mask
  opt.maskFiles = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
                           'GlasserAtlas/Glasser_ROIs_sensorimotor/', ...
                           'volumetric_ROIs');
  

  % load your options
  task = {'mototopy'}; % 'mototopy' somatotopy

  space = {'T1w'};

  verbosity = 3;

  % no data collected: '06' 
  %  sub-ctrl014 only mototopy exp
  subject_label = {'ctrl001'}; 

% 'mbs001', 'mbs002' , 'mbs003', 'mbs004', 'mbs005', ...
% 'mbs006', 'mbs007', ...
% 'ctrl001', 'ctrl002','ctrl003','ctrl004', 'ctrl005', 'ctrl007', ...
% 'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011', 'ctrl012', ...
% 'ctrl013','ctrl014', 'ctrl015', 'ctrl016','ctrl017'

% prep of 4D maps, and s2 smoothing happened in run_fmriprep_stats_somamototopy.m
% make sure those steps are done before running this script
  
  %% mvpa options
  % define the 4D maps to be used
  opt.funcFWHM = 2;

  % take the most responsive xx nb of voxels
  opt.mvpa.ratioToKeep = 150; % 100 150 250 300(364 min for combo)

  % set which type of ffx results you want to use
  opt.mvpa.map4D = {'t_maps'}; % 'beta', 

  % design info
  opt.mvpa.nbRun = 6; %6 for somato, 3 for mototopy fir pilots
  if strcmp(task, 'somatotopy')
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
  opt.decodingType = [2,4]; %2

   % want to still run mvpa although the mask is smaller than desired
  % vx number? 
  opt.mvpa.useMaskVoxelNumber = 1;

%   %% run mvpa 
%   roiSource = 'spmAnat'; 
%   accuracy = calculateMvpa(opt, roiSource);
%   
%   %% run pairwise MVPA
%   roiSource = 'spmAnat'; 
%   opt.mvpa.pairs = 1;
%   accuracy = calculatePairwiseMvpa(opt, roiSource);
% 
%   %% extract DSMs
%   % example call: extract_DSM(opt,roiSource, action)
%   extract_DSM(opt,roiSource)
%   
%   %% plot DSMs
%   roi = 'somato3';
%   image = 'beta';
%   condition = 'BodyParts5';
%   plotMDS(opt, roi, image)
%   
%   %% extract and plot pairwise DSMs
%   image = 'beta'; %'t_maps'
%   roiSource = 'spmAnat';
%   extractAndPlotPairwiseDA(opt,roiSource, image);
%   
%   %% run decoding in hcpex atlas roi
%   roiSource = 'hcpex'; 
%   accuracy = calculateMvpa(opt, roiSource);
  
  %% run pairwise MVPA
  roiSource = 'glassier'; 
  opt.mvpa.pairs = 1;
  accuracy = calculatePairwiseMvpa(opt, roiSource);
  
  
  
  
  
  
  