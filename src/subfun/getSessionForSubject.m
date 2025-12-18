function session = getSessionForSubject(subLabel)
% Determine session based on subject ID
% 
% Matches the logic from bash warp_native_masks_to_mni.sh
%
% Usage:
%   session = getSessionForSubject('sub-ctrl001');
%
% Output:
%   session - session label (e.g., 'ses-001', 'ses-002', 'ses-003')

switch subLabel
  case {'sub-ctrl003','sub-ctrl004','sub-ctrl006','sub-ctrl007','sub-ctrl008', ...
        'sub-ctrl009','sub-ctrl010','sub-ctrl011','sub-ctrl012','sub-ctrl014', ...
        'sub-ctrl016','sub-ctrl017'}
    session = 'ses-002';
  case {'sub-ctrl015'}
    session = 'ses-003';
  case {'sub-mbs004','sub-mbs005','sub-mbs006','sub-mbs007'}
    session = 'ses-002';
  otherwise
    session = 'ses-001';
end

end
