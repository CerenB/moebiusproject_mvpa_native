clear;
clc;

addpath(fullfile(fileparts(mfilename('fullpath')), '..'));

% spm fmri
warning('off');
addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));

% then add cpp repo to prevent repo version compatibility issue
run ../lib/bidspm/initCppSpm.m;

% lastly, we add all the subfunctions that are in the sub directories
opt = getOptionMoebiusMvpa();


%% MVPA - prep
% with smoothing 0mm
funcFWHM = 0;
bidsSmoothing(funcFWHM, opt);

% subject level univariate
bidsFFX('specifyAndEstimate', opt, funcFWHM);
bidsFFX('contrasts', opt, funcFWHM);

bidsConcatBetaTmaps(opt, funcFWHM, 0, 0);


% with smoothing 2mm
% % prep for mvpa
funcFWHM = 2;
bidsSmoothing(funcFWHM, opt);

bidsFFX('specifyAndEstimate', opt, funcFWHM);
bidsFFX('contrasts', opt, funcFWHM);

bidsConcatBetaTmaps(opt, funcFWHM, 0, 0);

