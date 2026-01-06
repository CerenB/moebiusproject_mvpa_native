function commonMaskPath = saveCommonVoxelMask(datasets, outputDir, templateSource, saveName)
% Save a binary mask showing common voxels across all subjects (NIfTI via SPM)
%
% Usage:
%   commonMaskPath = saveCommonVoxelMask(datasets, outputDir, [], saveName);
%   commonMaskPath = saveCommonVoxelMask(datasets, outputDir, '/path/to/template.nii', saveName);
%
% Inputs:
%   datasets         cell array of CoSMoMVPA datasets (one per subject)
%   outputDir        directory where to save the mask
%   templateSource   optional: path to a NIfTI to copy header from, or a CoSMo dataset
%   saveName         filename for output mask (e.g., 'commonVoxels_hand.nii')
%
% Outputs:
%   commonMaskPath   path to saved common voxel mask

  if nargin < 4 || isempty(saveName)
    saveName = 'commonVoxelMask.nii';
  end
  
  % Create output directory if needed
  if ~exist(outputDir, 'dir')
    mkdir(outputDir);
  end
  
  nSubs = numel(datasets);
  fprintf('  Finding common voxels across %d subjects...\n', nSubs);
  
  % Get voxel coordinates for each subject
  allCoords = cell(nSubs, 1);
  for i = 1:nSubs
    ds = datasets{i};
    
    % Extract voxel coordinates
    if isfield(ds.fa, 'i') && isfield(ds.fa, 'j') && isfield(ds.fa, 'k')
      coords = [ds.fa.i(:), ds.fa.j(:), ds.fa.k(:)];
      allCoords{i} = coords;
      fprintf('    Subject %d: %d voxels\n', i, size(coords, 1));
    else
      error('Dataset %d does not have voxel coordinate information (i, j, k).', i);
    end
  end
  
  % Find intersection: voxels present in all subjects
  fprintf('  Computing intersection...\n');
  
  % Convert coordinates to unique row identifiers for faster intersection
  commonCoords = allCoords{1};
  for i = 2:nSubs
    % Find rows in commonCoords that exist in allCoords{i}
    [~, ia, ~] = intersect(commonCoords, allCoords{i}, 'rows');
    commonCoords = commonCoords(ia, :);
  end
  
  nCommon = size(commonCoords, 1);
  fprintf('  Common voxels: %d\n', nCommon);
  
  % Get volume dimensions from first dataset
  % Reconstruct volume size from coordinates
  maxI = max(commonCoords(:, 1));
  maxJ = max(commonCoords(:, 2));
  maxK = max(commonCoords(:, 3));
  volSize = [maxI, maxJ, maxK];
  
  % Create binary mask with common voxels
  commonMask = zeros(volSize, 'uint8');
  
  % Set common voxels to 1
  for iVox = 1:nCommon
    i = commonCoords(iVox, 1);
    j = commonCoords(iVox, 2);
    k = commonCoords(iVox, 3);
    commonMask(i, j, k) = 1;
  end
  
  % Prepare template header
  Vtmpl = [];
  if nargin >= 3 && ~isempty(templateSource)
    if ischar(templateSource) && exist(templateSource, 'file') == 2
      Vtmpl = spm_vol(templateSource);
    elseif isstruct(templateSource) && isfield(templateSource, 'a') && isfield(templateSource.a, 'vol')
      Vtmpl = templateSource.a.vol(1);
    end
  end
  if isempty(Vtmpl) && isstruct(datasets{1}) && isfield(datasets{1}, 'a') && isfield(datasets{1}.a, 'vol')
    Vtmpl = datasets{1}.a.vol(1);
  end
  if isempty(Vtmpl)
    error('No template volume found to write NIfTI mask. Provide templateSource or ensure datasets{1}.a.vol exists.');
  end
  Vout = Vtmpl;
  Vout.fname = fullfile(outputDir, saveName);
  Vout.dt(1) = spm_type('uint8');
  Vout.dim = size(commonMask);
  spm_write_vol(Vout, commonMask);
  commonMaskPath = Vout.fname;
  fprintf('  Saving common voxel mask: %s\n', commonMaskPath);
  fprintf('  Done. Common voxel mask saved.\n');
  
end
