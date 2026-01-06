function [opt] = chooseMask(opt, roiSource, subID)

% this is a switch case, according to the action, we choose with ROIs to be
% used

% Sources handled:
% - spmanat: SPM Anatomy atlas (MNI)
% - hcpex: HCPex atlas (MNI)
% - glassier: subject-specific Glasser masks in T1w space (binary)
% - glassierExclusive: subject-specific Glasser exclusive masks (no overlap)
% - bspline / nearest: subject-specific resliced MNI masks (interp choice)
% - probability: precomputed group probability masks (thresholded, pooled)
% - balanced: precomputed balanced group mask (threshold met in each group)


if nargin < 3
    subID = [];
end

subID = ['sub-' subID];  % Construct subID here

switch lower(roiSource)
    

    case 'spmanat'
        
        opt.maskPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
                                '..', '..', '..', 'derivatives', 'roi', ...
                                'atlases', 'spmAnatomy');
        
        % masks to decode/use
        opt.maskName = {'hemi-l_space-MNI_label-somato3_mask.nii', ...
                        'hemi-r_space-MNI_label-somato3_mask.nii'};
        
        % use in output roi name
        opt.maskLabel = {'leftCombined', 'rightCombined'};
        
    case 'hcpex'
        
        opt.maskPath = fullfile(opt.dir.roi, 'group','allRois');
        
        opt.maskName = spm_select('FPlist', ...
                                  opt.maskPath, ...
                                  '.*space-.*_mask.nii$');
        opt.maskName = cellstr(opt.maskName);
        
    case 'glassier'
        
        % Check if subID was provided
        if isempty(subID)
            error('chooseMask:missingSubID', ...
                  'subID is required when using glassier ROI source');
        end
        
        % Build path to subject-specific mask folder        
        % Only select files containing 'binary' in the filename
        opt.maskName = spm_select('FPlist', ...
                                  fullfile(opt.maskPath, 'binary', subID), ...
                                  '.*binary.*\.nii(\.gz)?$');
        opt.maskName = cellstr(opt.maskName);
        
        % Extract labels from filenames for output
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), opt.maskName, 'UniformOutput', false);
        
    case 'glassierexclusive'
        
        % Check if subID was provided
        if isempty(subID)
            error('chooseMask:missingSubID', ...
                  'subID is required when using glassierExclusive ROI source');
        end
        
        % Build path to subject-specific exclusive masks folder        
        % Only select files containing 'exclusive' in the filename
        opt.maskName = spm_select('FPlist', ...
                                  fullfile(opt.maskPath, 'exclusiveMasks', subID), ...
                                  '.*exclusive.*\.nii(\.gz)?$');
        opt.maskName = cellstr(opt.maskName);
        
        % Extract labels from filenames for output
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), opt.maskName, 'UniformOutput', false);
        
    case {'bspline','nearest'}
        % Subject-specific MNI-space masks; folder chosen by roiSource
        if isempty(subID) || strcmp(subID, 'sub-')
            error('chooseMask:missingSubID', ...
                  'subID is required when using bspline/nearest ROI source');
        end
        interpFolder = lower(roiSource); % 'bspline' or 'nearest'
        % you need to take resliced masks
        subjDir = fullfile(opt.maskPath, interpFolder, subID, 'resliced');
        if ~exist(subjDir, 'dir')
            error('chooseMask:missingDir', 'Mask directory not found: %s', subjDir);
        end
        opt.maskName = spm_select('FPlist', subjDir, '.*\.nii(\.gz)?$');
        opt.maskName = cellstr(opt.maskName);
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), opt.maskName, 'UniformOutput', false);

    case 'probability'
        % Group-level probability masks at configured threshold (may be multiple per ROI base)
        if ~isfield(opt, 'probMaskDir') || isempty(opt.probMaskDir)
            error('chooseMask:missingProbDir', 'opt.probMaskDir must be set for prob50 roiSource');
        end
        if ~isfield(opt, 'groupMvpa') || ~isfield(opt.groupMvpa, 'condition')
            error('chooseMask:missingCondition', 'opt.groupMvpa.condition is required for prob50 roiSource');
        end
        pct = defaultProbPct(opt);
        condStr = strrep(opt.groupMvpa.condition, ' ', '');
        pat = sprintf('probMap_%s_.*_%dpct_binary\.nii$', condStr, pct);
        files = spm_select('FPlist', opt.probMaskDir, pat);
        files = cellstr(files);
        if isempty(files)
            error('chooseMask:missingProbMask', 'No probability masks matching pattern in %s', opt.probMaskDir);
        end
        opt.maskName = files;
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), files, 'UniformOutput', false);

    case 'balanced'
        % Balanced mask: voxel present in thresholded maps of every group
        if ~isfield(opt, 'probMaskDir') || isempty(opt.probMaskDir)
            error('chooseMask:missingProbDir', 'opt.probMaskDir must be set for balanced roiSource');
        end
        if ~isfield(opt, 'groupMvpa') || ~isfield(opt.groupMvpa, 'condition')
            error('chooseMask:missingCondition', 'opt.groupMvpa.condition is required for balanced roiSource');
        end
        pct = defaultProbPct(opt);
        condStr = strrep(opt.groupMvpa.condition, ' ', '');
        pat = sprintf('probMap_group-balanced_%s_.*_%dpct_binary\.nii$', condStr, pct);
        files = spm_select('FPlist', opt.probMaskDir, pat);
        files = cellstr(files);
        if isempty(files)
            error('chooseMask:missingBalancedMask', 'No balanced mask found in %s', opt.probMaskDir);
        end
        opt.maskName = files;
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), files, 'UniformOutput', false);

end


end

function pct = defaultProbPct(opt)
    % Derive probability threshold percent from opt
    if isfield(opt, 'probThreshold') && ~isempty(opt.probThreshold)
        pct = round(opt.probThreshold * 100);
    else
        pct = 50;
    end
end

function label = extractMaskLabel(filename)
    % Extract hemisphere and area from filename
    % Handles multiple formats:
    %   'L_area3a_3b.nii.gz' -> hemi='L', area='area3a_3b'
    %   'probMap_group-balanced_hand_L_area3a_3b_2_1_50pct_binary.nii' -> hemi='L', area='area3a_3b_2_1'
    [~, name, ~] = fileparts(filename);
    if endsWith(name, '.nii')
        name = name(1:end-4);
    end
    
    % Try regex pattern for probability/balanced masks: _[LR]_<area>_\d+pct_binary
    hemiAreaMatch = regexp(name, '_([LR])_(.+?)_(\d+pct_binary)$', 'tokens');
    
    if ~isempty(hemiAreaMatch)
        % Probability or balanced mask format
        label.hemi = hemiAreaMatch{1}{1};  % 'L' or 'R'
        label.area = hemiAreaMatch{1}{2};  % e.g., 'area3a_3b_2_1'
        label.full = name;
    else
        % Try simple format: L_<area> or R_<area>
        parts = strsplit(name, '_');
        if length(parts) >= 2 && (strcmp(parts{1}, 'L') || strcmp(parts{1}, 'R'))
            label.hemi = parts{1};
            label.area = strjoin(parts(2:end), '_');
            label.full = name;
        else
            % Fallback if format is unexpected
            label.hemi = '';
            label.area = name;
            label.full = name;
        end
    end
end