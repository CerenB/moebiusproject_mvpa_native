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
%     opt.subjects = {'ctrl014'}; % only in mototopy

    opt.subjects = {'mbs001', 'mbs002', 'mbs003', 'mbs004', 'mbs005', ...
                    'mbs006', 'mbs007', ...
                    'ctrl001','ctrl002','ctrl003','ctrl004', 'ctrl005', ...
                    'ctrl007', 'ctrl008', 'ctrl009', 'ctrl010', 'ctrl011',...
                    'ctrl012','ctrl013', 'ctrl015', 'ctrl016', ...
                    'ctrl017'}; % 'ctrl014',
                
    % Uncomment the lines below to run preprocessing
    % - don't use realign and unwarp
    opt.realign.useUnwarp = true;

    % we stay in native space (that of the T1)
    % - in "native" space: don't do normalization
    opt.space = 'individual'; % 'individual', 'MNI'

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
    

    
    
    opt.roi.atlas = 'hcpex';
    opt.roi.space = {'MNI'};
    opt.roi.name = {'1', '2', '3a', '3b', '4','6a', '6d', '6v', 'FEF', 'PEF'};

    %define folders for ROI    
    opt.dir.stats = fullfile(opt.dataDir, '..', 'derivatives', 'cpp_spm-stats');
    
    opt.dir.roi = [opt.derivativesDir '-roi'];
    spm_mkdir(fullfile(opt.dir.roi, 'group'));

    opt.jobsDir = fullfile(opt.dir.roi, 'JOBS', opt.taskName);
    
    
    
%     opt.roiPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
%                                 '..', '..', '..', 'derivatives', 'roi', ...
%                                 'atlases', 'spmAnatomy');
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
  opt.mvpa.map4D = {'t_maps'}; % 'beta', 

  % design info
  opt.mvpa.nbRun = 6; %6 for somato, 3 for mototopy fir pilots
  if strcmp(opt.taskName, 'somatotopy')
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
end
