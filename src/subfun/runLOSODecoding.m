function [accuracy, foldAccuracy, predictions, trueLabels] = runLOSODecoding(ds_group, opt)
% Run Leave-One-Subject-Out cross-validation using cosmo_crossvalidate.
%
% Inputs:
%   ds_group : CoSMoMVPA dataset with samples stacked across subjects
%   opt      : options struct (expects opt.mvpa fields)
%
% Outputs:
%   accuracy      : overall accuracy across all samples
%   foldAccuracy  : per-fold accuracy (one fold per held-out subject)
%   predictions   : one predicted label per subject (mode across runs)
%   trueLabels    : true label per subject

  % Debug: Check class distribution
  unique_targets = unique(ds_group.sa.targets);
  unique_chunks = unique(ds_group.sa.chunks);
  nCtrl = sum(ds_group.sa.targets == 1);
  nMbs = sum(ds_group.sa.targets == 2);
  fprintf('\n  DEBUG: Dataset structure\n');
  fprintf('    Unique targets (classes): %s\n', mat2str(unique_targets));
  fprintf('    Unique chunks (subjects): %s\n', mat2str(unique_chunks));
  fprintf('    Class 1 (ctrl): %d samples\n', nCtrl);
  fprintf('    Class 2 (mbs): %d samples\n', nMbs);
  
  % Check which chunks belong to which class
  fprintf('    Per-subject class assignment:\n');
  for iChunk = 1:max(ds_group.sa.chunks)
    chunkMask = ds_group.sa.chunks == iChunk;
    classForChunk = ds_group.sa.targets(chunkMask);
    classForChunk = classForChunk(1);  % Should be same for all runs
    fprintf('      Subject %2d: Class %d\n', iChunk, classForChunk);
  end

  % Set up MVPA options for feature selection + classification
  if ~isfield(opt, 'mvpa')
    opt.mvpa = struct();
  end
  if isfield(opt.mvpa, 'ratioToKeep')
    opt.mvpa.feature_selection_ratio_to_keep = opt.mvpa.ratioToKeep;
    fprintf('  Feature selection: top %d voxels via ANOVA\n', opt.mvpa.ratioToKeep);
  end
  if ~isfield(opt.mvpa, 'child_classifier')
    opt.mvpa.child_classifier = @cosmo_classify_lda;
  end
  fprintf('  Using classifier: %s\n', func2str(opt.mvpa.child_classifier));
  if isfield(opt.mvpa, 'normalization')
    fprintf('  Normalization: %s (applied per fold)\n', opt.mvpa.normalization);
  end
  
  % Allow unbalanced partitions (ctrl and mbs groups have different sizes)
  % This is expected for between-participants design with unequal group sizes
  opt.mvpa.unbalanced_partitions_ok = true;

  % For between-participants design with multiple runs per subject:
  % Create independent samples partitioner treating each subject as an independent sample
  % This is appropriate for ctrl vs mbs classification where subjects are the unit of analysis
  % and all chunks (subjects) are truly independent (no repeated measures)
  
  % First, create a subject-level dataset (one row per subject, keeping target/chunk info)
  % Required: .sa.chunks must have all unique values for cosmo_independent_samples_partitioner
  unique_chunks = unique(ds_group.sa.chunks);
  nSubs = numel(unique_chunks);
  ds_subject_level = struct();
  ds_subject_level.samples = zeros(nSubs, size(ds_group.samples, 2));  % nSubs x nVoxels
  ds_subject_level.sa.targets = zeros(nSubs, 1);
  ds_subject_level.sa.chunks = (1:nSubs)';  % All unique: required by cosmo_independent_samples_partitioner
  
  % For each subject, average their runs to create subject-level features
  for iSub = 1:nSubs
    subMask = ds_group.sa.chunks == unique_chunks(iSub);
    ds_subject_level.samples(iSub, :) = mean(ds_group.samples(subMask, :), 1);
    ds_subject_level.sa.targets(iSub) = ds_group.sa.targets(find(subMask, 1));
  end
  
  % Create independent samples partitions (subject-level, LOSO-like with test_count=1)
  % test_count=1: one subject per class in test set per fold
  % fold_count=nSubs: create nSubs folds (similar to LOSO but properly balanced)
  partitions_subject = cosmo_independent_samples_partitioner(ds_subject_level, ...
                                                             'test_count', 1, ...
                                                             'fold_count', nSubs);
  fprintf('  Using independent samples partitioner (between-participants: subjects are independent)\n');
  fprintf('  %d subjects in %d folds (test_count=1 per class)\n', nSubs, nSubs);
  
  % Now expand partitions back to full dataset (all runs per subject)
  nFolds = numel(partitions_subject.train_indices);
  partitions = struct();
  partitions.train_indices = cell(nFolds, 1);
  partitions.test_indices = cell(nFolds, 1);
  
  for iFold = 1:nFolds
    train_subs = unique_chunks(partitions_subject.train_indices{iFold});
    test_subs = unique_chunks(partitions_subject.test_indices{iFold});
    
    % Expand to all samples (runs) in those subjects
    partitions.train_indices{iFold} = find(ismember(ds_group.sa.chunks, train_subs));
    partitions.test_indices{iFold} = find(ismember(ds_group.sa.chunks, test_subs));
  end

  % Cross-validation with feature selection
  [pred, accuracy] = cosmo_crossvalidate(ds_group, ...
                                         @cosmo_classify_meta_feature_selection, ...
                                         partitions, opt.mvpa);

  % Per-fold accuracy
  nFolds = numel(partitions.train_indices);
  foldAccuracy = zeros(nFolds, 1);
  for iFold = 1:nFolds
    testIdx = partitions.test_indices{iFold};
    foldAccuracy(iFold) = mean(pred(testIdx) == ds_group.sa.targets(testIdx));
  end

  % One prediction per subject (mode across runs)
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
