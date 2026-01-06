function assembleGroupDecodingInputs(opt)
% Assemble 3D/4D subject images for group-level MVPA decoding (ctrl vs mbs)
%
% This script reorganizes per-subject statistical maps for group classification.
% Three aggregation strategies control how volumes are combined:
%
% STRATEGY 'average':
%   - Collapses ALL volumes (all conditions × runs) into ONE 3D per subject
%   - Use case: Test if ctrl vs mbs differ in overall somatosensory activity
%   - Output: 3D volume per subject
%
% STRATEGY 'specific':
%   - Filters to selected conditions, then applies granularity option
%   - GRANULARITY 'per-run':
%       * For each (run, condition), average repetitions → one volume
%       * Example: 12 runs × 1 condition = 12 volumes (4D)
%       * Use case: Decode ctrl vs mbs for specific body part with LOSO CV
%   - GRANULARITY 'per-condition-avg':
%       * Average across all runs per condition → one volume per condition
%       * Example: 5 conditions = 5 volumes (4D)
%       * Use case: Limited; fewer samples for classification
%
% STRATEGY 'concatenate':
%   - Keeps ALL original volumes unchanged (4D as-is)
%   - Use case: Full dataset without aggregation (large)
%
% Usage:
%   assembleGroupDecodingInputs(opt)
%
% Required opt fields (with defaults if missing):
%   opt.taskName              = {'somatotopy'} | {'mototopy'}
%   opt.groupMvpa.strategy    = 'average' | 'specific' | 'concatenate'
%   opt.groupMvpa.imageType   = 'tmap' | 'beta'   % uses desc-4D_<imageType>.nii
%   opt.groupMvpa.conditions  = {'hand'}         % pattern match (case-insensitive) for 'specific'
%   opt.groupMvpa.sampleGranularity = 'per-run' | 'per-condition-avg'
%   opt.groupMvpa.writeNifti  = true/false       % write per-subject NIfTIs
%   opt.space          = 'MNI152NLin2009cAsym' | 'T1w' (folder name)
%
% Output (saved under outputs/derivatives/cosmoMvpa/group):
%   - TSV file listing subject id and group (1=ctrl, 2=mbs)
%   - Per-subject NIfTI files (if writeNifti=true) in FFX directories

  if nargin<1 || isempty(opt)
    opt = setDefaultOptions();
  end

  % Minimal path setup (SPM + bidspm), consistent with other scripts
%   warning('off');
%   if exist('/Users/battal/Documents/MATLAB/spm12','dir')
%     addpath(genpath('/Users/battal/Documents/MATLAB/spm12'));
%   end
%   this_dir = fullfile('/Volumes/extreme/Cerens_files/fMRI', ...
%                       'moebius_topo_analyses/code/src/mvpa');
%   addpath(fullfile(this_dir, '..', '..', 'lib', 'bidspm'), '-begin');
%   if exist('bidspm','file')==2
%     bidspm();
%   end

    fprintf('\n========================================\n');
  fprintf('PREPARING GROUP-LEVEL MVPA DECODING\n');
    fprintf('Task: %s | Strategy: %s | Image: %s | Space: %s\n', ...
      opt.taskName{1}, opt.groupMvpa.strategy, ...
      opt.groupMvpa.imageType, opt.space{1});
  fprintf('========================================\n');

  % Participants by group (match project lists)
  ctrlSubjects = {'ctrl001','ctrl002','ctrl003','ctrl004','ctrl005', ...
                  'ctrl007','ctrl008','ctrl009','ctrl010','ctrl011', ...
                  'ctrl012','ctrl013','ctrl015','ctrl016','ctrl017'};
  mbsSubjects  = {'mbs001','mbs002','mbs003','mbs004','mbs005','mbs006','mbs007'};

  % If task is mototopy, include ctrl014 in the ctrl list
  if isfield(opt,'taskName') && ~isempty(opt.taskName) && strcmp(opt.taskName{1}, 'mototopy')
    if ~ismember('ctrl014', ctrlSubjects)
      ctrlSubjects{end+1} = 'ctrl014';
    end
  end

  allSubjects = [ctrlSubjects, mbsSubjects];
  groupLabels = [ones(1, numel(ctrlSubjects)), 2*ones(1, numel(mbsSubjects))]; % 1=ctrl, 2=mbs

  % Directories
  statsBaseDir = fullfile('/Volumes/extreme/Cerens_files/fMRI/', ...
                          'moebius_topo_analyses/outputs/derivatives/', ...
                          'bidspm-stats');
  outputDir = fullfile(statsBaseDir, '..', 'cosmoMvpa', 'group');
  if ~exist(outputDir,'dir'); mkdir(outputDir); end

  % Get condition list from first available subject (for logging only)
  [firstTsv, firstSub] = find_first_labelfold(statsBaseDir, allSubjects, opt);
  if isempty(firstTsv)
    error('No labelfold.tsv found in any subject FFX directory.');
  end
  fprintf('Using labelfold example: %s\n', firstTsv);
  t = readtable(firstTsv, 'FileType','text', 'Delimiter','\t');
  if ismember('labels', t.Properties.VariableNames)
    allConditions = string(t.labels);
  else
    allConditions = string(t{:, end});
  end
  allConditions = strtrim(allConditions);
  fprintf('Example subject %s has %d conditions. Labels: %s\n', firstSub, ...
          numel(allConditions), strjoin(unique(allConditions), ', '));

  strategy = opt.groupMvpa.strategy;
  gran = opt.groupMvpa.sampleGranularity;
  if strcmp(strategy, 'specific')
    selectedConditions = strtrim(string(opt.groupMvpa.conditions));
  end

  if strcmp(strategy, 'concatenate')
    if ~isfield(opt.groupMvpa, 'writeNifti') || ~opt.groupMvpa.writeNifti
      fprintf('Concatenate strategy: using existing 4D maps as-is; no new NIfTI outputs will be written.\n');
    else
      fprintf('Concatenate strategy: using existing 4D maps and writing subject copies (opt.groupMvpa.writeNifti=true).\n');
    end
  end
  validSubjects = {};
  validLabels = [];
  validMetadata = cell(numel(allSubjects), 1); % store labels & folds per subject

  for iSub = 1:numel(allSubjects)
    subID = allSubjects{iSub};
    subLabel = ['sub-' subID];
    gLab = groupLabels(iSub);
    ffxDir = fullfile(statsBaseDir, subLabel, ...
              ['task-', opt.taskName{1}, '_space-', opt.space{1}, ...
              '_FWHM-', num2str(opt.fwhm.func)]);

    fprintf('\nProcessing %s (group %d) [%d/%d]\n', ...
            subLabel, gLab, iSub, numel(allSubjects));
    if ~exist(ffxDir,'dir')
      warning('Stats dir missing, skip: %s', ffxDir); continue; end

    imgPath = resolve_image_path(ffxDir, subLabel, opt, strategy);
    if isempty(imgPath)
      warning('4D image missing, skip dir: %s', ffxDir); continue; end

    tsvPath = find_labelfold_tsv(ffxDir, subLabel, opt);
    if isempty(tsvPath)
      warning('labelfold.tsv missing, skip: %s', subLabel); continue; end
    fprintf('  labelfold.tsv: %s\n', tsvPath);
    tt = readtable(tsvPath, 'FileType','text', 'Delimiter','\t');
    if ismember('labels', tt.Properties.VariableNames)
      labelsThis = string(tt.labels);
    else
      labelsThis = string(tt{:, end});
    end
    labelsThis = strtrim(labelsThis);
    if ismember('folds', tt.Properties.VariableNames)
      foldsThis = double(tt.folds);
    else
      % fallback: assume sequential folds 1..N if missing
      foldsThis = (1:numel(labelsThis))';
    end

    V = spm_vol(imgPath);
    Y = spm_read_vols(V);
    nvol = size(Y,4);

    % Debug info on labels and volumes
    fprintf('  Volumes: %d | Labels: %d | Unique labels: %s\n', nvol, numel(labelsThis), strjoin(unique(labelsThis), ', '));

    if nvol ~= numel(labelsThis)
      warning('Volumes (%d) != labels (%d) for %s. Proceeding with min.', nvol, numel(labelsThis), subLabel);
      nvol = min(nvol, numel(labelsThis));
      Y = Y(:,:,:,1:nvol);
      labelsThis = labelsThis(1:nvol);
    end

    switch strategy
      case 'average'
        % Average across ALL volumes (conditions x runs)
        subjData = mean(Y,4);
        groupData{iSub} = subjData;
        validMetadata{iSub} = struct('labels', {{'average'}}, 'folds', {1});
        validSubjects{end+1} = subID; %#ok<AGROW>
        validLabels(end+1) = gLab; %#ok<AGROW>

      case 'specific'
        % Use pattern matching to find conditions containing the selected strings
        condMask = false(size(labelsThis));
        for c = selectedConditions
          condMask = condMask | contains(labelsThis, c, 'IgnoreCase', true);
        end
        if ~any(condMask)
          warning('No selected conditions found for %s. Available labels: %s', ...
                  subLabel, strjoin(unique(labelsThis), ', '));
          continue;
        end
        fprintf('  Selected labels: %s\n', strjoin(unique(labelsThis(condMask)), ', '));
        switch gran
          case 'per-run'
            runs = unique(foldsThis(:))';
            conds = unique(labelsThis(condMask))';
            volList = {};
            volData = [];
            metaLabels = {};
            metaFolds = [];
            for r = runs
              for c = conds
                idx = find(foldsThis==r & labelsThis==c);
                if isempty(idx), continue; end
                avgRC = mean(Y(:,:,:,idx), 4);
                volData = cat(4, volData, avgRC);
                metaLabels{end+1} = char(c); %#ok<AGROW>
                metaFolds(end+1) = r; %#ok<AGROW>
              end
            end
            if isempty(volData)
              warning('No volumes after per-run aggregation for %s', subLabel); continue; end
            groupData{iSub} = volData; % 4D: [X Y Z (runs*conds)]
            validMetadata{iSub} = struct('labels', {metaLabels}, 'folds', metaFolds);
          case 'per-condition-avg'
            conds = unique(labelsThis(condMask))';
            volData = [];
            metaLabels = {};
            for c = conds
              idx = find(labelsThis==c);
              avgC = mean(Y(:,:,:,idx), 4);
              volData = cat(4, volData, avgC);
              metaLabels{end+1} = char(c); %#ok<AGROW>
            end
            groupData{iSub} = volData; % 4D with one vol per condition
            validMetadata{iSub} = struct('labels', {metaLabels}, 'folds', 1:numel(conds));
          otherwise
            error('Unknown sampleGranularity: %s', gran);
        end
        validSubjects{end+1} = subID; %#ok<AGROW>
        validLabels(end+1) = gLab; %#ok<AGROW>

      case 'concatenate'
        % keep all volumes (conditions x runs) as-is
        groupData{iSub} = Y; % 4D
        metaLabels = cellfun(@char, num2cell(labelsThis), 'UniformOutput', false);
        validMetadata{iSub} = struct('labels', {metaLabels}, 'folds', foldsThis);
        validSubjects{end+1} = subID; %#ok<AGROW>
        validLabels(end+1) = gLab; %#ok<AGROW>

      otherwise
        error('Unknown strategy: %s', strategy);
    end
  end

  keep = ~cellfun('isempty', groupData);
  groupData = groupData(keep);
  validMetadata = validMetadata(keep);
  validSubjects = validSubjects(keep);
  validLabels = validLabels(keep);

  fprintf('\n========================================\n');
  fprintf('Prepared %d subjects (ctrl=%d, mbs=%d)\n', numel(validSubjects), ...
          sum(validLabels==1), sum(validLabels==2));
  fprintf('========================================\n');

  if isempty(validSubjects)
    error('No subjects prepared. Check that selected conditions match available labels and that 4D maps/labelfold.tsv exist.');
  end

  % Save subject list with group labels
  saveFilename = sprintf('groupDecoding_%s_%s_%s.tsv', ...
                         opt.taskName{1}, strategy, datestr(now, 'yyyymmddHHMMSS'));
  tsvPath = fullfile(outputDir, saveFilename);
  tOut = table(validSubjects', validLabels', string(groupStr(validLabels))', ...
               'VariableNames', {'subject','group','groupLabel'});
  writetable(tOut, tsvPath, 'FileType', 'text', 'Delimiter', '\t');
  fprintf('Saved subject list: %s\n', tsvPath);

  % Optionally write per-subject NIfTIs to disk for downstream reproducibility
  writeNifti = isfield(opt.groupMvpa, 'writeNifti') && opt.groupMvpa.writeNifti;
  if strcmp(strategy, 'concatenate')
    if writeNifti
      fprintf('Concatenate strategy: skipping NIfTI writing to avoid rewriting existing 4D maps.\n');
    end
    writeNifti = false; % do not rewrite existing 4D maps
  end

  if writeNifti
    fprintf('Writing per-subject NIfTIs to disk...\n');
    for i = 1:numel(validSubjects)
      subID = validSubjects{i};
      subLabel = ['sub-' subID];
      ffxDir = fullfile(statsBaseDir, subLabel, ...
                        ['task-', opt.taskName{1}, '_space-', opt.space{1}, '_FWHM-2']);
      imgName = sprintf('%s_task-%s_space-%s_desc-4D_%s.nii', ...
                        subLabel, opt.taskName{1}, opt.space{1}, opt.groupMvpa.imageType);
      imgPath = fullfile(ffxDir, imgName);
      if ~exist(imgPath,'file'), continue; end
      Vref = spm_vol(imgPath);
      Ysub = groupData{i};
      meta = validMetadata{i};
      write_subject_nifti_and_tsv(Vref, Ysub, meta, ffxDir, subLabel, opt);
    end
  end

end

function [tsvPath, subID] = find_first_labelfold(statsBaseDir, allSubjects, opt)
  tsvPath = '';
  subID = '';
  for i=1:numel(allSubjects)
    sub = allSubjects{i};
    subLabel = ['sub-' sub];
    ffxDir = fullfile(statsBaseDir, subLabel, ...
              ['task-', opt.taskName{1}, '_space-', opt.space{1}, '_FWHM-2']);
    p = find_labelfold_tsv(ffxDir, subLabel, opt);
    if ~isempty(p)
      tsvPath = p; subID = sub; return; end
  end
end

function p = find_labelfold_tsv(ffxDir, subLabel, opt)
  % Deterministic labelfold path: sub-XX_task-<task>_space-<space>_labelfold.tsv
  p = '';
  if ~exist(ffxDir,'dir'); return; end
  fname = sprintf('%s_task-%s_space-%s_labelfold.tsv', ...
                  subLabel, opt.taskName{1}, opt.space{1});
  cand = fullfile(ffxDir, fname);
  if exist(cand, 'file')
    p = cand;
  end
end

function imgPath = resolve_image_path(ffxDir, subLabel, opt, strategy)
  % Resolve 4D image path with controlled fallbacks
  imgPath = '';
  % Primary expected name
  primary = sprintf('%s_task-%s_space-%s_desc-4D_%s.nii', ...
            subLabel, opt.taskName{1}, opt.space{1}, opt.groupMvpa.imageType);
  cand = fullfile(ffxDir, primary);
  if exist(cand, 'file')
    imgPath = cand; return;
  end

  % Fallback 1: any desc-4D_<imageType>.nii
  dd = dir(fullfile(ffxDir, sprintf('*desc-4D_%s.nii', opt.groupMvpa.imageType)));
  if ~isempty(dd)
    imgPath = fullfile(ffxDir, dd(1).name); return;
  end

  % Fallback 2: any desc-4D_*.nii
  dd = dir(fullfile(ffxDir, '*desc-4D_*.nii'));
  if ~isempty(dd)
    imgPath = fullfile(ffxDir, dd(1).name); return;
  end

  % Fallback 3: only for non-specific strategies, allow all3D as last resort
  if ~strcmp(strategy, 'specific')
    dd = dir(fullfile(ffxDir, sprintf('*desc-all3D_%s.nii', opt.groupMvpa.imageType)));
    if ~isempty(dd)
      imgPath = fullfile(ffxDir, dd(1).name); return;
    end
  end
end

function s = groupStr(lbl)
  s = repmat("", size(lbl));
  s(lbl==1) = "ctrl";
  s(lbl==2) = "mbs";
end

function opt = setDefaultOptions()
  opt.taskName = {'somatotopy'};
  opt.space = {'MNI152NLin2009cAsym'};
  opt.groupMvpa.strategy = 'specific'; % 'average' | 'specific' | 'concatenate'
  opt.groupMvpa.imageType = 'tmap';    % 'tmap' | 'beta'
  opt.groupMvpa.conditions = {'hand'}; % pattern match (case-insensitive) if strategy='specific'
  opt.groupMvpa.sampleGranularity = 'per-run'; % 'per-run' | 'per-condition-avg'
  opt.groupMvpa.writeNifti = false;
end

function write_nifti_like(Vref, Y3D, outPath)
  Vout = Vref;
  Vout.fname = outPath;
  Vout.descrip = 'groupMvpa-derived';
  if isfield(Vout,'pinfo'); Vout = rmfield(Vout,'pinfo'); end
  if isfield(Vout,'private'); Vout = rmfield(Vout,'private'); end
  Vout = spm_create_vol(Vout);
  spm_write_vol(Vout, Y3D);
end

function write_subject_nifti_and_tsv(Vref, Ysub, meta, outDirSub, subLabel, opt)
  % Generate condition suffix for filename
  if strcmp(opt.groupMvpa.strategy, 'specific')
    condStr = strjoin(opt.groupMvpa.conditions, '');
    condStr = strrep(condStr, ' ', ''); % remove spaces
    descStr = [condStr '4D'];
  else
    descStr = 'all4D';
  end
  
  if ndims(Ysub)==3
    out3d = fullfile(outDirSub, sprintf('%s_task-%s_space-%s_desc-%s_%s.nii', ...
                    subLabel, opt.taskName{1}, opt.space{1}, strrep(descStr, '4D', '3D'), opt.groupMvpa.imageType));
    write_nifti_like(Vref(1), Ysub, out3d);
    % Write TSV
    tsvOut = strrep(out3d, '.nii', '_labelfold.tsv');
    tMeta = table(meta.labels', meta.folds', 'VariableNames', {'labels','folds'});
    writetable(tMeta, tsvOut, 'FileType', 'text', 'Delimiter', '\t');
  else
    % write per-volume temps then merge to 4D
    nV = size(Ysub,4);
    tmpList = cell(nV,1);
    for k=1:nV
      tmpList{k} = fullfile(outDirSub, sprintf('%s_task-%s_space-%s_desc-%sVol-%03d_%s.nii', ...
                     subLabel, opt.taskName{1}, opt.space{1}, descStr, k, opt.groupMvpa.imageType));
      write_nifti_like(Vref(1), Ysub(:,:,:,k), tmpList{k});
    end
    out4d = fullfile(outDirSub, sprintf('%s_task-%s_space-%s_desc-%s_%s.nii', ...
                    subLabel, opt.taskName{1}, opt.space{1}, descStr, opt.groupMvpa.imageType));
    try
      spm_file_merge(char(tmpList), out4d);
      % cleanup temps
      for k=1:numel(tmpList), if exist(tmpList{k},'file'), delete(tmpList{k}); end, end
      % Write TSV
      tsvOut = strrep(out4d, '.nii', '_labelfold.tsv');
      tMeta = table(meta.labels', meta.folds', 'VariableNames', {'labels','folds'});
      writetable(tMeta, tsvOut, 'FileType', 'text', 'Delimiter', '\t');
    catch ME
      warning('spm_file_merge failed for %s: %s', subLabel, ME.message);
    end
  end
end
