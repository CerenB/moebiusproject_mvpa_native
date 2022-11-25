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
    opt.subjects = {'ctrl001'}; % 
    
    
    % Uncomment the lines below to run preprocessing
    % - don't use realign and unwarp
    opt.realign.useUnwarp = true;

    % we stay in native space (that of the T1)
    % - in "native" space: don't do normalization
    opt.space = 'MNI'; % 'individual', 'MNI'

    % The directory where the data are located
    opt.dataDir = fullfile(fileparts(mfilename('fullpath')), ...
                           '..', '..', '..',  'raw');
    opt.derivativesDir = fullfile(opt.dataDir, '..', 'derivatives', ...
                                  'cpp_spm');

    % task to analyze
%     opt.taskName = 'mototopy';
    opt.taskName = 'somatotopy';

 
    % Suffix output directory for the saved jobs
    opt.jobsDir = fullfile( ...
                           opt.dataDir, '..', 'derivatives', ...
                           'cpp_spm', 'JOBS', opt.taskName);
                       
    opt.model.file = fullfile(fileparts(mfilename('fullpath')), '..', ...
                              'model', ...
                              ['model-', opt.taskName, '_audCueParts_smdl.json']); 


    opt.pathOutput = fullfile(opt.dataDir, '..', 'derivatives', 'cosmoMvpa');    
    

    opt.roiPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
                                '..', '..', '..', 'derivatives', 'roi', ...
                                'atlases', 'spmAnatomy');
  %% DO NOT TOUCH
  opt = checkOptions(opt);
  saveOptions(opt);
  
  % we cannot save opt with opt.mvpa, it crashes

  %% mvpa options
  % define the 4D maps to be used
  opt.funcFWHM = 2;

  % take the most responsive xx nb of voxels
  opt.mvpa.ratioToKeep = 150; % 100 150 250 300(364 min for combo)

  % set which type of ffx results you want to use
  opt.mvpa.map4D = {'beta', 't_maps'};

  % design info
  opt.mvpa.nbRun = 6; %6 for somato, 3 for mototopy fir pilots
  if strcmp(opt.taskName, 'somatotopy')
     opt.mvpa.nbRun = 11; 
  end

  opt.mvpa.nbTrialRepetition = 1;

  % cosmo options
  opt.mvpa.tool = 'cosmo';
  opt.mvpa.normalization = 'zscore';
  opt.mvpa.child_classifier = @cosmo_classify_libsvm;
  opt.mvpa.feature_selector = @cosmo_anova_feature_selector;

  % permute the accuracies ?
  opt.mvpa.permutate = 1;

end
