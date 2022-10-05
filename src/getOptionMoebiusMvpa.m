% (C) Copyright 2019 CPP BIDS SPM-pipeline developpers

function opt = getOptionMoebiusMvpa()
    % opt = getOption()
    % returns a structure that contains the options chosen by the user to run
    % slice timing correction, pre-processing, FFX, RFX.

    if nargin < 1
        opt = [];
    end

    % group of subjects to analyze
    opt.groups = {''};
    % suject to run in each group
    opt.subjects = {'pil010', 'pil011'}; 
    
    
    % Uncomment the lines below to run preprocessing
    % - don't use realign and unwarp
    opt.realign.useUnwarp = true;

    % we stay in native space (that of the T1)
    % - in "native" space: don't do normalization
    opt.space = 'MNI'; % 'individual', 'MNI'

    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'raw');
    opt.derivativesDir = fullfile(opt.dataDir, '..');

    % task to analyze
%     opt.taskName = 'mototopy';
    opt.taskName = 'somatotopy';

 
    % Suffix output directory for the saved jobs
    opt.jobsDir = fullfile( ...
                           opt.dataDir, '..', 'derivatives', ...
                           'cpp_spm', 'JOBS', opt.taskName);
                       
    opt.model.file = fullfile(fileparts(mfilename('fullpath')), '..', ...
                              'model', 'model-somatotopy_audCueParts_smdl.json'); 
%     opt.model.file = fullfile(fileparts(mfilename('fullpath')), '..', ...
%                               'model', 'model-somatotopy_noCue_smdl.json');
%     opt.model.file = fullfile(fileparts(mfilename('fullpath')), '..', ...
%                               'model', 'model-mototopy_audCueParts_smdl.json');
                          
  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);
  % we cannot save opt with opt.mvpa, it crashes

  %% mvpa options

  % define the 4D maps to be used
  opt.funcFWHM = 2;

  % take the most responsive xx nb of voxels
  opt.mvpa.ratioToKeep = 300; % 100 150 250 350 420

  % set which type of ffx results you want to use
  opt.mvpa.map4D = {'beta', 't_maps'};

  % design info
  opt.mvpa.nbRun = 9;
  opt.mvpa.nbTrialRepetition = 1;

  % cosmo options
  opt.mvpa.tool = 'cosmo';
  % opt.mvpa.normalization = 'zscore';
  opt.mvpa.child_classifier = @cosmo_classify_libsvm;
  opt.mvpa.feature_selector = @cosmo_anova_feature_selector;

  % permute the accuracies ?
  opt.mvpa.permutate = 1;

%     %% DO NOT TOUCH
%     opt = checkOptions(opt);
%     saveOptions(opt);

end
