function newRunNb = updateRunNumber(subject,  taskName, runNb)

% problematic subjects are below
% ctrl007 has 7 runs, ctrl008 has 9 runs
% rest is set to 12 runs for somatotopy experiment 6 runs for mototopy 


  if strcmp(taskName, 'somatotopy')
     runNb = 12; 
     
     if strcmp(subject, 'ctrl007')
         runNb = 7;
     end
     
     if strcmp(subject, 'ctrl008')
         runNb = 9;
     end
  end
  

newRunNb = runNb;
end