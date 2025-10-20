function [opt] = chooseMask(opt, roiSource)

% this is a switch case, according to the action, we choose with ROIs to be
% used

% action 1: atlas SPM Anatomy - MNI
% action 2: atlas HCPex - MNI
% action 3: 
% action 4: 

switch lower(roiSource)
    

    case 'spmanat'
        
        opt.maskPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
                                '..', '..', '..', 'derivatives', 'roi', ...
                                'atlases', 'spmAnatomy');
        
        % masks to decode/use
        opt.maskName = {'hemi-l_space-MNI_label-somato3_mask.nii', ...
                        'hemi-r_space-MNI_label-somato3_mask.nii'};
        % opt.maskName = {'space-MNI_label-lhsomato3a_mask.nii', ...
%                         'space-MNI_label-rhsomato3a_mask.nii', ...
%                         'space-MNI_label-lhsomato3b_mask.nii', ...
%                         'space-MNI_label-rhsomato3b_mask.nii'};
        
        % use in output roi name
        opt.maskLabel = {'leftCombined', 'rightCombined'};
        
%         opt.maskLabel = {'leftSoma3a', 'rightSoma3a', 'leftSoma3b', ...
%                         'rightSoma3b'};
    case 'hcpex'
        
        opt.maskPath = fullfile(opt.dir.roi, 'group','allRois');
        
        opt.maskName = spm_select('FPlist', ...
                                  opt.maskPath, ...
                                  '.*space-.*_mask.nii$');
        opt.maskName = cellstr(opt.maskName);
end


end