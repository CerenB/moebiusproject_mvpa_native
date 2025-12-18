function resliceAndBinarizeSingleMask(originalMask, maskName, maskExt, refDim, refImage, ...
                                      maskOutputDir, tempDir, opt)
% Reslice and binarize one mask
%
% Usage:
%   resliceAndBinarizeSingleMask(maskPath, 'L_area3a', '.nii', refDim, refImage, outDir, tempDir, opt)
%
% Inputs:
%   originalMask    - full path to input mask file
%   maskName        - name without extension (e.g., 'L_area3a')
%   maskExt         - file extension (e.g., '.nii')
%   refDim          - reference dimensions [x y z]
%   refImage        - full path to reference 4D image
%   maskOutputDir   - output directory for final masks
%   tempDir         - temporary directory for intermediate files
%   opt             - options struct with threshold, reslice.do, save.roi, outputDir

fprintf('    Mask: %s\n', [maskName, maskExt]);

try
    % Get original mask dimensions
    hdr_orig = spm_vol(originalMask);
    origDim = hdr_orig.dim;
    
    % Check if reslicing is needed
    if ~isequal(origDim(1:3), refDim(1:3))
        fprintf('      ⚠ Dimensions differ [%d %d %d] → [%d %d %d]\n', ...
                origDim(1), origDim(2), origDim(3), refDim(1), refDim(2), refDim(3));
        
        % Copy mask to temp directory first
        tempInputMask = fullfile(tempDir, [maskName, '.nii']);
        copyfile(originalMask, tempInputMask);
        
        % Reslice mask to match reference dimensions
        opt.outputDir = tempDir;
        reslicedMask = prepareRoi(opt, tempInputMask, refImage);
        
        if ~exist(reslicedMask, 'file')
            warning('      ✗ Reslicing failed');
            return;
        end
        fprintf('      ✓ Resliced\n');
    else
        fprintf('      ✓ Dims match (no reslicing needed)\n');
        reslicedMask = originalMask;
    end
    
    % Re-binarize after reslicing
    fprintf('      Binarizing...\n');
    opt.threshold = 0.2;  % Higher threshold for interpolated data
    opt.outputDir = maskOutputDir;
    
    finalMaskName = [maskName, '.nii'];
    [voxelNbFinal] = binarizeImage(reslicedMask, finalMaskName, opt);
    
    % Verify final dimensions
    finalMask = fullfile(maskOutputDir, finalMaskName);
    hdr_final = spm_vol(finalMask);
    finalDim = hdr_final(1).dim;
    
    % Check dimensions
    if isequal(finalDim(1:3), refDim(1:3))
        fprintf('      ✓ READY: [%d %d %d] | voxels: %d\n', ...
                finalDim(1), finalDim(2), finalDim(3), voxelNbFinal);
    else
        warning('      ✗ Final dims [%d %d %d] ≠ reference [%d %d %d]', ...
                finalDim(1), finalDim(2), finalDim(3), refDim(1), refDim(2), refDim(3));
    end
    
    % Verify mask is binary
    maskData = spm_read_vols(hdr_final);
    uniqueVals = unique(maskData(maskData ~= 0));
    if all(ismember(uniqueVals, [0, 1]))
        fprintf('      ✓ BINARY\n\n');
    else
        warning('      ✗ NOT BINARY: contains %s\n\n', mat2str(uniqueVals));
    end
    
catch ME
    warning('      ✗ Error: %s\n\n', ME.message);
    return;
end

end
