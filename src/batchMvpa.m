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
  
  
  
  
  