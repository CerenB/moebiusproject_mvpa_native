function [ds, textcond] = sliceDataPerCondition(ds,decodingType,cond)

% this function slice the ds (data 4d) according to the desired conditions,
% such as to run 4class decoding, it slices the ds to 4 ds.sa.targets

% hand = 1, feet = 2, tongue = 3, lips = 4, forehead = 5
switch decodingType
    case 1
        if cond == 1
            %5 body parts: forehead, hand, feet, tongue,  
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'BodyParts5';
        elseif cond == 2
            % Hand vs. Feet
            ds = cosmo_slice(ds,ds.sa.targets == 1 |ds.sa.targets == 2 ) ;
            textcond = 'HandvsFeet';
        elseif cond == 3
            % Hand vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 1 |ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsHand';
        elseif cond == 4
            % Feet vs. Forehead
            ds =cosmo_slice(ds,ds.sa.targets == 2 | ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsFeet';
        elseif cond == 5
            % Tongue vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 3 |ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsTongue';
        elseif cond == 6
            % Lips vs. Forehead
            ds = cosmo_slice(ds,ds.sa.targets == 4 | ds.sa.targets == 5 ) ;
            textcond = 'ForeheadvsLips';
        elseif cond == 7
            % Hand vs. Lips
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 4 ) ;
            textcond = 'ForeheadvsLips';
        elseif cond == 8
            % Lips vs. Tongue
            ds = cosmo_slice(ds,ds.sa.targets == 3 | ds.sa.targets == 4 ) ;
            textcond = 'TonguevsLips';
        elseif cond == 9
            %5 body parts: forehead, hand, feet, tongue,  
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'OmitTongueBodyParts4';
        end
    
        % searchlight to check for 2 things only
    case 2
        if cond == 1
            %5 body parts: forehead, hand, feet, tongue,  
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'BodyParts5';
        elseif cond == 2
            %5 body parts: forehead, hand, feet, tongue,  
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 | ds.sa.targets == 4 | ds.sa.targets == 5) ;
            textcond = 'OmitTongueBodyParts4';
        end
        
        
    case 3
        % 6 body parts with Forehead and Forehead2
        if cond == 1
            % 6 body parts: forehead, hand, feet, tongue,  
            ds = cosmo_slice(ds,ds.sa.targets == 1 | ds.sa.targets == 2 |ds.sa.targets == 3 | ds.sa.targets == 4 | ds.sa.targets == 5 | ds.sa.targets == 6) ;
            textcond = 'BodyParts6';
        elseif cond == 2
            ds = cosmo_slice(ds,ds.sa.targets == 5 | ds.sa.targets == 6 ) ;
            textcond = 'ForeheadvsForehead2';
            
        end
end

end