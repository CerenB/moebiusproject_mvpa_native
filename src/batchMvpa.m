clear ;
clc;

%% set paths
  % spm
  warning('off');
  addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
  % cosmo
  cosmo = '~/Documents/MATLAB/CoSMoMVPA';
  addpath(genpath(cosmo));
  cosmo_warning('once');

  % libsvm
  libsvm = '~/Documents/MATLAB/libsvm';
  addpath(genpath(libsvm));
  % verify it worked.
  cosmo_check_external('libsvm'); % should not give an error
  
  % add cpp repo
  run ../lib/bidspm/initCppSpm.m;
  
  % add mini-helper functions
  addpath(genpath(fullfile(pwd, 'subfun')));
  
  % load your options
  opt = getOptionMoebiusMvpa();

  %% run mvpa 
  roiSource = 'spmAnat'; 
  accuracy = calculateMvpa(opt, roiSource);
  
  %% run pairwise MVPA
  roiSource = 'spmAnat'; 
  opt.mvpa.pairs = 1;
  accuracy = calculatePairwiseMvpa(opt, roiSource);

  %% extract DSMs
  % example call: extract_DSM(opt,roiSource, action)
  extract_DSM(opt,roiSource)
  
  %% plot DSMs
  roi = 'somato3';
  image = 'beta';
  condition = 'BodyParts5';
  plotMDS(opt, roi, image)
  
  %% extract and plot pairwise DSMs
  image = 'beta'; %'t_maps'
  roiSource = 'spmAnat';
  extractAndPlotPairwiseDA(opt,roiSource, image);
  
  %% run decoding in hcpex atlas roi
  roiSource = 'hcpex'; 
  accuracy = calculateMvpa(opt, roiSource);
  
  
  
  
  
  
  
  
  
  