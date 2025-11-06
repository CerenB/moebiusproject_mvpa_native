function test_binarizeImage()
% Simple test for binarizeImage using a synthetic volume.
% Requires SPM on path.

if ~exist('spm_vol','file')
    error('SPM must be on path to run this test.');
end

% Create synthetic data
rng(0);
V = rand(10,10,10);
maskDir = tempname;
mkdir(maskDir);
maskPath = fullfile(maskDir, 'synthetic.nii');

% Build SPM header
hdr = struct();
hdr.fname = maskPath;
hdr.dim = size(V);
hdr.dt = [spm_type('float32') 0];
hdr.mat = eye(4);
hdr.pinfo = [1;0;0];

spm_write_vol(hdr, V);

% Run binarization
opt = struct();
opt.threshold = 0.5;
opt.unzip = struct('do', false);
opt.outputDir = maskDir;

outName = 'synthetic_bin.nii';
expected = sum(V(:) > opt.threshold);
voxelNb = binarizeImage(maskPath, outName, opt);

assert(voxelNb == expected, 'Voxel count mismatch: got %d expected %d', voxelNb, expected);

% Read back and verify binary content
Vout = spm_read_vols(spm_vol(fullfile(maskDir, outName)));
assert(all(ismember(Vout(:), [0,1])), 'Output image is not binary');

fprintf('test_binarizeImage passed. Voxels > threshold: %d\n', voxelNb);

end
