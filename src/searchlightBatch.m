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
  
%   % add cpp repo
%   run ../lib/bidspm/initCppSpm.m;
  
  % add mini-helper functions
  addpath(genpath(fullfile(pwd, 'subfun')));
  
  % get options
  opt = getOptionSearchlight();

  % perform the searchlight
  info = step1Searchlight(opt);