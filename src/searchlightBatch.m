clear all;
clc;

  % add path, repos, ...
  addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

  % cosmo
  cosmo = '~/Documents/MATLAB/CoSMoMVPA';
  addpath(genpath(cosmo));
  cosmo_warning('once');

  % libsvm
  libsvm = '~/Documents/MATLAB/libsvm';
  addpath(genpath(libsvm));
  % verify it worked.
  cosmo_check_external('libsvm'); % should not give an error
  
  % spm fmri
  warning('off');
  addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

%   % add cpp repo
  run ../lib/bidspm/initCppSpm.m;
  
  % add mini-helper functions
  addpath(genpath(fullfile(pwd, 'subfun')));
  
  % get options
  opt = getOptionSearchlight();

  % perform the searchlight
  info = step1Searchlight(opt);
  
  % smoothing
  funcFWHM2Level = 8;
  maps = 't_maps';
  condition = 'BodyParts5';
  step2SmoothSLMaps(condition, maps, funcFWHM2Level);
  
  step3CreateSLResultsMaps(condition,maps, funcFWHM2Level);
  
  %%% WIP
  % need to adjust the file names to be read
  % need to adjust the chance level according to the condition
  step4CreateContrastMaps(maps, funcFWHM2Level)