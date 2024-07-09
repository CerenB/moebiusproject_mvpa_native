function [ds, textcond] = sliceDataPerCondition(opt, ds)

% this function slice the ds (data 4d) according to the desired conditions,
% such as to run 4class decoding, it slices the ds to 4 ds.sa.targets

% hand = 1, feet = 2, tongue = 3, lips = 4, forehead = 5

decodingType = opt.decodingType;
iCondition = opt.iDecodCondition;

if isfield(opt.mvpa, 'pairs')
    labels = opt.mvpa.condLabelName;
    stim = opt.mvpa.condLabelNb;
    pairs = sort(nchoosek(stim,2), 2, 'ascend');

end

switch decodingType
    case 1
        if iCondition == 1
            %5 body parts: forehead, hand, feet, tongue,
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'BodyParts5';
        elseif iCondition == 2
            % Hand vs. Feet
            ds = cosmo_slice(ds,ds.sa.targets == 1 |ds.sa.targets == 2 ) ;
            textcond = 'HandvsFeet';
        elseif iCondition == 3
            % Hand vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 1 |ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsHand';
        elseif iCondition == 4
            % Feet vs. Forehead
            ds =cosmo_slice(ds,ds.sa.targets == 2 | ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsFeet';
        elseif iCondition == 5
            % Tongue vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 3 |ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsTongue';
        elseif iCondition == 6
            % Lips vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 4 | ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsLips';
        elseif iCondition == 7
            % Hand vs. Lips
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 4 ) ;
            textcond = 'HandvsLips';
        elseif iCondition == 8
            % Lips vs. Tongue
            ds = cosmo_slice(ds,ds.sa.targets == 3 | ds.sa.targets == 4 ) ;
            textcond = 'TonguevsLips';
        elseif iCondition == 9
            %5 body parts: forehead, hand, feet, tongue,
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'OmitTongueBodyParts4';
        end
        
        % searchlight to check for 2 things only
    case 2
        if iCondition == 1
            %5 body parts: forehead, hand, feet, tongue,
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'BodyParts5';
        elseif iCondition == 2
            %5 body parts: forehead, hand, feet, tongue,
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'OmitTongueBodyParts4';
        end
        
        
    case 3
        % 6 body parts with Forehead and Forehead2
        if iCondition == 1
            % 6 body parts: forehead, hand, feet, tongue,
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5 | ds.sa.targets == 6) ;
            textcond = 'BodyParts6';
        elseif iCondition == 2
            ds = cosmo_slice(ds,ds.sa.targets == 5 | ds.sa.targets == 6 ) ;
            textcond = 'ForeheadvsForehead2';
            
        end
        
        
    case 4
        % partition the dataset
        ds = cosmo_slice(ds,ds.sa.targets == pairs(iCondition,1) | ds.sa.targets == pairs(iCondition,2)) ;
        textcond = [labels{pairs(iCondition,1)},'_vs_',labels{pairs(iCondition,2)}];
        
end

end