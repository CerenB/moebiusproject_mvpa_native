function roiName = removeSpmPrefix(binaryMap, prefix)
% Remove SPM prefix (e.g., 'r') from filename
%
% INPUTS:
%   binaryMap - full path to the resliced image
%   prefix - prefix to remove (e.g., 'r')
%
% OUTPUT:
%   roiName - full path with prefix removed from filename

if nargin < 2
    prefix = 'r';  % default SPM reslice prefix
end

[filepath, filename, ext] = fileparts(binaryMap);

% Remove prefix if it exists at the start of filename
if startsWith(filename, prefix)
    filename = filename(length(prefix)+1:end);
end

% Construct new filename with full path
roiName = fullfile(filepath, [filename, ext]);

% Rename the file if it exists
if exist(binaryMap, 'file')
    movefile(binaryMap, roiName);
    fprintf('Renamed: %s -> %s\n', binaryMap, roiName);
end

end