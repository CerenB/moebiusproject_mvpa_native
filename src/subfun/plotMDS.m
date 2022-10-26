function plotMDS(opt, roi, image)

% copyright Stefania Mattioni 2018

% the visualization of 5 body parts
% input: DSMs for left and right ROIs,
%        other plots are commented

% output: MDS (multi-dimensional scaling) plots in given ROI

%% load input
% get the smoothing parameter for 4D map
funcFWHM = opt.funcFWHM;

% choose masks to be used
opt = chooseMask(opt, roiSource);

                            
% define output path
inputPath = fullfile(opt.pathOutput,'RSA');
cd(inputPath)

outputPath = fullfile(inputPath,'MDSFigures');
if ~exist(outputPath, 'dir')
        mkdir(outputPath);
end

% find which .mat files to load for plotting
patternToSearch = [opt.taskName, ...
                   '_DSM_*', roi, ...
                   '_image-',image, ...
                   '_Slicing-',condition,...
                   '_s-', num2str(funcFWHM), ...
                   '.mat'];
 roiFile = dir(fullfile(inputPath, patternToSearch));
 roiFile([roiFile.isdir]) = [];
  

% make output file names here
figureSaveFileName{1} = fullfile(outputPath,[roiFile(1).name(1:end-4), '.pdf']);
figureSaveFileName{2} = fullfile(outputPath,[roiFile(2).name(1:end-4), '.pdf']);


% load dissimilarity matrix
load(roiFile(1).name);
left_dsm = contMeanDsm;
load(roiFile(2).name);
right_dsm = contMeanDsm;

%label the dots shorter to avoid overlap
labels_dsm= {'Hand', 'Feet', 'Tongue', 'Lips','Forehead'};
%hand = 1, feet = 2, tongue = 3, lips = 4, forehead = 5
%% let's get going...
% get two-dimensional projection of ROIs dissimilarity matrices using cmdscale
figure;
right_mds = cmdscale(squareform(right_dsm));
left_mds = cmdscale(squareform(left_dsm));

% adjust range of x and y axes
constant = 0.3;
mx = max(abs(left_mds(:)))+ constant;
xlim([-mx mx]);
ylim([-mx mx]);

% adjust the font size
fnsize= 12;

% 5 body parts in left ROI
text(left_mds(1,1), left_mds(1,2), labels_dsm(1),'Color',[1,0.5,0],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(2,1), left_mds(2,2), labels_dsm(2),'Color',[1,0,0],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(3,1), left_mds(3,2), labels_dsm(3),'Color',[0,0,1],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(4,1), left_mds(4,2), labels_dsm(4),'Color',[0,0.5,1],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(5,1), left_mds(5,2), labels_dsm(5),'Color',[0.2,0.75,0.8],'FontName','Helvetica','FontSize',fnsize); %forehead


% 5 body parts in the right ROI
figure;
text(right_mds(1,1), right_mds(1,2), labels_dsm(1),'Color',[1,0.5,0],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(2,1), right_mds(2,2), labels_dsm(2),'Color',[1,0,0],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(3,1), right_mds(3,2), labels_dsm(3),'Color',[0,0,1],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(4,1), right_mds(4,2), labels_dsm(4),'Color',[0,0.5,1],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(5,1), right_mds(5,2), labels_dsm(5),'Color',[0.2,0.75,0.8],'FontName','Helvetica','FontSize',fnsize); 

%text(right_mds(:,1), right_mds(:,2), labels_dsm);
% adjust range of x and y axes
constant = 0.3;
mx = max(abs(right_mds(:))) + constant;
xlim([-mx mx]);
ylim([-mx mx]);

%save manually these MDS figures...

%% Plot DSMs

figure;
LH = imagesc(left_dsm);
set(gca,'XTick',1:length(left_dsm),'XAxisLocation', 'top','XTickLabel',...
    labels_dsm,'FontSize',14,'YTick',1:length(left_dsm),...
    'YTickLabel',labels_dsm,'TickLength',[0 0]);
            
c= colorbar();
set(c, 'YTick', [0 1]); 
caxis([0 1])
saveas(LH,figureSaveFileName{1}); 

figure;
RH = imagesc(right_dsm);
set(gca,'XTick',1:length(right_dsm),'XAxisLocation', 'top','XTickLabel',...
    labels_dsm,'FontSize',14,'YTick',1:length(right_dsm),...
    'YTickLabel',labels_dsm,'TickLength',[0 0]);
            
c = colorbar();
set(c, 'YTick', [0 1]); 
caxis([0 1])
saveas(RH,figureSaveFileName{2})
   
% another idea would be...
%figure;
%imagesc(tril(right_dsm))
                     
            
%%
% pathway = '/Users/cerenbattal/Cerens_files/fMRI/Processed/Spatiotopy/RSA/DSM_results_group_reliability_MotionStatic/6mm/';
% cd(pathway)
% load('SC_lPT_6mm_NS_dsm');
% lPT_dsm = meanSC_dsm;
% 
% load('SC_rPT_6mm_NS_dsm');
% rPT_dsm = meanSC_dsm;
% 
% %  subplot function 
% labels_dsm= {'Leftward', 'Rightward', 'Downward', 'Upward','Left','Right','Down','Up'};
% 
% figure();
% subplot(4,2,1);
% imagesc(lPT_dsm);
% title('Left PT DSM');
% %set(gca,'XTickLabel',labels_dsm,'YTickLabel',labels_dsm);
% 
% subplot(4,2,2);
% imagesc(rPT_dsm);
% title('Left PT DSM');
% 
% 
% %% Add pattern similarity
% 
% labels = {'Left', 'Right', 'Down', 'Up'};
% 
% % call function
% %pattern_motionstaticSC(2,'NS',0) #(action,roi,split_half)
% 
% mat = Lz
% subplot(4,2,3);
% imagesc(mat);
% colorbar
% caxis([min(mat(:)) max(mat(:))])
% title('Pattern Similarity');
% set(gca,'XTick',1:length(mat),'XAxisLocation', 'top','XTickLabel',labels,...
%                 'YTick',1:length(mat),'YTickLabel',labels,'TickLength',[0 0]);
%             
% mat = Rz
% subplot(4,2,4);
% imagesc(mat);
% colorbar
% caxis([min(mat(:)) max(mat(:))])
% title('Pattern Similarity');
% set(gca,'XTick',1:length(mat),'XAxisLocation', 'top','XTickLabel',labels,...
%                 'YTick',1:length(mat),'YTickLabel',labels,'TickLength',[0 0]);
%             
% 
% %% Add the dendrograms
% 
% lPT_hclus = linkage(lPT_dsm);
% rPT_hclus = linkage(rPT_dsm);
% 
% subplot(4,2,5);
% 
% dendrogram(lPT_hclus,'labels',labels_dsm,'orientation','left');
% subplot(4,2,6);
% dendrogram(rPT_hclus,'labels',labels_dsm,'orientation','left');
% 
% 
% %% Show the MDS (multi-dimensional scaling) plots 
% 
% % Show early visual cortex model similarity
% subplot(4,2,7);
% 
% % get two-dimensional projection of 'ev_dsm' dissimilarity using cmdscale;
% % assign the result to a variable 'xy_ev'
% lPT_mds = cmdscale(squareform(lPT_dsm));
% 
% % plot the labels using the labels
% text(lPT_mds(:,1), lPT_mds(:,2), labels_dsm);
% 
% % adjust range of x and y axes
% mx = max(abs(lPT_mds(:)));
% xlim([-mx mx]);
% ylim([-mx mx]);
% 
% % Show right PT similarity
% 
% % using cmdscale, store two-dimensional projection of 'vt_dsm' and
% % 'behav_dsm' in 'xy_vt' and 'xy_behav'
% rPT_mds = cmdscale(rPT_dsm);
% 
% 
% subplot(4,2,8);
% text(rPT_mds(:,1), rPT_mds(:,2), labels_dsm);
% mx = max(abs(rPT_mds(:)));
% xlim([-mx mx]);
% ylim([-mx mx]);
% 
