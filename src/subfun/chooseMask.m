function [opt] = chooseMask(opt, roiSource, subID)

% this is a switch case, according to the action, we choose with ROIs to be
% used

% action 1: atlas SPM Anatomy - MNI
% action 2: atlas HCPex - MNI
% action 3: glassier atlas - T1w space
% action 4: glassierExclusive - T1w space, exclusive masks with no overlap

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
        subjDir = fullfile(opt.maskPath, interpFolder, subID);
        if ~exist(subjDir, 'dir')
            error('chooseMask:missingDir', 'Mask directory not found: %s', subjDir);
        end
        opt.maskName = spm_select('FPlist', subjDir, '.*\.nii(\.gz)?$');
        opt.maskName = cellstr(opt.maskName);
        opt.maskLabel = cellfun(@(x) extractMaskLabel(x), opt.maskName, 'UniformOutput', false);

end


end

function label = extractMaskLabel(filename)
    % Extract hemisphere and area from filename
    % e.g., 'L_area3a_3b.nii.gz' -> struct with hemi='L', area='area3a_3b'
    [~, name, ~] = fileparts(filename);
    if endsWith(name, '.nii')
        name = name(1:end-4);
    end
    
    % Split by underscore
    parts = strsplit(name, '_');
    
    if length(parts) >= 2
        label.hemi = parts{1};  % 'L' or 'R'
        label.area = strjoin(parts(2:end), '_');  % 'area3a_3b' or 'area4', etc.
        label.full = name;  % Keep full name too
    else
        % Fallback if format is unexpected
        label.hemi = '';
        label.area = name;
        label.full = name;
    end
end