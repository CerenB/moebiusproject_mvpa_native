function roiInfo = combineMasks(roiPath)

masksNames = {'space-MNI_label-lhsomato3a_mask.nii', ...
    'space-MNI_label-rhsomato3a_mask.nii', ...
    'space-MNI_label-lhsomato3b_mask.nii', ...
    'space-MNI_label-rhsomato3b_mask.nii'};



for iMask = 1:2
    
    hdr1 = spm_vol(fullfile(roiPath,masksNames{iMask}));
    img1 = spm_read_vols(hdr1);
    
    hdr2 = spm_vol(fullfile(roiPath,masksNames{iMask+2}));
    img2 = spm_read_vols(hdr2);
    
    
    % open a template to save these parcels into 1 image
    hdr = hdr1;
    temp = img1 + img2;
    a = temp(temp > 1); % empty

    % if a is not empty, put the temp >>2 into 1s
    
    % rename & save
    p = bids.internal.parse_filename(spm_file(masksNames{iMask}, 'filename'));
    
    entities = struct('hemi', p.entities.label(1), ...
        'space', 'MNI', ...
        'label', p.entities.label(3:end-1));
    
    nameStructure = struct('entities', entities, ...
        'suffix', 'mask', ...
        'ext', '.nii', ...
        'use_schema', false);
    
    newName = bids.create_filename(nameStructure);
    hdr.fname = spm_file(hdr.fname, 'filename', newName);
    
    % save
    spm_write_vol(hdr, temp);
    
    % voxel number
    roiInfo(iMask).name = newName;
    roiInfo(iMask).voxelNb = sum(temp(:) == 1);
end

end