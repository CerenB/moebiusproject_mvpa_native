function extractDSM(opt,roiSource)
% this function extracts from defined ROI, RSA dissimilarity matrices for each subject

% example call : extract_DSM(opt,1)
% DSM


% 12.10.2022 CB refactoring on for moebius project 

%% set things up

                            
% get the smoothing parameter for 4D map
funcFWHM = opt.funcFWHM;

% choose masks to be used
opt = chooseMask(opt, roiSource);

                            
% define output path
outputPath = fullfile(opt.pathOutput,'RSA');
if ~exist(outputPath, 'dir')
        mkdir(outputPath);
end


% define targets, labels, ... for 4D maps
decodingType = 1;
[condLabelNb, condLabelName, ~] = setStimuli(decodingType);
[targets, chunks, labels] = setTargetChunksLabels(opt, ...
                                                  condLabelNb, ...
                                                  condLabelName);

% slicing into 5 body parts:                                            
slicingCondition = 1;
% note: decodingtype =3 & slicingCondition =1 would slice data into 6
% bodyparts (6th being forehead2)

        for iMask = 1:length(opt.maskName)
            for iImage = 1:length(opt.mvpa.map4D)
                for iSub = 1:numel(opt.subjects)
                    
                    % get FFX path
                    subID = opt.subjects{iSub};
                    ffxDir = getFFXdir(subID, funcFWHM, opt);
                    
                    
                    % 4D image
                    imageName = ['4D_', opt.mvpa.map4D{iImage}, '_', num2str(funcFWHM), '.nii'];
                    image = fullfile(ffxDir, imageName);
                    
                    
                    % choose the mask
                    mask = fullfile(opt.maskPath, opt.maskName{iMask});
                    
                    % display the used mask
                    disp(opt.maskName{iMask});
                    
                    %% put everything inside here
                    
                    ds = cosmo_fmri_dataset(image, ...
                        'mask',mask,...
                        'targets',targets,...
                        'chunks',chunks);
                    
                    ds.sa.labels = labels;
                    
                    % % compute average for each unique target, so that the dataset has X
                    % % samples - one for each target
                    ds=cosmo_fx(ds, @(x)mean(x,1), 'targets', 1);
                    
                    % % demeaning them
                    % meanPattern = mean(ds.samples,2);  % get the mean for every pattern
                    % meanPattern = repmat(meanPattern,1,size(ds.samples,2)); % make a matrix with repmat
                    % ds.samples  = ds.samples - meanPattern; % remove the mean from every every point in each pattern
                    
                    opt.iDecodCondition = slicingCondition;
                    opt.decodingType = decodingType;
                    [ds, slicingCategory] = sliceDataPerCondition(opt, ds);

                    % remove constant features
                    ds=cosmo_remove_useless_data(ds);
                    
                    % simple sanity check to ensure all attributes are set properly
                    cosmo_check_dataset(ds);
                    
                    % Use pdist (or cosmo_pdist) with 'correlation' distance to get DSMs
                    % in vector form.
                    dsm = pdist(ds.samples, 'correlation');
                    % get the euclidean distance
                    dsmEuc = pdist(ds.samples);
                    % get standardized euclidean distance by dividing to
                    % standard deviation
                    dsmSeuc = pdist(ds.samples, 'seuclidean');
                    
                    %%%%%%%%%%%
                    % add ROI/IMAGE/ saving structure
                    % save into matrix according to the groups
                    contVec(iSub,:) = dsm;
                    contVecEuc(iSub,:) = dsmEuc;
                    contVecSeuc(iSub,:) = dsmSeuc;

                    
                end
                
                %create a mean vector of all the sub values, and ive the matrix form
                contMeanDsm = squareform(mean(contVec));
                
                %% Save the mat fil with all the brain DSMs
                saveRoiName = opt.maskName{iMask}(1:end-9);
                saveOutputName = fullfile(outputPath, ...
                    [opt.taskName, ...
                    '_DSM_', ...
                    saveRoiName, '_', ...
                    'image-', opt.mvpa.map4D{iImage}, ...
                    '_Slicing-', slicingCategory, ...
                    '_s-', num2str(funcFWHM), ...
                    '.mat']);
                
                save (saveOutputName,...
                    'contVec','contMeanDsm', 'contVecEuc', 'contVecSeuc');

                
            end
        end

end