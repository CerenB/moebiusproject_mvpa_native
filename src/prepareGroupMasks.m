function [opt, nCommonCount, nBin50] = prepareGroupMasks(opt, roiSourceMasks, doBalanced)
% Build group-level common and probability masks for all masks in resliced folder.
% - Discovers all .nii mask files from first subject's resliced folder
% - Gathers same-named masks from all subjects: opt.maskPath/<roiSourceMasks>/sub-*/resliced/<maskFile>
% - For each mask, writes intersection mask and probability map with threshold
% - Optional balanced mask: requires each group (by ID prefix, e.g., ctrl/mbs) to meet the threshold; intersects per-group binaries
% - Sets opt.commonMaskDir and opt.probMaskDir for downstream use
% - Uses opt.groupMvpa.condition for output naming
%
% Inputs:
%   opt - options structure with required fields: subjects, maskPath, groupMvpa.condition, pathOutput, probThreshold (default: 0.5)
%         opt.probThreshold - probability threshold for binary mask (default: 0.5 for 50%)
%                             e.g., 0.4 for 40%, 0.7 for 70%, 0.8 for 80%
%   roiSourceMasks - source mask type (e.g., 'nearest', 'bspline')
%   doBalanced - logical flag (default false). If true, create a single balanced
%                mask that requires each group to meet the threshold (logical AND of per-group binaries).

  if nargin < 3 || isempty(doBalanced)
    doBalanced = false;
  end
  if ~isfield(opt, 'probThreshold') || isempty(opt.probThreshold)
    opt.probThreshold = 0.5;  % default 50%
  end
  probThreshold = opt.probThreshold;
  if nargin < 2 || isempty(roiSourceMasks)
    error('prepareGroupMasks:missingRoiSource', 'roiSourceMasks is required (e.g., ''nearest'' or ''bspline'')');
  end
  if ~isfield(opt, 'subjects') || isempty(opt.subjects)
    error('prepareGroupMasks:missingSubjects', 'opt.subjects must be defined');
  end
  if ~isfield(opt, 'maskPath') || isempty(opt.maskPath)
    error('prepareGroupMasks:missingMaskPath', 'opt.maskPath must be set');
  end
  if ~isfield(opt, 'groupMvpa') || ~isfield(opt.groupMvpa, 'condition') || isempty(opt.groupMvpa.condition)
    error('prepareGroupMasks:missingCondition', 'opt.groupMvpa.condition must be defined');
  end
  if ~isfield(opt, 'pathOutput') || isempty(opt.pathOutput)
    error('prepareGroupMasks:missingPathOutput', 'opt.pathOutput must be set');
  end

  condStr = opt.groupMvpa.condition;
  maskOutputDir = fullfile(opt.pathOutput, 'commonVoxelMasks');
  if ~exist(maskOutputDir, 'dir')
    mkdir(maskOutputDir);
  end

  % Derive group labels from subject IDs (prefix before digits) for balanced mode
  groupLabels = cell(numel(opt.subjects),1);
  for gi = 1:numel(opt.subjects)
    tok = regexp(opt.subjects{gi}, '^[a-zA-Z]+', 'match', 'once');
    if isempty(tok)
      tok = 'group';
    end
    groupLabels{gi} = tok;
  end
  uniqueGroups = unique(groupLabels);

  % Discover all mask files from first subject's resliced folder
  firstSubID = ['sub-' opt.subjects{1}];
  reslicedDir = fullfile(opt.maskPath, roiSourceMasks, firstSubID, 'resliced');
  
  if ~exist(reslicedDir, 'dir')
    error('prepareGroupMasks:missingReslicedDir', ...
          sprintf('Resliced directory not found: %s', reslicedDir));
  end
  
  maskFiles = dir(fullfile(reslicedDir, '*.nii'));
  if isempty(maskFiles)
    error('prepareGroupMasks:noMasks', ...
          sprintf('No .nii mask files found in: %s', reslicedDir));
  end
  
  fprintf('Found %d mask files to process:\n', numel(maskFiles));
  for ii = 1:numel(maskFiles)
    fprintf('  %d. %s\n', ii, maskFiles(ii).name);
  end
  fprintf('\n');

  % Initialize output arrays
  nCommonCount = zeros(numel(maskFiles), 1);
  nBin50 = zeros(numel(maskFiles), 1);

  % Process each mask file
  for mIdx = 1:numel(maskFiles)
    targetMaskName = maskFiles(mIdx).name;
    fprintf('Processing mask %d/%d: %s\n', mIdx, numel(maskFiles), targetMaskName);
    
    % Collect mask paths from all subjects
    maskPathsAll = {};
    for i = 1:numel(opt.subjects)
      subID = ['sub-' opt.subjects{i}];
      subjMask = fullfile(opt.maskPath, roiSourceMasks, subID, 'resliced', targetMaskName);
      if exist(subjMask, 'file') == 2
        maskPathsAll{end+1,1} = subjMask; %#ok<AGROW>
      else
        fprintf('  Missing mask for %s\n', subID);
      end
    end
    
    if isempty(maskPathsAll)
      fprintf('  WARNING: No masks found for %s. Skipping.\n', targetMaskName);
      continue;
    end
    
    % Generate output names with mask filename (without .nii extension)
    [~, maskBase, ~] = fileparts(targetMaskName);
    % For probability map naming, remove '_binary' from base to avoid confusion
    maskBaseClean = strrep(maskBase, '_binary', '');
    probPct = round(probThreshold * 100);
    % Keep common mask naming as-is (may include '_binary')
    commonMaskName = sprintf('commonVoxels_fromMasks_%s_%s.nii', condStr, maskBase);
    % Probability map should not include 'binary' in base name
    probMapName = sprintf('probMap_%s_%s.nii', condStr, maskBaseClean);
    % Thresholded probability mask: add 'binary' at the end for clarity
    prob50Name = sprintf('probMap_%s_%s_%dpct_binary.nii', condStr, maskBaseClean, probPct);
    
    % Compute common mask (all subjects)
    nCommonCount(mIdx) = computeCommonMaskFromNifti(maskPathsAll, maskOutputDir, commonMaskName);
    fprintf('  Common voxels: %d\n', nCommonCount(mIdx));
    
    % Compute probability mask and threshold (pooled across all subjects)
    nBin50(mIdx) = computeProbabilityMaskFromNifti(maskPathsAll, maskOutputDir, ...
                     probMapName, prob50Name, probThreshold);
    fprintf('  Voxels in >=%.0f%% subjects: %d\n', probThreshold*100, nBin50(mIdx));

    % Balanced mask: require each group to meet threshold, then intersect (no per-group outputs)
    if doBalanced
      writeBalancedMask(opt, roiSourceMasks, targetMaskName, groupLabels, uniqueGroups, ...
                        maskBaseClean, condStr, probThreshold, probPct, maskOutputDir, maskPathsAll);
    end
  end

  % Set directories in opt
  opt.commonMaskDir = maskOutputDir;
  opt.probMaskDir = maskOutputDir;
  
  fprintf('\nGroup-level masks saved to: %s\n', maskOutputDir);
end

  function writeBalancedMask(opt, roiSourceMasks, targetMaskName, groupLabels, uniqueGroups, ...
                             maskBaseClean, condStr, probThreshold, probPct, maskOutputDir, maskPathsAll)
  % Compute a balanced mask: voxels meeting threshold within each group, then intersect.

    groupBinaries = cell(numel(uniqueGroups), 1);
    for gIdx = 1:numel(uniqueGroups)
      gName = uniqueGroups{gIdx};
      gMaskPaths = {};
      for i = 1:numel(opt.subjects)
        if strcmp(groupLabels{i}, gName)
          subID = ['sub-' opt.subjects{i}];
          subjMask = fullfile(opt.maskPath, roiSourceMasks, subID, 'resliced', targetMaskName);
          if exist(subjMask, 'file') == 2
            gMaskPaths{end+1,1} = subjMask; %#ok<AGROW>
          else
            fprintf('    Missing %s mask for %s\n', gName, subID);
          end
        end
      end
      if isempty(gMaskPaths)
        fprintf('    WARNING: No masks found for group %s (%s). Skipping balanced mask.\n', gName, targetMaskName);
        groupBinaries = {}; return;
      end

      Vg = spm_vol(char(gMaskPaths));
      Yg = spm_read_vols(Vg);
      gCount = sum(Yg > 0, 4);
      thrCount = ceil(probThreshold * numel(gMaskPaths));
      gBin = gCount >= thrCount;
      groupBinaries{gIdx} = gBin;
      fprintf('    Group %s: voxels meeting >=%.0f%% within-group: %d\n', gName, probThreshold*100, nnz(gBin));
    end

    if ~isempty(groupBinaries) && all(~cellfun('isempty', groupBinaries))
      balancedMask = groupBinaries{1};
      for gIdx = 2:numel(groupBinaries)
        balancedMask = balancedMask & groupBinaries{gIdx};
      end
      balancedMaskName = sprintf('probMap_group-balanced_%s_%s_%dpct_binary.nii', condStr, maskBaseClean, probPct);
      Vref = spm_vol(maskPathsAll{1});
      Vout = Vref;
      Vout.fname = fullfile(maskOutputDir, balancedMaskName);
      if isfield(Vout,'pinfo'); Vout = rmfield(Vout,'pinfo'); end
      if isfield(Vout,'private'); Vout = rmfield(Vout,'private'); end
      Vout = spm_create_vol(Vout);
      spm_write_vol(Vout, balancedMask);
      fprintf('    Balanced mask (all groups meet >=%.0f%%): %d voxels\n', probThreshold*100, nnz(balancedMask));
    end
  end
