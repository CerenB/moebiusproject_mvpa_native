function checkDimensionsAndSpace(image1, image2)
% Check if two NIfTI images have matching dimensions and spatial properties
%
% INPUTS:
%   image1 - path to first NIfTI file
%   image2 - path to second NIfTI file
%
% This function compares:
% - Image dimensions
% - Voxel sizes
% - Affine transformation matrices
% - Bounding boxes

if ~exist('spm_vol', 'file')
    error('SPM must be on path.');
end

fprintf('\n========== Spatial Comparison ==========\n');
fprintf('Image 1: %s\n', image1);
fprintf('Image 2: %s\n\n', image2);

% Read headers
hdr1 = spm_vol(image1);
hdr2 = spm_vol(image2);

% Handle 4D images (take first volume)
if length(hdr1) > 1
    fprintf('Image 1 is 4D (%d volumes). Using first volume.\n', length(hdr1));
    hdr1 = hdr1(1);
end
if length(hdr2) > 1
    fprintf('Image 2 is 4D (%d volumes). Using first volume.\n', length(hdr2));
    hdr2 = hdr2(1);
end

% Compare dimensions
fprintf('Dimensions:\n');
fprintf('  Image 1: [%d %d %d]\n', hdr1.dim);
fprintf('  Image 2: [%d %d %d]\n', hdr2.dim);
dimMatch = isequal(hdr1.dim, hdr2.dim);
if dimMatch
    fprintf('  ✓ MATCH\n\n');
else
    fprintf('  ✗ MISMATCH - Cannot use for MVPA!\n\n');
end

% Compare voxel sizes
vox1 = sqrt(sum(hdr1.mat(1:3,1:3).^2));
vox2 = sqrt(sum(hdr2.mat(1:3,1:3).^2));
fprintf('Voxel sizes (mm):\n');
fprintf('  Image 1: [%.2f %.2f %.2f]\n', vox1);
fprintf('  Image 2: [%.2f %.2f %.2f]\n', vox2);
voxMatch = all(abs(vox1 - vox2) < 0.01);
if voxMatch
    fprintf('  ✓ MATCH\n\n');
else
    fprintf('  ✗ MISMATCH\n\n');
end

% Compare affine matrices
fprintf('Affine transformation matrices:\n');
fprintf('  Image 1:\n');
disp(hdr1.mat);
fprintf('  Image 2:\n');
disp(hdr2.mat);
matMatch = all(abs(hdr1.mat(:) - hdr2.mat(:)) < 0.01);
if matMatch
    fprintf('  ✓ MATCH\n\n');
else
    fprintf('  ✗ MISMATCH\n\n');
end

% Overall verdict
fprintf('========================================\n');
if dimMatch && voxMatch && matMatch
    fprintf('✓ Images are in the SAME space - OK for MVPA\n');
else
    fprintf('✗ Images are in DIFFERENT spaces - RESLICING REQUIRED\n');
    if ~dimMatch
        fprintf('  - Dimensions differ\n');
    end
    if ~voxMatch
        fprintf('  - Voxel sizes differ\n');
    end
    if ~matMatch
        fprintf('  - Spatial transformations differ\n');
    end
end
fprintf('========================================\n\n');

end
