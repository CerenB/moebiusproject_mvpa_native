clear all;
clc;

  % add path, repos, ...
  addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

  % get options
  opt = getOptionSearchlight();

  % perform the searchlight
  info = step1Searchlight(opt);