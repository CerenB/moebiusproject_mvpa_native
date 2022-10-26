function extractAndPlotPairwiseDA(opt,roiSource, image)
% we use this script to visualised pairwise decoding DSM and MDS


% choose masks to be used
opt = chooseMask(opt, roiSource);

% assign the values
choosenVoxNb = opt.mvpa.ratioToKeep;	
ffxSmooth = opt.funcFWHM;
leftRoi = opt.maskLabel{1};
rightRoi = opt.maskLabel{2};

% define output path
outputPath = fullfile(opt.pathOutput,'RSA');
if ~exist(outputPath, 'dir')
        mkdir(outputPath);
end

% load the .mat file 
inputFilePattern =[opt.taskName, ...
    'PairwiseDecoding_', ...
    roiSource, ...
    '_s', num2str(opt.funcFWHM), ...
    '_voxNb', num2str(opt.mvpa.ratioToKeep), ...
    '_*', '.mat'];

 inputFile = dir(fullfile(opt.pathOutput, inputFilePattern));
 load(fullfile(inputFile.folder,inputFile.name));
 
%% prepare labels
decodingType = 4;
[opt.mvpa.condLabelNb, opt.mvpa.condLabelName, ~] = setStimuli(decodingType);
                             
labels = opt.mvpa.condLabelName;
stim = opt.mvpa.condLabelNb;
pairs = nchoosek(stim,2);
    
for iLabel = 1:length(pairs)
    
    AllPairs{iLabel} = [labels{pairs(iLabel,1)},...
        '_vs_',...
        labels{pairs(iLabel,2)}];
    
end

% condition names
s = AllPairs';


% extract and save into vectors the DA per condition
for iCond = 1:length(AllPairs)
    
    decodingConditions = AllPairs{iCond};
    
   
    countL = 1;
    countR = 1;
    for i = 1:length(accu)
        % extract relevant DA
        if strcmp(accu(i).decodingConditions,decodingConditions) && ...
                strcmp(accu(i).image, image) && ...
                (accu(i).choosenVoxNb == choosenVoxNb) && ...
                (accu(i).ffxSmooth == ffxSmooth) && ...
                strcmp(accu(i).roiSource, roiSource)
            
            %for left Roi
            if strcmp(accu(i).mask,leftRoi)
                
                leftAccu(countL).accuracy = accu(i).accuracy;
                leftAccu(countL).subID = accu(i).subID;
                leftAccu(countL).condition = accu(i).decodingConditions;
                countL = countL +1;
            % for right roi    
            elseif strcmp(accu(i).mask,rightRoi)
                
                rightAccu(countR).accuracy = accu(i).accuracy;
                rightAccu(countR).subID = accu(i).subID;
                rightAccu(countL).condition = accu(i).decodingConditions;
                countR = countR +1;
            end
        end
        
    end
    
    % make structure into vector
    right = [rightAccu(1:end).accuracy]';
    left = [leftAccu(1:end).accuracy]';
    
    % save vectors into matrix
    AllLeftAccu (:, iCond) = left;
    AllRightAccu (:, iCond) = right;
    
    
end

% make dsm across participants 
leftDsm = squareform(mean(AllLeftAccu));
rightDsm = squareform(mean(AllRightAccu));

% make dsm per participant
for iSub = 1:numel(opt.subjects)
    dsmLeft(:, :, iSub) = squareform((AllLeftAccu(iSub, :)));
    dsmRight(:, :, iSub) = squareform((AllRightAccu(iSub, :)));
end

% save
outputName = ['DSM-', inputFilePattern(1:end-6)];
save(fullfile(outputPath,outputName),'leftDsm', 'rightDsm',...
                              'AllLeftAccu', 'AllRightAccu');

%% plot  pairwise DSM
% set below parameters to save the figure correctly
% change this part accordingly
% DSM = leftDsm;
% roiName = rightRoi;
DSM = rightDsm;
roiName = 'rightSomatoCx3ab';

% DSM = dsmRight(:,:,3);
% roiName = 'rightSomatoCx3ab-pil011';

% make the figure
figure;
H = imagesc(DSM);
titleme = ['PairwiseDecoding',' ', opt.taskName, ' ', roiName,' '];
title(titleme);
set(gca,'XTick',1:length(DSM),'XAxisLocation', 'top','XTickLabel',labels,'FontSize', 14,...
    'YTick',1:length(DSM),'YTickLabel',labels,'FontSize', 14,'TickLength',[0 0]);

% colormap(jet)
c = colorbar();
set(c, 'YTick', [0 1]); % In this example, just use three ticks for illustation
caxis([0 1])
axis square;
            
% save 
savePdf = [outputName, '_', roiName, '_', datestr(now, 'yyyymmddHHMM'), '.pdf'];
saveas(H,fullfile(outputPath,savePdf));


%% plot MDS
%label the dots shorter to avoid overlap
% labelsDsm= {'Hand', 'Feet', 'Tongue', 'Lips','Forehead'};
labelsDsm= {'Forehead',  'Lips', 'Tongue', 'Feet', 'Hand'};
%hand = 1, feet = 2, tongue = 3, lips = 4, forehead = 5

S = figure;
mds = cmdscale(DSM);

% adjust range of x and y axes
constant = 0.3;
mx = max(abs(mds(:)))+ constant;
xlim([-mx mx]);
ylim([-mx mx]);

% adjust the font size
fnsize= 18;

% 5 body parts in left ROI
text(mds(1,1), mds(1,2), labelsDsm(1),'Color',[1,0.5,0],'FontName','Helvetica','FontSize',fnsize);
text(mds(2,1), mds(2,2), labelsDsm(2),'Color',[1,0,0],'FontName','Helvetica','FontSize',fnsize);
text(mds(3,1), mds(3,2), labelsDsm(3),'Color',[0,0,1],'FontName','Helvetica','FontSize',fnsize);
text(mds(4,1), mds(4,2), labelsDsm(4),'Color',[0,0.5,1],'FontName','Helvetica','FontSize',fnsize);
text(mds(5,1), mds(5,2), labelsDsm(5),'Color',[0.2,0.75,0.8],'FontName','Helvetica','FontSize',fnsize); %forehead


% save
outputMDSName = ['MDS_Averaged-subjNb-4_',outputName(5:end), ...
              '_',roiName, '_', datestr(now, 'yyyymmddHHMM'), '.pdf'];
saveas(S,fullfile(outputPath,outputMDSName));

end