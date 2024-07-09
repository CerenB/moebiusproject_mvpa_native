function step2SmoothSLMaps(condition, maps, funcFWHM2Level)

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Step 1 was running searchlight analysis
  % Here is Step 2, smoothing the SL result maps

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % maps = 'beta'% 't_maps';
  % funcFWHM = 0 %  2;
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  opt = getOptionSearchlight();

  if nargin < 2 

    maps = opt.mvpa.map4D{2};
    funcFWHM2Level = 8;

  end

  % get the smoothing of 4D images
  funcFWHM = opt.funcFWHM;

  % make the prefix for SL output files
  prefixSmooth = [spm_get_defaults('smooth.prefix'), num2str(funcFWHM2Level), '_'];

  % get the .nii files
  % dummy call for ffxDir
  ffxDir = getFFXdir(opt.subjects{1}, funcFWHM, opt);  
  [~, folderName] = fileparts(ffxDir);

  % get the folder name to pick files from
  resultFolder = fullfile(opt.pathInput,...
                           [folderName,  '_',opt.mvpa.roiSource, ...
                           '_', opt.mvpa.sphereType, ...
                           '-', num2str(opt.mvpa.searchlightVoxelNb), ...
                           '_classifier-', opt.mvpa.className]);
                       
  midFilePattern = ['4D-', maps, ...
                    '_', condition, '_', ...
                    opt.mvpa.sphereType, '-', num2str(opt.mvpa.searchlightVoxelNb),...
                    '*.nii'];
  
  % define where the sl files are
  slNiiFile = dir(fullfile(resultFolder,['*_', midFilePattern])); %^sub-
  slNiiFile([slNiiFile.isdir]) = [];

  
  % get rid of the nans
  fprintf('Converting zero values to nans\n\n');
  
  for iSub = 1:numel(opt.subjects)

    % prepare subject full file for spm input
    subName = [slNiiFile(iSub).name];
    subFullPath = fullfile(resultFolder, subName);

    % convert 0 to nan in .nii files
    tmp = load_nii(subFullPath);
    tmp.img(tmp.img == 0) = nan;
    save_nii(tmp, subFullPath);

    % save the path +nii files for spm smoothing
    subjFullfile{iSub, 1} = subFullPath; %#ok<AGROW>

  end

  % Check the number of subjects corresponds to number of files
  fprintf('\n\nNumber of Subjects = %.0f \n\n', numel(opt.subjects));

  disp('Files:');
  for iFile = 1:length(slNiiFile)
    disp([slNiiFile(iFile).name]);
  end
  fprintf('\n\nNumber of Files = %.0f \n\n', length(slNiiFile));

  %% spm batch for smoothing

  spm('defaults', 'fmri');
  spm_jobman('initcfg');

  matlabbatch = [];
  matlabbatch{1}.spm.spatial.smooth.data = subjFullfile;
  matlabbatch{1}.spm.spatial.smooth.fwhm = [funcFWHM2Level funcFWHM2Level funcFWHM2Level];
  matlabbatch{1}.spm.spatial.smooth.dtype = 0;
  matlabbatch{1}.spm.spatial.smooth.im = 1;
  matlabbatch{1}.spm.spatial.smooth.prefix = prefixSmooth;

  %   spm_jobman('run', matlabbatch);

  %% smooth it
  %    matlabbatch = [];
  %    matlabbatch = setBatchSmoothing(matlabbatch, ...
  %                                       subjFullfile, ...
  %                                       funcFWHM2Level, ...
  %                                       prefixSmooth);
  spm_jobman('run', matlabbatch);

 % cd(pathInput);

end
