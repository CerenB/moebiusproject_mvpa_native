function [voxelNb, dims] = voxelCountAndDimensions(image)
% count how many voxels we have in the image

  hdr = spm_vol(image);
  img = spm_read_vols(hdr);
  
  %voxel number
  voxelNb = sum(img(:) == 1);
  
  %dimensions
  dims = hdr.dim;
  
end