function setup_libsvm()
  % Setup libsvm paths and verify installation
  %
  % This function adds libsvm to the MATLAB path and checks if it's working
  
  libsvm_base = fullfile(getenv('HOME'), 'Documents', 'MATLAB', 'libsvm-3.36');
  libsvm_matlab = fullfile(libsvm_base, 'matlab');
  
  % Add both directories to be safe
  addpath(libsvm_matlab);
  addpath(genpath(libsvm_base));
  
  % Check if it works, but don't stop execution if it fails
  try
      cosmo_check_external('libsvm');
      fprintf('✓ libsvm is available\n');
  catch ME
      warning('libsvm check failed, but continuing anyway...');
      warning('Error was: %s', ME.message);
      warning('Some SVM-based analyses may not work.');
  end
  
end