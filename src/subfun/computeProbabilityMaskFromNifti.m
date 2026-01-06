function nBin = computeProbabilityMaskFromNifti(maskPaths, outputDir, probName, binName, threshFrac)
% Build probability map across subjects and save probability map plus thresholded mask.
  if isempty(maskPaths)
    error('No mask paths provided for probability mask.');
  end
  if nargin < 5 || isempty(threshFrac)
    threshFrac = 0.5;
  end
  nSubs = numel(maskPaths);
  if exist(outputDir, 'dir')~=7
    mkdir(outputDir);
  end
  V1 = spm_vol(maskPaths{1});
  acc = double(spm_read_vols(V1) ~= 0);
  for i = 2:nSubs
    Vi = spm_vol(maskPaths{i});
    imgi = spm_read_vols(Vi) ~= 0;
    if any(size(imgi) ~= size(acc))
      error('Mask size mismatch between %s and %s', maskPaths{1}, maskPaths{i});
    end
    acc = acc + double(imgi);
  end
  probMap = acc / nSubs;
  binMask = probMap >= threshFrac;
  nBin = nnz(binMask);
  Vprob = V1;
  Vprob.fname = fullfile(outputDir, probName);
  Vprob.dt(1) = spm_type('float32');
  spm_write_vol(Vprob, probMap);
  Vbin = V1;
  Vbin.fname = fullfile(outputDir, binName);
  Vbin.dt(1) = spm_type('uint8');
  spm_write_vol(Vbin, binMask);
end
