function createExclusiveMasks(opt, maskPairs)
% createExclusiveMasks - Create exclusive masks for multiple subjects
%
% SYNTAX:
%   createExclusiveMasks(opt, maskPairs)
%
% INPUT:
%   opt - Options structure from batchMvpa.m with fields:
%         .subjects  - Cell array of subject IDs (e.g., {'ctrl001', 'ctrl002'})
%         .maskPath  - Base path to ROI masks
%   
%   maskPairs - Cell array of mask pairs to check for overlap. Each element
%               is a cell array with two mask filenames:
%               e.g., {{'L_area3a_3b_binary.nii', 'R_area3a_3b_binary.nii'}, ...
%                      {'L_area4_binary.nii', 'R_area4_binary.nii'}}
%
% DESCRIPTION:
%   Loops through all subjects and creates exclusive versions of specified
%   mask pairs by removing overlapping voxels. Saves results in
%   volumetric_ROIs/exclusiveMasks/<subject>/ directory.
%
% EXAMPLE:
%   % Define mask pairs to process
%   maskPairs = {{'L_area3a_3b_binary.nii', 'R_area3a_3b_binary.nii'}, ...
%                {'L_area4_binary.nii', 'R_area4_binary.nii'}};
%   
%   % Run batch processing
%   createExclusiveMasks(opt, maskPairs);

    fprintf('\n========================================\n');
    fprintf('Batch Creating Exclusive Masks\n');
    fprintf('========================================\n');
    fprintf('Processing %d subjects\n', length(opt.subjects));
    fprintf('Processing %d mask pairs per subject\n', length(maskPairs));
    
    % Loop through subjects
    for iSub = 1:length(opt.subjects)
        subID = opt.subjects{iSub};
        subLabel = ['sub-' subID];
        
        fprintf('\n--- Subject %d/%d: %s ---\n', iSub, length(opt.subjects), subLabel);
        
        % Define subject-specific paths
        inputDir = fullfile(opt.maskPath, 'binary', subLabel);
        outputDir = fullfile(opt.maskPath, 'exclusiveMasks', subLabel);
        
        % Check if input directory exists
        if ~exist(inputDir, 'dir')
            warning('Input directory not found for %s, skipping: %s', subLabel, inputDir);
            continue;
        end
        
        % Loop through mask pairs
        for iPair = 1:length(maskPairs)
            currentPair = maskPairs{iPair};
            
            if length(currentPair) ~= 2
                warning('Mask pair %d must have exactly 2 masks, skipping', iPair);
                continue;
            end
            
            mask1Name = currentPair{1};
            mask2Name = currentPair{2};
            
            fprintf('\nPair %d/%d: %s vs %s\n', iPair, length(maskPairs), mask1Name, mask2Name);
            
            % Full paths to masks
            mask1Path = fullfile(inputDir, mask1Name);
            mask2Path = fullfile(inputDir, mask2Name);
            
            % Check if both masks exist
            if ~exist(mask1Path, 'file')
                warning('  Mask 1 not found: %s', mask1Path);
                continue;
            end
            
            if ~exist(mask2Path, 'file')
                warning('  Mask 2 not found: %s', mask2Path);
                continue;
            end
            
            % Create exclusive masks
            try
                [exclu1, exclu2, info] = makeExclusivePair(mask1Path, mask2Path, outputDir);
                
                fprintf('  Summary:\n');
                fprintf('    Overlapping voxels: %d\n', info.nOverlap);
                fprintf('    %s: %d -> %d voxels\n', mask1Name, ...
                        info.nMask1Original, info.nMask1Exclusive);
                fprintf('    %s: %d -> %d voxels\n', mask2Name, ...
                        info.nMask2Original, info.nMask2Exclusive);
                
            catch ME
                warning('  Failed to process pair: %s', ME.message);
                continue;
            end
        end
    end
    
    fprintf('\n========================================\n');
    fprintf('Batch processing complete!\n');
    fprintf('========================================\n');
    
end


function [mask1_exclu, mask2_exclu, overlapInfo] = makeExclusivePair(mask1_path, mask2_path, outputDir)
% makeExclusivePair - Create exclusive masks by removing overlapping voxels
%
% SYNTAX:
%   [mask1_exclu, mask2_exclu, overlapInfo] = makeExclusivePair(mask1_path, mask2_path, outputDir)
%
% INPUT:
%   mask1_path - Full path to first binary mask (.nii or .nii.gz)
%   mask2_path - Full path to second binary mask (.nii or .nii.gz)
%   outputDir  - Directory where exclusive masks will be saved
%
% OUTPUT:
%   mask1_exclu  - Full path to first exclusive mask
%   mask2_exclu  - Full path to second exclusive mask
%   overlapInfo  - Struct with overlap statistics

    % Create output directory if it doesn't exist
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    
    % Load the two binary masks
    fprintf('Loading masks...\n');
    fprintf('  Mask 1: %s\n', mask1_path);
    hdr1 = spm_vol(mask1_path);
    img1 = spm_read_vols(hdr1);
    
    fprintf('  Mask 2: %s\n', mask2_path);
    hdr2 = spm_vol(mask2_path);
    img2 = spm_read_vols(hdr2);
    
    % Check dimensions match
    if ~isequal(size(img1), size(img2))
        error('makeExclusivePair:dimensionMismatch', ...
              'Mask dimensions do not match: [%s] vs [%s]', ...
              num2str(size(img1)), num2str(size(img2)));
    end
    
    % Count original voxels
    nMask1Original = sum(img1(:) > 0);
    nMask2Original = sum(img2(:) > 0);
    
    fprintf('\nOriginal voxel counts:\n');
    fprintf('  Mask 1: %d voxels\n', nMask1Original);
    fprintf('  Mask 2: %d voxels\n', nMask2Original);
    
    % Find overlapping voxels (where both masks == 1)
    overlap = (img1 > 0) & (img2 > 0);
    nOverlap = sum(overlap(:));
    
    fprintf('\nOverlap detected: %d voxels\n', nOverlap);
    
    if nOverlap > 0
        fprintf('  Removing overlap from both masks...\n');
        % Set overlapping voxels to 0 in both masks
        img1_exclu = img1;
        img2_exclu = img2;
        img1_exclu(overlap) = 0;
        img2_exclu(overlap) = 0;
    else
        fprintf('  No overlap found - masks are already exclusive.\n');
        img1_exclu = img1;
        img2_exclu = img2;
    end
    
    % Count exclusive voxels
    nMask1Exclusive = sum(img1_exclu(:) > 0);
    nMask2Exclusive = sum(img2_exclu(:) > 0);
    
    fprintf('\nExclusive voxel counts:\n');
    fprintf('  Mask 1: %d voxels (removed %d)\n', ...
            nMask1Exclusive, nMask1Original - nMask1Exclusive);
    fprintf('  Mask 2: %d voxels (removed %d)\n', ...
            nMask2Exclusive, nMask2Original - nMask2Exclusive);
    
    % Generate output filenames
    [~, name1, ext1] = fileparts(mask1_path);
    if strcmp(ext1, '.gz')
        [~, name1, ~] = fileparts(name1);
    end
    
    [~, name2, ext2] = fileparts(mask2_path);
    if strcmp(ext2, '.gz')
        [~, name2, ~] = fileparts(name2);
    end
    
    % Add '_exclusive' suffix (keep '_binary' if present)
    outName1 = [name1, '_exclusive.nii'];
    outName2 = [name2, '_exclusive.nii'];
    
    mask1_exclu = fullfile(outputDir, outName1);
    mask2_exclu = fullfile(outputDir, outName2);
    
    % Save exclusive masks
    fprintf('\nSaving exclusive masks...\n');
    fprintf('  %s\n', mask1_exclu);
    hdr1_out = hdr1;
    hdr1_out.fname = mask1_exclu;
    spm_write_vol(hdr1_out, img1_exclu);
    
    fprintf('  %s\n', mask2_exclu);
    hdr2_out = hdr2;
    hdr2_out.fname = mask2_exclu;
    spm_write_vol(hdr2_out, img2_exclu);
    
    % Prepare output info
    overlapInfo.nOverlap = nOverlap;
    overlapInfo.nMask1Original = nMask1Original;
    overlapInfo.nMask2Original = nMask2Original;
    overlapInfo.nMask1Exclusive = nMask1Exclusive;
    overlapInfo.nMask2Exclusive = nMask2Exclusive;
    
    fprintf('\n✓ Exclusive masks created successfully!\n');
    
end
