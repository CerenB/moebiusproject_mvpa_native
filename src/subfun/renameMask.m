function outputImage = renameMask(inputImage)
  %
  % give a HMAT mask a name that is more bids friendly
  %
  % USAGE::
  %
  %   outputImage = renameMask(inputImage)
  %
  % EXAMPLE::
  %
  %   inputImage = fullfile(pwd, 'HMAT_Left_preSMA.nii');
  %   outputImage = renameMask(inputImage);
  %
  %   outputImage
  %   >>
  %     fullfile(pwd, 'space-MNI_label-rhHMATpreSMA_mask.nii.gz');
  %
  %
  % (C) Copyright 2021 CPP ROI developers

  p.filename = spm_file(inputImage, 'filename');
  p.suffix = 'mask';
  p.ext = '.nii';
  if strcmp(spm_file(inputImage, 'ext'), 'gz')
    p.ext = [p.ext '.gz'];
  end
 
  p.entities.space = 'MNI';

  basename = spm_file(inputImage, 'basename');
  parts = strsplit(basename, '_');
  
  hemisph = 'lh';
  if strcmp(parts{4}, 'R')
      hemisph = 'rh';
  end
      
  p.entities.label = [hemisph 'somato' parts{3}];

  p.use_schema = false;

  newName = bids.create_filename(p);

  outputImage = spm_file(inputImage, 'filename', newName);

  movefile(inputImage, outputImage);

end