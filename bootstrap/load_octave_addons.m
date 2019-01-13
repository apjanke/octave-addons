function load_octave_addons
  %LOAD_OCTAVE_ADDONS Load the octave-addons library
  %
  % This adds all the necessary Mcode directories to your path
  
  this_dir = fileparts(mfilename('fullpath'));
  repo_dir = fileparts(this_dir);
  mcode_dir = fullfile(repo_dir, 'Mcode');
  
  d = mydir(mcode_dir);
  tfFolder = [d.isdir];
  d = d(tfFolder);
  for i = 1:numel(d)
    addpath(fullfile(mcode_dir, d(i).name));
  end
  fprintf('Loaded octave-addons from %s\n', repo_dir);
end

function out = mydir(folder)
  d = dir(folder);
  names = {d.name};
  out = d;
  out(ismember(names, {'.','..'})) = [];
end
