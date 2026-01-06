function nCommon = computeCommonMaskFromNifti(maskPaths, outputDir, outName)
% Stack binary masks as NIfTI, count overlaps, and save voxels present in all subjects.
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
  for i = 2:nSubs
    Vi = spm_vol(maskPaths{i});
    imgi = spm_read_vols(Vi) ~= 0;
    if any(size(imgi) ~= size(img))
      error('Mask size mismatch between %s and %s', maskPaths{1}, maskPaths{i});
    end
    acc = acc + double(imgi);
  end
  commonMask = acc == nSubs;
  nCommon = nnz(commonMask);
  Vout = V1;
  Vout.fname = fullfile(outputDir, outName);
  spm_write_vol(Vout, commonMask);
end
