function extract_DSM(slicing,action)
% this function extracts from defined ROI, RSA dissimilarity matrices for each subject

% example call : extract_DSM(3,1) %includes both Motion & Static conditions in
% DSM
% action 2 plots the DSM figures and runs a correlation between the group
% rois

% 12.10.2022 CB refactoring on for moebius project 

%% set Path
% add cosmo path only in pc 3 option

mainPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
                                '..', '..', '..', 'derivatives');
roiPath = fullfile(fileparts(mfilename('fullpath')), '..', ...
                                '..', '..', '..', 'derivatives', 'roi', ...
                                'atlases', 'spmAnatomy');

% define output path
outputPath = fullfile(mainPath,'RSA');


% cosmo
cosmo = '~/Documents/MATLAB/CoSMoMVPA';
addpath(genpath(cosmo));
cosmo_warning('once');
% libsvm
libsvm = '~/Documents/MATLAB/libsvm';
addpath(genpath(libsvm));
% verify it worked:
cosmo_check_external('libsvm'); % should not give an error






% set subjects
subAll = {'NiFe','PiFo','AnDe','AnPa','ArRa','JePa','LuAn','MaPe',...
    'SiDa','AnBa','StMa','SaKo','ChSc','MiBo','SaFr','GiCo',...
    'DaPr','EkDe','ElLe','FrRe','GiMa','PrKn','RoBo',...
    'ToLa','VaOc','TeVi','AlSa','DaCe','MiGa','MiAr','LuTu',...
    'LaGa'};

% define targets, labels, ... for 4D maps
runNb = 12;
stimNb = 1:8;
labels= {'Left', 'Right', 'Down', 'Up','SLeft','SRight','SDown','SUp'};

% set the stimuli space in cosmoMVPA style
chunks = (1:runNb)';
chunks = repmat(chunks,length(stimNb),1);
targets = repmat(stimNb',1,runNb)';
targets = targets(:);
labels = repmat(labels',1,runNb)';
labels = labels(:);


% read the masks
fnames = dir(fullfile(roiPath,roiName));
% if data is in SSD, then checkpoint for ghost file
count = 1;
for iFile = 1:length(fnames)
    if ~startsWith(fnames(iFile).name,'._')
        roiAll{count} = fnames(iFile).name; %#ok<AGROW>
        count = count +1;
    end
end

switch action
    case 1
        for iRoi = 1:length(roiAll)
            for iSub =1:length(subAll)
                
                %define subject
                sub = subAll{iSub};
                
                if iSub<=16
                    group = 'EB'; else group = 'CONT'; end %#ok<SEPEX>
                
                if strcmp(sub,'ArRa')
                    subject4D = fullfile(mainPath,group,sub,'/Run2/FFX_MVPA_s2/s2_4D_t_maps.nii');
                else
                    subject4D = fullfile(mainPath,group,sub,'/Run1/FFX_MVPA_s2/s2_4D_t_maps.nii');
                end
                
                %define brain mask
                maskName = roiAll{iRoi};
                mask = strcat(roiPath,maskName);
                
                %% put everything inside here
                                
                ds = cosmo_fmri_dataset(subject4D, ...
                    'mask',mask,...
                    'targets',targets,...
                    'chunks',chunks);
                
                ds.sa.labels = labels;
                
                % % compute average for each unique target, so that the dataset has 24
                % % samples - one for each target
                ds=cosmo_fx(ds, @(x)mean(x,1), 'targets', 1);
                
%                 % demeaning them
%                 meanPattern = mean(ds.samples,2);  % get the mean for every pattern
%                 meanPattern = repmat(meanPattern,1,size(ds.samples,2)); % make a matrix with repmat
%                 ds.samples  = ds.samples - meanPattern; % remove the mean from every every point in each pattern
% 
%             
                % only take the motion stimuli presented data, slicing:
                % default is set to 3, so no slicing
                if slicing == 1
                    ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4) ;
                elseif slicing == 2
                    ds = cosmo_slice(ds,ds.sa.targets == 5 | ds.sa.targets == 6 |ds.sa.targets == 7 | ds.sa.targets == 8) ;
                else
                end
                
                % remove constant features
                ds=cosmo_remove_useless_data(ds);
                
                % simple sanity check to ensure all attributes are set properly
                cosmo_check_dataset(ds);
                
                % Use pdist (or cosmo_pdist) with 'correlation' distance to get DSMs
                % in vector form. 
                dsm = pdist(ds.samples, 'correlation');
                % get the euclidean distance
                dsm_euc = pdist(ds.samples);
                % get standardized euclidean distance by dividing to
                % standard deviation
                dsm_seuc = pdist(ds.samples, 'seuclidean');

                % save into matrix according to the groups
                if strcmp(group, 'CONT')
                    SC_vec(iSub-16,:) = dsm;
                    SC_vec_euc(iSub-16,:) = dsm_euc;
                    SC_vec_seuc(iSub-16,:) = dsm_seuc;
                else
                    EB_vec(iSub,:) = dsm;
                    EB_vec_euc(iSub,:) = dsm_euc;
                    EB_vec_seuc(iSub,:) = dsm_seuc;
                end
                
            end
            
            %create a mean vector of all the sub values, and ive the matrix form
            meanEB_dsm = squareform(mean(EB_vec));
            meanSC_dsm = squareform(mean(SC_vec));
            
            %% Save the mat fil with all the brain DSMs
            saveRoiName = maskName(1:7);
            saveOutputName = fullfile(outputPath, ...
                                     [saveRoiName, '_', ...
                                     datestr(now, 'yyyymmddHHMM'),...
                                     '_dsm.mat']);
            save (saveOutputName,...
                 'SC_vec','meanSC_dsm', 'SC_vec_euc', 'SC_vec_seuc', ...
                 'EB_vec','meanEB_dsm', 'EB_vec_euc', 'EB_vec_seuc');

        end

    case 2  
        %% plot the DSM
        cd (outputPath)
        
        labels= {'Left', 'Right', 'Down', 'Up','Left','Right','Down','Up'};
        
        % read the DSM in the folder
        dsm_names = dir('*dsm.mat'); % V5_6mm_2 PT_6mm_mo
        for iDSM = 1:length(dsm_names)
            dsm{iDSM} = dsm_names(iDSM).name;
        end
        
        % load the DSM by 1 by 1
        for iDSM = 1:length(dsm)
            load(dsm{iDSM})
            temp = dsm_names(iDSM).name;
            
            group = temp(1:2);
            roi_name = temp(4:6);
            
            if strcmp(group, 'EB')
                fig_dsm = meanEB_dsm;
            else
                fig_dsm = meanSC_dsm;
            end
            
            figure;
            H= imagesc(fig_dsm);
            titleme = [group,' ', roi_name,' '];
            title(titleme);
            set(gca,'XTick',1:length(fig_dsm),'XAxisLocation', 'top','XTickLabel',labels,'FontSize', 14,...
                'YTick',1:length(fig_dsm),'YTickLabel',labels,'FontSize', 14,'TickLength',[0 0]);
            
           % colormap(jet)
            c= colorbar();
            set(c, 'YTick', [0 1]); % In this example, just use three ticks for illustation
            caxis([0 1])
           saveas(H,[outputPath,titleme,'Figure_default.pdf'])
            
        end
        
        
        %% correlation between mean DSMs
        count = 1;
        results = struct();
        results2 = struct();
        % load the DSM by 1 by 1
        for iDSM = 1:(length(dsm)/2)
            load(dsm{iDSM})
            temp = dsm_names(iDSM).name;
            
            group = temp(1:2);
            roi_name = temp(4:6);
            
            load(strcat('SC',temp(3:end)))
            
            %% correlate the groups
            % mean them
            SC_meanDSM = mean(SC_vec(1:16,:)); %average the subject(rows)
            EB_meanDSM = mean(EB_vec(1:16,:)); %average the subject(rows)
            
            %rho = corr(meanEB_dsm', meanSC_dsm');
           % rho = corr(SC_meanDSM', EB_meanDSM');
           
            rho = corrcoef(SC_meanDSM, EB_meanDSM);
            %take fisher transform
            ztan = atanh(rho(2));
            
            fprintf('Correlation in %s, EB - SC is %.3f\n',roi_name, rho(2));
            
            results(iDSM).name = roi_name;
            results(iDSM).CorrCoef = rho(2);
            results(iDSM).zTrans = ztan;
            
            %% correlate the regions
            %hold already loaded ones, roi 1 = PT
            roi1_SC_meanDSM = SC_meanDSM;
            roi1_EB_meanDSM = EB_meanDSM;
            
            %load the opposite regions' dsm
            load(strcat('EB_',roi_name(1:end-2),'V5',temp(7:end)));
            load(strcat('SC_',roi_name(1:end-2),'V5',temp(7:end)));
            
            % take the mean of opposite regions' dsm, roi 2 = V5
            roi2_SC_meanDSM = mean(SC_vec(1:16,:)); %average the subject(rows)
            roi2_EB_meanDSM = mean(EB_vec(1:16,:)); %average the subject(rows)
            
            %correlate with the held ones
            rho_regionSC = corrcoef(roi2_SC_meanDSM, roi1_SC_meanDSM);
            rho_regionEB = corrcoef(roi2_EB_meanDSM, roi1_EB_meanDSM);
            
            fprintf('Correlation %s with V5, in SC %.3f, EB is %.3f\n',roi_name,rho_regionSC(2), rho_regionEB(2));
            fprintf('Fisher transform %s with V5, in SC %.3f, EB is %.3f\n',roi_name,atan(rho_regionSC(2)), atan(rho_regionEB(2)));
            
            results2(count).name = roi_name;
            results2(count).CoeffEB = rho_regionEB(2);
            results2(count).CoeffSC = rho_regionSC(2);
            %save also fisher transformed ones
            results2(count).zTansEB = atan(rho_regionEB(2));
            results2(count).zTansSC = atan(rho_regionSC(2));
            
            count = count + 1;
        end
        save('CorrelationMeanDSMNEW','results','results2')
        
end

end