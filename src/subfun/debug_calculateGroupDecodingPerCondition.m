function accu = debug_calculateGroupDecodingPerCondition(opt, roiSource)
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
%   opt.space           = 'MNI152NLin2009cAsym'
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
  maskBase = '';
  if isfield(opt,'maskPath') && ~isempty(opt.maskPath)
    maskBase = opt.maskPath;
  end
  fprintf('ROI source: %s | Mask base: %s\n', roiSource, maskBase);

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
                     opt.space{1}, num2str(funcFWHM), ts);

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

  %% Mask handling
  % For group decoding, masks may be subject-specific. We'll resolve per-subject
  % masks inside the dataset loading step rather than using a single mask here.

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
  [datasets, validSubjects, validLabels, maskPaths] = loadGroupDatasets(opt, allSubjects, groupLabels);
  nValid = numel(validSubjects);

  if nValid < 4
    error('Insufficient subjects for decoding (%d valid). Need at least 4.', nValid);
  end

  fprintf('\nValid subjects for decoding: %d (ctrl=%d, mbs=%d)\n', ...
          nValid, sum(validLabels==1), sum(validLabels==2));

  % Report original voxel counts BEFORE intersection
  fprintf('\nOriginal voxel counts per subject (before intersection):\n');
  for i = 1:min(5, nValid)
    fprintf('  Subject %d: %d voxels\n', i, size(datasets{i}.samples, 2));
  end
  if nValid > 5
    fprintf('  ... (%d more subjects)\n', nValid - 5);
    fprintf('  Subject %d: %d voxels\n', nValid, size(datasets{nValid}.samples, 2));
  end

  % Optional: derive common mask directly from NIfTI masks (count-based)
  maskOutputDir = fullfile(opt.pathOutput, 'commonVoxelMasks');
  maskSaveNameCount = sprintf('commonVoxels_fromMasks_%s.nii', condStr);
  try
    nCommonCount = computeCommonMaskFromNifti(maskPaths, maskOutputDir, maskSaveNameCount);
    fprintf('  Common voxels (mask count method): %d\n', nCommonCount);
  catch ME
    fprintf('Warning: Could not compute common mask from NIfTIs: %s\n', ME.message);
  end

  % Align all subjects to common voxels
  fprintf('\nAligning subjects to common voxel space...\n');
  datasetsAligned = alignAllSubjects(datasets);

  % Save common voxel mask for visualization (using aligned datasets - just for NIfTI output)
  maskSaveName = sprintf('commonVoxels_%s.nii', condStr);
  try
    templateMask = maskPaths{1}; % Use first subject's mask info as template
    fprintf('  Writing common voxel mask to NIfTI...\n');
    saveCommonVoxelMask(datasetsAligned, maskOutputDir, templateMask, maskSaveName);
  catch ME
    fprintf('Warning: Could not save common voxel mask: %s\n', ME.message);
  end

  % Stack all subjects into single dataset
  fprintf('\nStacking subjects into group dataset...\n');
  ds_group = stackAllSubjects(datasetsAligned, validLabels);

  fprintf('\nDataset summary:\n');
  fprintf('  Total samples: %d\n', size(ds_group.samples, 1));
  fprintf('  Common features: %d\n', size(ds_group.samples, 2));
  fprintf('  Subjects (chunks): %d\n', numel(unique(ds_group.sa.chunks)));

  % Run LOSO cross-validation
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

  % Compute confusion matrix
  confMat = confusionmat(trueLabels, predictions);
  fprintf('\nConfusion Matrix:\n');
  fprintf('              Predicted ctrl  Predicted mbs\n');
  fprintf('Actual ctrl   %14d  %13d\n', confMat(1,1), confMat(1,2));
  fprintf('Actual mbs    %14d  %13d\n', confMat(2,1), confMat(2,2));

  % Store results
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
    accu(count).space = opt.space{1};
    accu(count).ffxSmooth = funcFWHM;
    count = count + 1;
  end

  % Add overall accuracy to structure
  for i = 1:numel(accu)
    accu(i).overallAccuracy = accuracy;
    accu(i).confusionMatrix = confMat;
  end

  % Save output
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

function [datasets, validSubjects, validLabels, maskPaths] = loadGroupDatasets(opt, allSubjects, groupLabels)
  % Load 4D images for all subjects
  nSubjects = numel(allSubjects);
  datasets = cell(nSubjects, 1);
  validIdx = true(nSubjects, 1);
  maskPaths = cell(nSubjects, 1);
  
  condStr = strrep(opt.groupMvpa.condition, ' ', '');
  
  
  for iSub = 1:nSubjects
    subID = allSubjects{iSub};
    subLabel = ['sub-' subID];
    ffxDir = fullfile(opt.dir.stats, subLabel, ...
              ['task-', opt.taskName{1}, '_space-', opt.space{1}, ...
              '_FWHM-', num2str(opt.fwhm.func)]);
          
    imgPattern = sprintf('sub-%s_task-%s_space-%s_desc-%s4D_%s.nii', ...
                       subID, opt.taskName{1}, opt.space{1}, condStr, ...
                       opt.groupMvpa.imageType);      
    imgPath = fullfile(ffxDir, imgPattern);
    
    if ~exist(imgPath, 'file')
      warning('Missing 4D image for %s: %s', subLabel, imgPath);
      validIdx(iSub) = false;
      continue;
    end
    
    % Resolve subject-specific mask; require presence
    maskForSub = '';
    try
      optMask = chooseMask(opt, opt.roiSource, subID);
      if isfield(optMask, 'maskName') && ~isempty(optMask.maskName)
        maskForSub = optMask.maskName{1};
      end
    catch ME
      % keep maskForSub empty; handled below
    end
    if isempty(maskForSub) || exist(maskForSub,'file')~=2
      warning('Missing mask for %s; skipping subject. Expected under %s/%s/%s', ...
              subLabel, opt.maskPath, lower(opt.roiSource), subLabel);
      validIdx(iSub) = false;
      continue;
    end
    fprintf('  Using mask for %s: %s\n', subLabel, maskForSub);
    maskPaths{iSub} = maskForSub;

    try
      ds = cosmo_fmri_dataset(imgPath, 'mask', maskForSub);
      
      % Remove zero voxels
      zeroMask = all(ds.samples == 0, 1);
      ds = cosmo_slice(ds, ~zeroMask, 2);
      
      % Remove useless data
      ds = cosmo_remove_useless_data(ds);
      
            datasets{iSub} = ds;
            fprintf('  [%d/%d] Loaded %s: %d volumes, %d features\n', ...
              iSub, nSubjects, subLabel, size(ds.samples,1), size(ds.samples,2));
    catch ME
            warning('Failed to load %s with mask: %s', subLabel, ME.message);
      validIdx(iSub) = false;
    end
  end
  
  datasets = datasets(validIdx);
  validSubjects = allSubjects(validIdx);
  validLabels = groupLabels(validIdx);
  maskPaths = maskPaths(validIdx);
end

function [accuracy, foldAccuracy, predictions, trueLabels] = runLOSODecoding(ds_group, opt)
  % Run Leave-One-Subject-Out cross-validation using cosmo_crossvalidate

  % Set up MVPA options for feature selection + classification
  if ~isfield(opt, 'mvpa')
    opt.mvpa = struct();
  end
  
  % Feature selection ratio
  if isfield(opt.mvpa, 'ratioToKeep')
    opt.mvpa.feature_selection_ratio_to_keep = opt.mvpa.ratioToKeep;
    fprintf('  Feature selection: top %d voxels via ANOVA\n', opt.mvpa.ratioToKeep);
  end
  
  % Set classifier if not already set
  if ~isfield(opt.mvpa, 'child_classifier')
    opt.mvpa.child_classifier = @cosmo_classify_lda;
  end
  fprintf('  Using classifier: %s\n', func2str(opt.mvpa.child_classifier));
  
  % Normalization handled internally by cosmo_crossvalidate
  if isfield(opt.mvpa, 'normalization')
    fprintf('  Normalization: %s (applied per fold)\n', opt.mvpa.normalization);
  end

  % LOSO partitions: leave one chunk (subject) out per fold
  partitions = cosmo_nchoosek_partitioner(ds_group, 1);
  
  % Run cross-validation with feature selection
  % cosmo_crossvalidate handles normalization per fold internally
  [pred, accuracy] = cosmo_crossvalidate(ds_group, ...
                                         @cosmo_classify_meta_feature_selection, ...
                                         partitions, opt.mvpa);

  % Compute per-fold accuracy
  nFolds = numel(partitions.train_indices);
  foldAccuracy = zeros(nFolds, 1);
  for iFold = 1:nFolds
    testIdx = partitions.test_indices{iFold};
    foldAcc = mean(pred(testIdx) == ds_group.sa.targets(testIdx));
    foldAccuracy(iFold) = foldAcc;
  end

  % One prediction per subject (majority vote across runs)
  nSubs = numel(unique(ds_group.sa.chunks));
  predictions = zeros(nSubs, 1);
  trueLabels = zeros(nSubs, 1);
  
  for iSub = 1:nSubs
    subMask = ds_group.sa.chunks == iSub;
    subPreds = pred(subMask);
    subTrue = ds_group.sa.targets(subMask);
    predictions(iSub) = mode(subPreds);
    trueLabels(iSub) = subTrue(1);
  end
end

function datasetsAligned = alignAllSubjects(datasets)
  % Find voxels common to all subjects and slice each subject to those voxels
  nSubs = numel(datasets);
  
  % Get voxel IDs for each subject
  allIds = cell(nSubs, 1);
  for i = 1:nSubs
    allIds{i} = getVoxelIds(datasets{i});
  end
  
  % Find intersection across all subjects
  commonIds = allIds{1};
  for i = 2:nSubs
    commonIds = intersect(commonIds, allIds{i});
  end
  
  if isempty(commonIds)
    error('No overlapping voxels across all subjects. Check mask alignment.');
  end
  
  fprintf('  Common voxels across all subjects: %d\n', numel(commonIds));
  
  % Slice each subject to common voxels
  datasetsAligned = cell(nSubs, 1);
  for i = 1:nSubs
    datasetsAligned{i} = sliceToCommonVoxels(datasets{i}, commonIds);
  end
end

function ids = getVoxelIds(ds)
  % Extract unique voxel identifiers from dataset
  if isfield(ds.fa, 'i') && isfield(ds.fa, 'j') && isfield(ds.fa, 'k')
    ids = ds.fa.i * 1e8 + ds.fa.j * 1e4 + ds.fa.k;
  elseif isfield(ds.fa, 'voxel_indices')
    ids = ds.fa.voxel_indices(:);
  else
    ids = (1:size(ds.samples, 2))';
  end
end

function nCommon = computeCommonMaskFromNifti(maskPaths, outputDir, outName)
  % Stack binary masks as NIfTI, count overlaps, binarize voxels present in all subjects
  if isempty(maskPaths)
    error('No mask paths provided for count-based common mask.');
  end
  nSubs = numel(maskPaths);
  if exist(outputDir, 'dir')~=7
    mkdir(outputDir);
  end
  V1 = spm_vol(maskPaths{1});
  img = spm_read_vols(V1) ~= 0;
  acc = double(img);
  
  fprintf('  [DEBUG] Mask volume dimensions: %s\n', mat2str(size(img)));
  fprintf('  [DEBUG] Subject 1 voxel count: %d\n', nnz(img));
  
  for i = 2:nSubs
    Vi = spm_vol(maskPaths{i});
    imgi = spm_read_vols(Vi) ~= 0;
    if any(size(imgi) ~= size(img))
      error('Mask size mismatch between %s and %s', maskPaths{1}, maskPaths{i});
    end
    acc = acc + double(imgi);
    if i <= 3
      fprintf('  [DEBUG] Subject %d voxel count: %d\n', i, nnz(imgi));
    end
  end
  
  fprintf('  [DEBUG] Accumulator range: min=%d, max=%d\n', min(acc(:)), max(acc(:)));
  fprintf('  [DEBUG] Histogram of overlap counts:\n');
  for c = [1, 5, 10, 15, 20, nSubs]
    if c <= nSubs
      fprintf('    %d subjects: %d voxels\n', c, nnz(acc == c));
    end
  end
  
  commonMask = acc == nSubs;
  nCommon = nnz(commonMask);
  fprintf('  [DEBUG] Voxels in ALL %d subjects: %d\n', nSubs, nCommon);
  
  Vout = V1;
  Vout.fname = fullfile(outputDir, outName);
  spm_write_vol(Vout, commonMask);
  fprintf('  [DEBUG] Saved common mask to: %s\n', outName);
end

function dsOut = sliceToCommonVoxels(ds, commonIds)
  % Slice dataset to keep only common voxels
  voxIds = getVoxelIds(ds);
  [~, loc] = ismember(commonIds, voxIds);
  dsOut = cosmo_slice(ds, loc, 2);
end

function ds_group = stackAllSubjects(datasetsAligned, labels)
  % Stack all subjects into single dataset with proper targets and chunks
  nSubs = numel(datasetsAligned);
  allSamples = [];
  allTargets = [];
  allChunks = [];
  
  for iSub = 1:nSubs
    ds = datasetsAligned{iSub};
    nRuns = size(ds.samples, 1);
    allSamples = [allSamples; ds.samples]; %#ok<AGROW>
    allTargets = [allTargets; repmat(labels(iSub), nRuns, 1)]; %#ok<AGROW>
    allChunks = [allChunks; repmat(iSub, nRuns, 1)]; %#ok<AGROW>
  end
  
  % Create stacked dataset
  ds_group = struct();
  ds_group.samples = allSamples;
  ds_group.sa.targets = allTargets;
  ds_group.sa.chunks = allChunks;
  ds_group.fa = datasetsAligned{1}.fa;
  if isfield(datasetsAligned{1}, 'a')
    ds_group.a = datasetsAligned{1}.a;
  else
    ds_group.a = struct();
  end
end
