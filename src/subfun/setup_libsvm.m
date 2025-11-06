function setup_libsvm()
  % Setup libsvm paths and verify installation
  %
  % This function adds libsvm to the MATLAB path, compiles if needed,
  % and checks if it's working
  
  libsvm_base = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'libsvm');
  libsvm_matlab = fullfile(libsvm_base, 'matlab');
  
  if ~exist(libsvm_matlab, 'dir')
      error(['libsvm not found at: %s\n' ...
             'Please clone it from: https://github.com/cjlin1/libsvm'], libsvm_matlab);
  end
  
  % Add to path
  addpath(libsvm_matlab);
  
  % Check if already compiled (look for .mex files)
  mexFiles = dir(fullfile(libsvm_matlab, '*.mex*'));
  
  if isempty(mexFiles)
      fprintf('libsvm MEX files not found. Compiling...\n');
      currentDir = pwd;
      cd(libsvm_matlab);
      
      try
          % Run the make script
          make;
          fprintf('✓ libsvm compiled successfully!\n');
      catch ME
          cd(currentDir);
          error(['Failed to compile libsvm: %s\n\n' ...
                 'Please ensure you have:\n' ...
                 '1. Xcode Command Line Tools: xcode-select --install\n' ...
                 '2. MATLAB compiler configured: mex -setup'], ME.message);
      end
      
      cd(currentDir);
  end
  
  % Verify it works
  try
      cosmo_check_external('libsvm');
      fprintf('✓ libsvm is available and working\n');
  catch ME
      warning('libsvm verification failed: %s', ME.message);
      warning('Some SVM-based analyses may not work.');
  end
  
end