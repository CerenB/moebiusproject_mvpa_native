function [voxelNb] = binarizeImage(mask, newBinariseName, opt)
% Binarize an image based on a threshold.
%
% INPUTS:
%   mask             - path to input mask file (.nii or .nii.gz)
%   newBinariseName  - output filename. If no extension is provided, .nii is added.
%                       If ".nii.gz" is provided, a .nii is written then gzipped.
%   opt              - struct with optional fields:
%                       .threshold (double, default 0)
%                       .unzip.do (logical, default: true if mask ends with .gz, else false)
%                       .outputDir (char, default: same directory as mask)
%                       .gzip.do (logical, default: true if newBinariseName ends with .nii.gz)
%
% OUTPUT:
%   voxelNb - number of voxels > threshold after binarization

% ---------- Defaults and validation ----------
if nargin < 3 || ~isstruct(opt)
    opt = struct();
end
if ~isfield(opt, 'threshold') || isempty(opt.threshold)
    % Use 0.1 as default for resliced/interpolated masks, 0 for original masks
    % (User can override by passing opt.threshold explicitly)
    opt.threshold = 0.1;
end
if ~isfield(opt, 'outputDir')
    opt.outputDir = [];
end
if ~isfield(opt, 'unzip') || ~isstruct(opt.unzip) || ~isfield(opt.unzip, 'do')
    opt.unzip.do = endsWith(mask, '.gz');
end
if ~isfield(opt, 'gzip') || ~isstruct(opt.gzip) || ~isfield(opt.gzip, 'do')
    opt.gzip.do = endsWith(newBinariseName, '.nii.gz');
end

if ~exist('spm_vol', 'file')
    error('SPM not on path. Please add SPM to the MATLAB path before calling binarizeImage.');
end
if ~ischar(mask) || isempty(mask)
    error('mask must be a valid file path (string).');
end
if ~exist(mask, 'file')
    error('Mask file does not exist: %s', mask);
end

% ---------- Handle gz input ----------
if opt.unzip.do && endsWith(mask, '.gz')
    fprintf('Unzipping mask file: %s\n', mask);
    try
        gunzip(mask);
        % Update mask path to point to unzipped file
        mask = mask(1:end-3); % remove .gz
        fprintf('✓ Unzipping successful -> %s\n', mask);
    catch ME
        warning('Failed to unzip mask (%s). Will attempt to read compressed file directly.', ME.message);
    end
end

% ---------- Read image ----------
try
    hdr = spm_vol(mask);
    img = spm_read_vols(hdr);
catch ME
    error('Failed to read image %s: %s', mask, ME.message);
end

% Treat NaNs/Inf as 0 before thresholding
img(~isfinite(img)) = 0;

% ---------- Binarize ----------
voxelNb = sum(img(:) > opt.threshold);
img = img > opt.threshold;

% ---------- Determine output path ----------
[inDir, ~, ~] = fileparts(hdr.fname);
outDir = inDir;
if ~isempty(opt.outputDir)
    outDir = opt.outputDir;
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% If user passed .nii.gz, we first write a .nii then gzip after
isTargetGz = endsWith(newBinariseName, '.nii.gz');
[~, outBase, outExt] = fileparts(newBinariseName);
if isempty(outExt)
    outExt = '.nii';
end

if isTargetGz
    outNiiName = [outBase, '.nii'];
    finalName = [outBase, '.nii.gz'];
else
    outNiiName = [outBase, outExt];
    finalName = outNiiName;
end

outNiiPath = fullfile(outDir, outNiiName);
finalOutPath = fullfile(outDir, finalName);

% ---------- Save NIfTI ----------
hdrOut = hdr;
hdrOut.fname = outNiiPath;
try
    spm_write_vol(hdrOut, double(img));
catch ME
    error('Failed to write image %s: %s', outNiiPath, ME.message);
end

% ---------- Gzip if requested ----------
if isTargetGz || (isfield(opt, 'gzip') && isfield(opt.gzip, 'do') && opt.gzip.do)
    try
        if exist(finalOutPath, 'file')
            delete(finalOutPath); % avoid duplicate
        end
        gzip(outNiiPath);
        % gzip writes alongside, so move/rename if needed
        writtenGz = [outNiiPath, '.gz'];
        if ~strcmp(writtenGz, finalOutPath)
            movefile(writtenGz, finalOutPath, 'f');
        end
        % Optionally remove the uncompressed .nii
        delete(outNiiPath);
    catch ME
        warning('Gzip failed (%s). Keeping uncompressed file: %s', ME.message, outNiiPath);
        finalOutPath = outNiiPath;
    end
end

fprintf('Binarized mask saved: %s\n', finalOutPath);

end