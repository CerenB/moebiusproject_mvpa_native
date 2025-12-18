function accu = calculateGroupDecodingPerCondition(opt, roiSource)
% Classify ctrl vs mbs group membership using per-condition 4D maps
%
% Main function to perform group-level MVPA decoding classifying subjects
% into ctrl or mbs groups based on their activation patterns for a specific
% body part condition (e.g., hand, feet, lips, tongue, forehead).
%
% Dependent on SPM + bidspm and CoSMoMVPA toolboxes
% Output is compatible with R visualization (CSV + MAT files)
%
% Approach:
%   - Load per-subject 4D maps (e.g., desc-hand4D_tmap.nii)
%   - Each 4D contains 12 volumes (one per run, averaged repetitions within run)
%   - Use Leave-One-Subject-Out (LOSO) cross-validation
%   - Classify ctrl (label=1) vs mbs (label=2)
%
% Usage (called from batchMvpa.m):
%   opt.groupMvpa.condition = 'hand';  % single condition: 'hand', 'feet', etc.
%   opt.groupMvpa.imageType = 'tmap';
%   accu = calculateGroupDecodingPerCondition(opt, 'glassier');
%
% Required opt fields:
%   opt.taskName              = {'somatotopy'}
%   opt.groupMvpa.condition   = 'hand'  % single condition name
%   opt.groupMvpa.imageType   = 'tmap' | 'beta'
%   opt.spaceFolder           = 'MNI152NLin2009cAsym'
%   opt.dir.stats             = path to bidspm-stats directory
%   opt.pathOutput            = output directory path
%
% Required roiSource:
%   roiSource                 = 'glassier' or 'glassierexclusive' or other ROI source

  if nargin < 2
    error('Two inputs required: calculateGroupDecodingPerCondition(opt, roiSource)');
  end
  
  if nargin < 1 || isempty(opt)
    error('opt structure required. Call this function from batchMvpa.m');
  end

  fprintf('\n========================================\n');
  fprintf('GROUP DECODING: Per-Condition (ctrl vs mbs)\n');
  fprintf('Task: %s | Condition: %s | Image: %s\n', ...
    opt.taskName{1}, opt.groupMvpa.condition, opt.groupMvpa.imageType);
  fprintf('========================================\n');

  %% Set output folder/name
  funcFWHM = opt.fwhm.func;
  if iscell(opt.taskName)
    taskNameStr = opt.taskName{1};
  else
    taskNameStr = opt.taskName;
  end
  ts = datestr(now, 'yyyymmddHHMM');
  condStr = strrep(opt.groupMvpa.condition, ' ', '');
  baseName = sprintf('%sGroupDecoding_%s_%s_%s_s%s_%s', ...
                     taskNameStr, condStr, opt.groupMvpa.imageType, ...
                     opt.spaceFolder, num2str(funcFWHM), ts);

  savefileMat = fullfile(opt.pathOutput, [baseName, '.mat']);
  savefileCsv = fullfile(opt.pathOutput, [baseName, '.csv']);

  % Set default roiSource if not provided
  if ~isfield(opt, 'roiSource')
    opt.roiSource = roiSource;
  end

  %% Get subject list and group labels
  [allSubjects, groupLabels] = loadSubjectList(opt);
  nSubjects = numel(allSubjects);

  fprintf('Total subjects: %d (ctrl=%d, mbs=%d)\n', ...
          nSubjects, sum(groupLabels==1), sum(groupLabels==2));

  %% Get mask
  [maskPath, opt] = getMaskPath(opt);

  %% Initialize results structure
  accu = struct( ...
    'subID', [], ...
    'groupLabel', [], ...
    'foldAccuracy', [], ...
    'predictions', [], ...
    'trueLabels', [], ...
    'condition', [], ...
    'maskHemi', [], ...
    'maskArea', [], ...
    'maskFull', [], ...
    'imageType', [], ...
    'space', [], ...
    'ffxSmooth', []);

  %% Load all subjects' data
  fprintf('\nLoading per-subject 4D images...\n');
  [datasets, validSubjects, validLabels] = loadGroupDatasets(opt, allSubjects, groupLabels, maskPath);
  nValid = numel(validSubjects);

  if nValid < 4
    error('Insufficient subjects for decoding (%d valid). Need at least 4.', nValid);
  end

  fprintf('\nValid subjects for decoding: %d (ctrl=%d, mbs=%d)\n', ...
          nValid, sum(validLabels==1), sum(validLabels==2));

  %% Stack datasets for group-level classification
  ds_group = stackGroupDatasets(datasets, validLabels);

  fprintf('\nDataset summary:\n');
  fprintf('  Total samples: %d\n', size(ds_group.samples, 1));
  fprintf('  Features: %d\n', size(ds_group.samples, 2));
  fprintf('  Chunks (subjects): %d\n', numel(unique(ds_group.sa.chunks)));

  %% Run LOSO cross-validation
  fprintf('\nRunning LOSO cross-validation...\n');
  [accuracy, foldAccuracy, predictions, trueLabels] = runLOSODecoding(ds_group, opt);

  fprintf('\n========================================\n');
  fprintf('DECODING ACCURACY: %.2f%%\n', accuracy * 100);
  fprintf('========================================\n');

  %% Display fold results
  for iFold = 1:numel(foldAccuracy)
    fprintf('  Fold %d (test subject %s): %.2f%%\n', ...
            iFold, validSubjects{iFold}, foldAccuracy(iFold) * 100);
  end

  %% Compute confusion matrix
  confMat = confusionmat(trueLabels, predictions);
  fprintf('\nConfusion Matrix:\n');
  fprintf('              Predicted ctrl  Predicted mbs\n');
  fprintf('Actual ctrl   %14d  %13d\n', confMat(1,1), confMat(1,2));
  fprintf('Actual mbs    %14d  %13d\n', confMat(2,1), confMat(2,2));

  %% Store results
  count = 1;
  for iFold = 1:nValid
    accu(count).subID = validSubjects{iFold};
    accu(count).groupLabel = validLabels(iFold);
    accu(count).foldAccuracy = foldAccuracy(iFold);
    accu(count).predictions = predictions(iFold);
    accu(count).trueLabels = trueLabels(iFold);
    accu(count).condition = opt.groupMvpa.condition;
    
    % Store mask information (first mask if multiple)
    if isfield(opt, 'maskLabel') && iscell(opt.maskLabel) && length(opt.maskLabel) > 0
      accu(count).maskHemi = opt.maskLabel{1}.hemi;
      accu(count).maskArea = opt.maskLabel{1}.area;
      accu(count).maskFull = opt.maskLabel{1}.full;
    else
      accu(count).maskHemi = '';
      accu(count).maskArea = '';
      accu(count).maskFull = '';
    end
    
    accu(count).imageType = opt.groupMvpa.imageType;
    accu(count).space = opt.spaceFolder;
    accu(count).ffxSmooth = funcFWHM;
    count = count + 1;
  end

  % Add overall accuracy to structure
  for i = 1:numel(accu)
    accu(i).overallAccuracy = accuracy;
    accu(i).confusionMatrix = confMat;
  end

  %% Save output
  save(savefileMat, 'accu');
  fprintf('\nSaved results: %s\n', savefileMat);

  % CSV with important info for plotting
  csvAccu = rmfield(accu, 'confusionMatrix');
  writetable(struct2table(csvAccu), savefileCsv);
  fprintf('Saved CSV: %s\n', savefileCsv);

  fprintf('\n========================================\n');
  fprintf('COMPLETED: Group decoding for %s\n', opt.groupMvpa.condition);
  fprintf('========================================\n');

end

%% SUBFUNCTIONS

function [allSubjects, groupLabels] = loadSubjectList(opt)
  % Load subject list and group labels from TSV file
  outputDir = fullfile(opt.dir.stats, '..', 'cosmoMvpa', 'group');
  tsvPattern = fullfile(outputDir, 'groupDecoding_*.tsv');
  tsvFiles = dir(tsvPattern);
  
  if isempty(tsvFiles)
    error('No groupDecoding TSV file found. Run assembleGroupDecodingInputs.m first.');
  end
  
  [~, idx] = max([tsvFiles.datenum]);
  tsvPath = fullfile(outputDir, tsvFiles(idx).name);
  fprintf('Loading subject list from: %s\n', tsvPath);
  
  tSubjects = readtable(tsvPath, 'FileType','text', 'Delimiter','\t');
  allSubjects = cellstr(tSubjects.subject);
  groupLabels = double(tSubjects.group); % 1=ctrl, 2=mbs
end

function [maskPath, opt] = getMaskPath(opt)
  % Get mask path using chooseMask helper
  fprintf('Getting mask from roiSource: %s\n', opt.roiSource);
  
  % Call chooseMask with proper signature: (opt, roiSource, subID)
  % For group-level, we don't need subID, so pass empty
  opt = chooseMask(opt, opt.roiSource, []);
  
  % Print out the mask names (like in calculatePairwiseMvpa.m)
  if isfield(opt, 'maskLabel') && iscell(opt.maskLabel)
    for iMask = 1:length(opt.maskLabel)
      fprintf('  Mask: %s\n', opt.maskLabel{iMask}.full);
    end
  end
  
  % Use the first mask for group-level decoding
  if isfield(opt, 'maskName') && iscell(opt.maskName) && ~isempty(opt.maskName{1})
    maskPath = opt.maskName{1};
  else
    maskPath = opt.maskPath;
  end
  
  if isempty(maskPath) || ~exist(maskPath, 'file')
    error('Mask not found: %s', maskPath);
  end
end

function [datasets, validSubjects, validLabels] = loadGroupDatasets(opt, allSubjects, groupLabels, maskPath)
  % Load 4D images for all subjects
  nSubjects = numel(allSubjects);
  datasets = cell(nSubjects, 1);
  validIdx = true(nSubjects, 1);
  
  condStr = strrep(opt.groupMvpa.condition, ' ', '');
  imgPattern = sprintf('sub-%%s_task-%s_space-%s_desc-%s4D_%s.nii', ...
                       opt.taskName{1}, opt.spaceFolder, condStr, opt.groupMvpa.imageType);
  
  for iSub = 1:nSubjects
    subID = allSubjects{iSub};
    subLabel = ['sub-' subID];
    ffxDir = fullfile(opt.dir.stats, subLabel, ...
              ['task-', opt.taskName{1}, '_space-', opt.spaceFolder, '_FWHM-2']);
    imgPath = fullfile(ffxDir, sprintf(imgPattern, subID));
    
    if ~exist(imgPath, 'file')
      warning('Missing 4D image for %s: %s', subLabel, imgPath);
      validIdx(iSub) = false;
      continue;
    end
    
    try
      ds = cosmo_fmri_dataset(imgPath, 'mask', maskPath);
      
      % Remove zero voxels
      zeroMask = all(ds.samples == 0, 1);
      ds = cosmo_slice(ds, ~zeroMask, 2);
      
      % Remove useless data
      ds = cosmo_remove_useless_data(ds);
      
      datasets{iSub} = ds;
      fprintf('  [%d/%d] Loaded %s: %d volumes, %d features\n', ...
              iSub, nSubjects, subLabel, size(ds.samples,1), size(ds.samples,2));
    catch ME
      warning('Failed to load %s: %s', subLabel, ME.message);
      validIdx(iSub) = false;
    end
  end
  
  datasets = datasets(validIdx);
  validSubjects = allSubjects(validIdx);
  validLabels = groupLabels(validIdx);
end

function ds_group = stackGroupDatasets(datasets, groupLabels)
  % Stack datasets: each subject contributes multiple samples (runs)
  % Target: replicate group label for each run of that subject
  % Chunks: subject ID (ensures all runs from same subject stay together)
  
  nValid = numel(datasets);
  allSamples = [];
  allTargets = [];
  allChunks = [];
  
  for iSub = 1:nValid
    ds = datasets{iSub};
    nRuns = size(ds.samples, 1);
    allSamples = [allSamples; ds.samples]; %#ok<AGROW>
    allTargets = [allTargets; repmat(groupLabels(iSub), nRuns, 1)]; %#ok<AGROW>
    allChunks = [allChunks; repmat(iSub, nRuns, 1)]; %#ok<AGROW>
  end
  
  % Create CoSMoMVPA dataset
  ds_group = struct();
  ds_group.samples = allSamples;
  ds_group.sa.targets = allTargets;
  ds_group.sa.chunks = allChunks;
  ds_group.fa = datasets{1}.fa;
  ds_group.a = datasets{1}.a;
end

function [accuracy, foldAccuracy, predictions, trueLabels] = runLOSODecoding(ds_group, opt)
  % Run Leave-One-Subject-Out cross-validation with optional feature selection
  
  % Set up classifier from opt.mvpa settings
  if isfield(opt, 'mvpa') && isfield(opt.mvpa, 'child_classifier')
    classifier = opt.mvpa.child_classifier;
    fprintf('  Using classifier: %s\n', func2str(classifier));
  else
    classifier = @cosmo_classify_lda; % Default fallback
    fprintf('  Using default classifier: LDA\n');
  end
  
  % Check for normalization option
  applyNormalization = false;
  if isfield(opt, 'mvpa') && isfield(opt.mvpa, 'normalization')
    if strcmp(opt.mvpa.normalization, 'zscore')
      applyNormalization = true;
      fprintf('  Applying z-score normalization\n');
    end
  end
  
  % Check for feature selection option
  ratioToKeep = [];
  if isfield(opt, 'mvpa') && isfield(opt.mvpa, 'ratioToKeep')
    ratioToKeep = opt.mvpa.ratioToKeep;
    fprintf('  Selecting top %d voxels via ANOVA\n', ratioToKeep);
  end
  
  % LOSO partitions
  partitions = cosmo_nchoosek_partitioner(ds_group, 1, 'chunks');
  
  nFolds = numel(unique(ds_group.sa.chunks));
  foldAccuracy = zeros(nFolds, 1);
  allPredictions = [];
  allTrueLabels = [];
  
  for iFold = 1:nFolds
    testIdx = ds_group.sa.chunks == iFold;
    trainIdx = ~testIdx;
    
    ds_train = cosmo_slice(ds_group, trainIdx);
    ds_test = cosmo_slice(ds_group, testIdx);
    
    % Apply normalization if specified
    if applyNormalization
      ds_train = cosmo_normalize(ds_train, 'zscore');
      ds_test = cosmo_normalize(ds_test, 'zscore');
    end
    
    % Apply feature selection on training data if specified
    if ~isempty(ratioToKeep)
      ds_train_selected = cosmo_anova_feature_selector(ds_train, ratioToKeep);
      
      % Get selected feature indices
      selectedFeat = ds_train_selected.fa.samples > 0;
      
      % Apply same selection to test data
      ds_test = cosmo_slice(ds_test, selectedFeat, 2);
    end
    
    % Train and predict
    pred = classifier(ds_train.samples, ds_train.sa.targets, ds_test.samples);
    
    allPredictions = [allPredictions; pred]; %#ok<AGROW>
    allTrueLabels = [allTrueLabels; ds_test.sa.targets]; %#ok<AGROW>
    
    foldAcc = mean(pred == ds_test.sa.targets);
    foldAccuracy(iFold) = foldAcc;
  end
  
  % Overall accuracy
  accuracy = mean(allPredictions == allTrueLabels);
  
  % Get one prediction per subject (majority vote per subject)
  nFolds = numel(foldAccuracy);
  predictions = zeros(nFolds, 1);
  trueLabels = zeros(nFolds, 1);
  
  for iFold = 1:nFolds
    testIdx = ds_group.sa.chunks == iFold;
    foldPreds = allPredictions(testIdx);
    foldTrue = allTrueLabels(testIdx);
    
    % Majority vote (or just take first since all should be same)
    predictions(iFold) = mode(foldPreds);
    trueLabels(iFold) = foldTrue(1);
  end
end
