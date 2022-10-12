function plot_DirectionLocation_MDS

% copyright Stefania Mattioni 2018

% the visualization of left,right,up nd down motion and static
% input: DSMs for left and right ROIs,
%        other plots are commented

% output: MDS (multi-dimensional scaling) plots in given ROI

% last edit cb 14.07.2021 to plot MDS in loc V5 and loc PT in EB/SC

%% load input
pc = 2;

if pc == 1
    pcPath = '/Users/cerenbattal/';
else 
    pcPath = '/Volumes/extreme/';
end

inputPathName = 'Cerens_files/fMRI/Processed/Spatiotopy/RSA/DSM_results_group_reliability/DSM_results_group_reliability_MotionStatic/6mm';
inputPath = fullfile(pcPath, inputPathName);
cd(inputPath)

outputPath = fullfile(inputPath,'MDS_figures');
group = 'EB';
roiName1 = 'lPT_6mm_dsm';
roiName2 = 'rPT_6mm_dsm';

% set the output file names
figure1SaveName = fullfile(outputPath,[group, roiName1,'_', date,'.pdf']);
figure2SaveName = fullfile(outputPath,[group, roiName2,'_', date,'.pdf']);

% load dissimilarity matrix
load([group,'_',roiName1]); 
left_dsm = meanEB_dsm;

load([group,'_',roiName2]);
right_dsm = meanEB_dsm;

%label the dots shorter to avoid overlap
labels_dsm= {'LD', 'RD', 'DD', 'UD','L','R','D','U'};

%% let's get going...
% get two-dimensional projection of ROIs dissimilarity matrices using cmdscale
figure;
right_mds = cmdscale(right_dsm);
left_mds = cmdscale(squareform(left_dsm));

% adjust range of x and y axes
constant = 0.3;
mx = max(abs(left_mds(:)))+ constant;
xlim([-mx mx]);
ylim([-mx mx]);

% adjust the font size
fnsize= 12;

% Left ROI
%Motion direction in left ROI

text(left_mds(1,1), left_mds(1,2), labels_dsm(1),'Color',[1,0.5,0],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(2,1), left_mds(2,2), labels_dsm(2),'Color',[1,0,0],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(3,1), left_mds(3,2), labels_dsm(3),'Color',[0,0,1],'FontName','Helvetica','FontSize',fnsize);
text(left_mds(4,1), left_mds(4,2), labels_dsm(4),'Color',[0,0.5,1],'FontName','Helvetica','FontSize',fnsize);
%static location in left ROI
text(left_mds(5,1), left_mds(5,2), labels_dsm(5),'Color',[0.8,0.5,0.3],'FontName','Helvetica','FontSize',fnsize); %[1,0,1]
text(left_mds(6,1), left_mds(6,2), labels_dsm(6),'Color',[0.75,0.2,0.2],'FontName','Helvetica','FontSize',fnsize); 
text(left_mds(7,1), left_mds(7,2), labels_dsm(7),'Color',[0.5,0.5,1],'FontName','Helvetica','FontSize',fnsize); 
text(left_mds(8,1), left_mds(8,2), labels_dsm(8),'Color',[0.5,0.75,1],'FontName','Helvetica','FontSize',fnsize); 



% Right ROI similarity
% Motion direction in left ROI
figure;
text(right_mds(1,1), right_mds(1,2), labels_dsm(1),'Color',[1,0.5,0],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(2,1), right_mds(2,2), labels_dsm(2),'Color',[1,0,0],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(3,1), right_mds(3,2), labels_dsm(3),'Color',[0,0,1],'FontName','Helvetica','FontSize',fnsize);
text(right_mds(4,1), right_mds(4,2), labels_dsm(4),'Color',[0,0.5,1],'FontName','Helvetica','FontSize',fnsize);
%static location in left ROI
text(right_mds(5,1), right_mds(5,2), labels_dsm(5),'Color',[0.8,0.5,0.3],'FontName','Helvetica','FontSize',fnsize); %[1,0,1]
text(right_mds(6,1), right_mds(6,2), labels_dsm(6),'Color',[0.75,0.2,0.2],'FontName','Helvetica','FontSize',fnsize); 
text(right_mds(7,1), right_mds(7,2), labels_dsm(7),'Color',[0.5,0.5,1],'FontName','Helvetica','FontSize',fnsize); 
text(right_mds(8,1), right_mds(8,2), labels_dsm(8),'Color',[0.5,0.75,1],'FontName','Helvetica','FontSize',fnsize); 

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
saveas(LH,figure1SaveName); 

figure;
RH = imagesc(right_dsm);
set(gca,'XTick',1:length(right_dsm),'XAxisLocation', 'top','XTickLabel',...
    labels_dsm,'FontSize',14,'YTick',1:length(right_dsm),...
    'YTickLabel',labels_dsm,'TickLength',[0 0]);
            
c = colorbar();
set(c, 'YTick', [0 1]); 
caxis([0 1])
saveas(RH,figure2SaveName)
   
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
