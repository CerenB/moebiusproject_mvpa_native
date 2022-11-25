function info = step1Searchlight(opt)


% get the smoothing parameter for 4D map
funcFWHM = opt.funcFWHM;

%% define the mask
% use in output name

if strcmp(opt.mvpa.roiSource, 'wholeBrain')
    
    % mask name to decode
    maskName = 'mask.nii';
    
end

%% set output folder/name
savefileMatName = [opt.taskName, ...
    '_SL_', ...
    opt.mvpa.roiSource, ...
    '_space-', opt.space, ...
    '_FWHM-', num2str(funcFWHM), ...
    '_', opt.mvpa.sphereType, ...
    '-', num2str(opt.mvpa.searchlightVoxelNb), ...
    '_classifier-', opt.mvpa.className, ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat'];

%% let's get going!

% set structure array for keeping the results
info = struct( ...
    'subID', [], ...
    'maskPath', [], ...
    'maskVoxNb', [], ...
    'searchlightVoxelNb', [], ...
    'image', [], ...
    'ffxSmooth', [], ...
    'roiSource', [], ...
    'decodingCondition', [], ...
    'imagePath', []);

count = 1;
iDecodingType = 2;

for iSub = 1:numel(opt.subjects)
    
    % get FFX path
    subID = opt.subjects{iSub};
    
    fprintf(['\n\n\nSub'  subID ' is  being processed ....\n']);
    
    ffxDir = getFFXdir(subID, funcFWHM, opt);
    [~, folderName] = fileparts(ffxDir);
    
    % create folder for output
    resultFolder = fullfile(opt.pathOutput,...
        [folderName,  '_',opt.mvpa.roiSource, ...
        '_', opt.mvpa.sphereType, ...
        '-', num2str(opt.mvpa.searchlightVoxelNb), ...
        '_classifier-', opt.mvpa.className]);
    if ~exist(resultFolder, 'dir')
        mkdir(resultFolder);
    end
    
    % loop through different 4D images
    for iImage = 1:length(opt.mvpa.map4D)
        
        % 4D image
        imageName = ['4D_', opt.mvpa.map4D{iImage}, ...
            '_', num2str(funcFWHM), '.nii'];
        image = fullfile(ffxDir, imageName);
        
        % mask
        mask = fullfile(ffxDir, maskName);
        
        %extract decoding conditions and set stimuli
        [condLabelNb, condLabelName, decodCondNb] = setStimuli(iDecodingType);
        
        for iDecodCondition = 1:decodCondNb
            
            % load cosmo input
            ds = cosmo_fmri_dataset(image, 'mask', mask);
            
            % Getting rid off zeros
            zeroMask = all(ds.samples == 0, 1);
            ds = cosmo_slice(ds, ~zeroMask, 2);
            
            % calculate the mask size
            maskVoxel = size(ds.samples, 2);
            
            % set cosmo structure
            ds = setCosmoStructure(opt, ds, condLabelNb, condLabelName);
            
            % slice the ds according to your targers (choose your
            % train-test conditions
            opt.iDecodCondition = iDecodCondition;
            opt.decodingType = iDecodingType;
            [ds, textCondition] = sliceDataPerCondition(opt, ds);
            
            % remove constant features
            ds = cosmo_remove_useless_data(ds);
            
            % partitioning, for test and training : cross validation
            % can be different e.g. cosmo_oddeven_partitioner(ds_per_run)
            opt.mvpa.partitions = cosmo_nfold_partitioner(ds);
            
            
            % define a neightborhood
            nbrhood = cosmo_spherical_neighborhood(ds, ...
                                                   opt.mvpa.sphereType, ...
                                                   opt.mvpa.searchlightVoxelNb);
            %cosmo_disp(nbrhood);
            
            % Run the searchlight
            svm_results = cosmo_searchlight(ds, ...
                                            nbrhood, ...
                                            opt.mvpa.measure, ...
                                            opt.mvpa);
            
            % store the relevant info
            info(count).subID = subID;
            info(count).maskPath = mask;
            info(count).maskVoxNb = maskVoxel;
            info(count).decodingConditions = textCondition;
            info(count).searchlightVoxelNb = opt.mvpa.searchlightVoxelNb;
            info(count).image = opt.mvpa.map4D{iImage};
            info(count).ffxSmooth = funcFWHM;
            info(count).roiSource = opt.mvpa.roiSource;
            info(count).imagePath = image;
            
            count = count + 1;
            
            % Store results to disc
            savingResultFile = fullfile(resultFolder, ...
                [['sub-', subID], ...
                '_4D-', opt.mvpa.map4D{iImage}, ...
                '_', textCondition, ...
                '_', opt.mvpa.sphereType, ...
                '-', num2str(opt.mvpa.searchlightVoxelNb), ...
                '_', datestr(now, 'yyyymmddHHMM'), '.nii']);
            
            cosmo_map2fmri(svm_results, savingResultFile);
        end
    end
end
%% save output
% mat file
savefileMat = fullfile(resultFolder, savefileMatName);
save(savefileMat, 'info');

end

function ds = setCosmoStructure(opt, ds, condLabelNb, condLabelName)
% sets up the target, chunk, labels by stimuli condition labels, runs,
% number labels.

% design info from opt
nbRun = opt.mvpa.nbRun;
betasPerCondition = opt.mvpa.nbTrialRepetition;

% chunk (runs), target (condition), labels (condition names)
conditionPerRun = length(condLabelNb);
betasPerRun = betasPerCondition * conditionPerRun;

chunks = repmat((1:nbRun)', 1, betasPerRun);
chunks = chunks(:);

targets = repmat(condLabelNb', 1, nbRun)';
targets = targets(:);
targets = repmat(targets, betasPerCondition, 1);

condLabelName = repmat(condLabelName', 1, nbRun)';
condLabelName = condLabelName(:);
condLabelName = repmat(condLabelName, betasPerCondition, 1);

% assign our 4D image design into cosmo ds git
ds.sa.targets = targets;
ds.sa.chunks = chunks;
ds.sa.labels = condLabelName;

% figure; imagesc(ds.sa.targets);

end
