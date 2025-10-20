function accu = calculateMvpa(opt, roiSource)

% main function which loops through masks and subjects to calculate the
% decoding accuracies for given conditions.
% dependant on SPM + CPP_SPM and CosMoMvpa toolboxes
% the output is compatible for R visualisation, it gives .csv file as well
% as .mat file

% get the smoothing parameter for 4D map
funcFWHM = opt.funcFWHM;

% choose masks to be used
opt = chooseMask(opt, roiSource);

%% set output folder/name
savefileMat = fullfile(opt.pathOutput, ...
    [opt.taskName, ...
    'Decoding_', ...
    roiSource, ...
    '_s', num2str(funcFWHM), ...
    '_ratio', num2str(opt.mvpa.ratioToKeep), ...
    '_', datestr(now, 'yyyymmddHHMM'), '.mat']);

savefileCsv = fullfile(opt.pathOutput, ...
    [opt.taskName, ...
    'Decoding_', ...
    roiSource, ...
    '_s', num2str(funcFWHM), ...
    '_ratio', num2str(opt.mvpa.ratioToKeep ), ...
    '_', datestr(now, 'yyyymmddHHMM'), '.csv']);

%% let's get going!

% set structure array for keeping the results
accu = struct( ...
    'subID', [], ...
    'mask', [], ...
    'accuracy', [], ...
    'maskVoxNb', [], ...
    'choosenVoxNb', [], ...
    'image', [], ...
    'ffxSmooth', [], ...
    'roiSource', [], ...
    'permutation', [], ...
    'prediction', [], ...
    'imagePath', []);

count = 1;
for iDecodingType = opt.decodingType
    for iSub = 1:numel(opt.subjects)
        
        % get FFX path
        subID = opt.subjects{iSub};
        ffxDir = getFFXdir(subID, funcFWHM, opt);
        
        % update runNb with problematic subjects
        opt.mvpa.nbRun = updateRunNumber(subID, opt.taskName, opt.mvpa.nbRun);
        
        for iImage = 1:length(opt.mvpa.map4D)
            
            for iMask = 1:length(opt.maskName)
                
                % choose the mask
                %mask = fullfile(opt.maskPath, opt.maskName{iMask});
                mask = fullfile(opt.maskName{iMask});

                % display the used mask
                p = bids.internal.parse_filename(spm_file(mask, 'filename'));
                disp(p.filename);
                
                % 4D image
                imageName = ['4D_', opt.mvpa.map4D{iImage}, '_', num2str(funcFWHM), '.nii'];
                image = fullfile(ffxDir, imageName);
                
                %extract decoding conditions and set stimuli
                [opt.mvpa.condLabelNb, opt.mvpa.condLabelName, ...
                    decodCondNb] = setStimuli(iDecodingType);
                opt.decodingType = iDecodingType;
                
                for iDecodCondition = 1:decodCondNb
                    
                    % load cosmo input
                    ds = cosmo_fmri_dataset(image, 'mask', mask);
                    
                    % Getting rid off zeros
                    zeroMask = all(ds.samples == 0, 1);
                    ds = cosmo_slice(ds, ~zeroMask, 2);
                    
                    % set cosmo structure
                    ds = setCosmoStructure(opt, ds);
                    
                    % slice the ds according to your targers (choose your
                    % train-test conditions
                    opt.iDecodCondition = iDecodCondition;
                    [ds, textCondition] = sliceDataPerCondition(opt, ds);
                                        
                    % remove constant features
                    ds = cosmo_remove_useless_data(ds);
                    
                    % calculate the mask size
                    maskVoxel = size(ds.samples, 2);
                    
                    % partitioning, for test and training : cross validation
                    partitions = cosmo_nfold_partitioner(ds);
                    
                    % use the ratios, instead of the voxel number:
                    opt.mvpa.feature_selection_ratio_to_keep = opt.mvpa.ratioToKeep;
                    
                    
                    % want to still run mvpa although the mask is smaller than desired
                    % vx number?
                    if opt.mvpa.useMaskVoxelNumber
                        if maskVoxel < opt.mvpa.ratioToKeep
                            opt.mvpa.feature_selection_ratio_to_keep = maskVoxel;
                        end
                    end
                    
                    
                    % ROI mvpa analysis
                    [pred, accuracy] = cosmo_crossvalidate(ds, ...
                        @cosmo_classify_meta_feature_selection, ...
                        partitions, opt.mvpa);
                                 
                    %% store output
                    accu(count).subID = subID;
                    accu(count).decodingConditions = textCondition;
                   % accu(count).mask = opt.maskLabel{iMask};
                   accu(count).mask = p.filename;
                   accu(count).maskLabel = p.entities.label;
                   accu(count).maskHemi = p.entities.hemi;
                    accu(count).maskVoxNb = maskVoxel;
                    accu(count).choosenVoxNb = opt.mvpa.feature_selection_ratio_to_keep;
                    accu(count).image = opt.mvpa.map4D{iImage};
                    accu(count).ffxSmooth = funcFWHM;
                    accu(count).accuracy = accuracy;
                    accu(count).prediction = pred;
                    accu(count).imagePath = image;
                    accu(count).roiSource = roiSource;
                    
                    %% PERMUTATION PART
                    if opt.mvpa.permutate  == 1
                        [acc0] = permuteAccuracy(ds,accuracy, partitions, opt.mvpa);
                        accu(count).permutation = acc0';
                    end
                    
                    % increase the counter and allons y!
                    count = count + 1;
                    
                    fprintf(['Sub'  subID ' - area: ' p.entities.label ...
                        ', accuracy: ' num2str(accuracy), ...
                        ' - condition: ' textCondition '\n\n\n']);
                end
            end
        end
    end
    %% save output
    
    % mat file
    save(savefileMat, 'accu');
    
    % csv but with important info for plotting
    csvAccu = rmfield(accu, 'permutation');
    csvAccu = rmfield(csvAccu, 'prediction');
    csvAccu = rmfield(csvAccu, 'imagePath');
    writetable(struct2table(csvAccu), savefileCsv);
    
end
end

