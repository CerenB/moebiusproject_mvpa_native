function ds = setCosmoStructure(opt, ds)
  % sets up the target, chunk, labels by stimuli condition labels, runs,
  % number labels.
  
  condLabelNb = opt.mvpa.condLabelNb;
  condLabelName = opt.mvpa.condLabelName;
  
   [targets, chunks, labels] = setTargetChunksLabels(opt, ...
                                                    condLabelNb, ...
                                                    condLabelName);

  % assign our 4D image design into cosmo ds git
  ds.sa.targets = targets;
  ds.sa.chunks = chunks;
  ds.sa.labels = labels;

  % figure; imagesc(ds.sa.chunks);

end