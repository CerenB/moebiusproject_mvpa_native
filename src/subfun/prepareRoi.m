function [roiName] = prepareRoi(opt, binaryMap, dataImage)

if opt.reslice.do
    % If needed reslice probability map to have same resolution as the data image
    %
    % resliceImg won't do anything if the 2 images have the same resolution
    %
    % if you read the data with spm_summarise,
    % then the 2 images do not need the same resolution.
    binaryMap = resliceRoiImages(dataImage, binaryMap);
end

roiName = removeSpmPrefix(binaryMap, spm_get_defaults('realign.write.prefix'));

end