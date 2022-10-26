function [stim, labels, conditionNb]= setStimuli(decodingType)

% this funtion sets the stimulus and number of conditions for a selected
% decoding type. So far the options are:
% decoding 1: 1 multiclass (5body parts) and 7 binary decoding
% decoding 2: 1 multiclass (6body parts) and 1 binary decoding


% hand = 1, feet = 2, tongue = 3, lips = 4, forehead = 5

switch decodingType
    
    %multiclass decoding FOR 5 body parts
    case 1 
                stim = 1:5;
                labels= {'Hand', 'Feet', 'Tongue', 'Lips',...
                        'Forehead'};
                conditionNb = 8;
                
    % omitting the tongue
    case 2 
                stim = 1:5;
                labels= {'Hand', 'Feet', 'Tongue', 'Lips',...
                        'Forehead'};
                conditionNb = 2;  
                
    % xxx          
    case 3 
                % horizontal / horizontal/ vertical / vertical
                stim = 1:6; 
                labels= {'Hand', 'Feet', 'Tongue', 'Lips',...
                        'Forehead', 'Forehead2'};
                conditionNb = 2;
                
    %multiclass decoding FOR 5 body parts
    case 4 
                stim = 1:5;
                labels= {'Hand', 'Feet', 'Tongue', 'Lips',...
                        'Forehead'};
                    
                % make pairs for pairwise decoding
                pairs = sort(nchoosek(stim,2), 2, 'ascend');                
                conditionNb = length(pairs);
end