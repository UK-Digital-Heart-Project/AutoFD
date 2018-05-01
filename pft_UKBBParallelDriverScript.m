%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clear the workspace as usual
clear all
close all
clc

fclose('all');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Locate a batch folder
if ispc
  Username = getenv('Username');
  Home = fullfile('C:', 'Users', Username, 'Desktop');
elseif isunix
  [ Status, CmdOut ] = system('whoami');
  Home = fullfile('home', CmdOut, 'Desktop');
end  
  
TopLevelFolder = uigetdir(Home, 'Select a top-level folder with subject folders inside');

if (TopLevelFolder == 0)
  msgbox('No selection - quitting !', 'Exit');
  return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Locate all the folders beneath
Listing = dir(TopLevelFolder);
Entries = { Listing.name  };
Folders = [ Listing.isdir ];
Entries = Entries(Folders);

SingleDot = strcmp(Entries, '.');
Entries(SingleDot) = [];
DoubleDot = strcmp(Entries, '..');
Entries(DoubleDot) = [];

Results = strcmp(Entries, 'Automated FD Calculation Results - x4');
Entries(Results) = [];
Results = strcmp(Entries, 'Automated FD Calculation Results - 0.25 mm pixels');
Entries(Results) = [];

Entries = Entries';
Entries = sort(Entries);

if isempty(Entries)
  h = msgbox('No sub-folders found.', 'Exit', 'modal');
  uiwait(h);
  delete(h);
  return;
end

SubFolders = Entries;

NFOLDERS = uint32(size(SubFolders, 1));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Process the sub-folders in batches, distributed between the multiple threads
NCORES = uint32(feature('numcores'));

if (NFOLDERS < NCORES)
  tic;
  parfor n = 1:NFOLDERS
    pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SubFolders(n), n);
  end
  toc;
else  
  BATCH = idivide(NFOLDERS, NCORES);
  
  Lower = zeros([NCORES, 1], 'uint32');
  Upper = zeros([NCORES, 1], 'uint32');
  
  a = 1;
  b = BATCH;
  
  for n = 1:NCORES-1
    Lower(n) = a;
    a = a + BATCH;
    Upper(n) = b;
    b = b + BATCH;
  end
  
  Lower(NCORES) = a;
  Upper(NCORES) = NFOLDERS;    
    
  SF = cell(NCORES, 1);
  
  for n = 1:NCORES
    SF{n} = SubFolders(Lower(n):Upper(n));
  end
  
  tic;
  parfor n = 1:NCORES 
    pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SF{n}, n);
  end
  toc;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Driver script completed - all done !\n');

