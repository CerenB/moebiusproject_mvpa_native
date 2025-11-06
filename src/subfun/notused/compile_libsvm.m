function compile_libsvm()
% Compile LIBSVM for MATLAB on macOS, matching the CURRENT MATLAB version.
%
% This will:
% - Show current MATLAB root and MEX extension
% - Remove stale MEX files with wrong extension
% - Run libsvm's make.m to build fresh MEX files
% - Verify that libsvm is usable from CoSMoMVPA

fprintf('Compiling LIBSVM for MATLAB...\n');

% Path to libsvm
libsvmPath = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'libsvm', 'matlab');

if ~exist(libsvmPath, 'dir')
    error('LIBSVM not found at: %s\nPlease clone it from: https://github.com/cjlin1/libsvm', libsvmPath);
end

% Report MATLAB environment
try
    mr = matlabroot; %#ok<NASGU>
catch
    mr = '(unknown matlabroot)';
end
ext = mexext;
fprintf('MATLAB root: %s\n', mr);
fprintf('Expected MEX extension: .%s\n', ext);

% Navigate to libsvm matlab directory
currentDir = pwd;
cd(libsvmPath);

% Remove stale MEX files with the wrong extension (e.g., compiled with old MATLAB)
stale = dir('*.mex*');
toDelete = {};
for i = 1:numel(stale)
    if ~endsWith(stale(i).name, ['.', ext])
        toDelete{end+1} = stale(i).name; %#ok<AGROW>
    end
end
if ~isempty(toDelete)
    fprintf('Removing %d stale MEX file(s) compiled for a different MATLAB:\n', numel(toDelete));
    cellfun(@(f) fprintf('  - %s\n', f), toDelete);
    cellfun(@(f) delete(f), toDelete);
end

try
    % Ensure a compiler is configured
    try
        mex('-setup', 'C++');
    catch meSetup
        warning('mex -setup failed or not needed: %s', meSetup.message);
    end

    % Run the make script
    fprintf('Running make.m in %s\n', libsvmPath);
    make;

    fprintf('\n✓ LIBSVM compiled successfully!\n');
    fprintf('MEX files created:\n');

    % List compiled files
    mexFiles = dir(['*.', ext]);
    if isempty(mexFiles)
        % Fallback: show any mex files
        mexFiles = dir('*.mex*');
    end
    for i = 1:length(mexFiles)
        fprintf('  - %s\n', mexFiles(i).name);
    end

    % Add to path
    addpath(libsvmPath);
    rehash toolboxcache;

    % Basic function presence
    wt = which('svmtrain');
    wp = which('svmpredict');
    fprintf('svmtrain: %s\n', ternary(~isempty(wt), wt, 'NOT FOUND'));
    fprintf('svmpredict: %s\n', ternary(~isempty(wp), wp, 'NOT FOUND'));

    % Test with CoSMoMVPA if available
    if exist('cosmo_check_external', 'file')
        fprintf('\nTesting LIBSVM via CoSMoMVPA...\n');
        cosmo_check_external('libsvm');
        fprintf('✓ LIBSVM is working with CoSMoMVPA!\n');
    else
        fprintf('\nNote: CoSMoMVPA not on path; skipping cosmo_check_external test.\n');
    end

catch ME
    cd(currentDir);
    fprintf('\n✗ Compilation failed: %s\n', ME.message);
    fprintf('\nTroubleshooting:\n');
    fprintf('1. Open Xcode once to accept its license (only if full Xcode installed).\n');
    fprintf('2. Ensure Command Line Tools are active: xcode-select --print-path\n');
    fprintf('3. Configure MATLAB compiler: mex -setup C++\n');
    rethrow(ME);
end

cd(currentDir);
fprintf('\nLibSVM path added. You can now use it in your MVPA scripts.\n');

end

function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end
