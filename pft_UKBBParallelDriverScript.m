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
elseif isunix || ismac
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

% Select the type of interpolation - this also happens in the worker thread function
% InterpolationType = pft_GetInterpolationType;
InterpolationType = 'Imresize - 0.25 mm pixels - cubic';

switch InterpolationType    
  case 'Imresize - (x4 x4) - cubic'
    if (exist(fullfile(TopLevelFolder, 'Automated FD Calculation Results - x4'), 'dir') ~= 7)
      mkdir(TopLevelFolder, 'Automated FD Calculation Results - x4');
    end
  case 'Imresize - 0.25 mm pixels - cubic'
    if (exist(fullfile(TopLevelFolder, 'Automated FD Calculation Results - 0.25 mm pixels'), 'dir') ~= 7)
      mkdir(TopLevelFolder, 'Automated FD Calculation Results - 0.25 mm pixels');
    end
end   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write out an XL file which contains just the header
HeaderFile = fullfile(TopLevelFolder, 'Header.csv');

if (exist(HeaderFile, 'file') ~= 2)
  Head = [ 'Folder,', ...
           'Slice order in segmentation,', 'Interpolation,', 'Default perimeter drawn,', ...
           'BP threshold (pixels),', 'Connection threshold (per cent),', ...
           'Original resolution / mm,', 'Output resolution / mm,', ...
           'Slices present,', ...
           'FD - Slice 1,', 'Slice 2,', 'Slice 3,', 'Slice 4,', 'Slice 5,', ...
           'Slice 6,', 'Slice 7,', 'Slice 8,', 'Slice 9,', 'Slice 10,', ...
           'Slice 11,', 'Slice 12,', 'Slice 13,', 'Slice 14,', 'Slice 15,', ...
           'Slice 16,', 'Slice 17,', 'Slice 18,', 'Slice 19,', 'Slice 20,', ...
           'End slices discarded for statistics,', ...
           'Slices evaluated,', 'Slices used,', ...
           'Mean global FD,', ...
           'Mean basal FD,', 'Mean apical FD,', ...
           'Max. basal FD,', 'Max. apical FD' ];     
                 
  fid = fopen(HeaderFile, 'at');
  fprintf(fid, '%s\n', Head);
  fclose(fid);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Process the sub-folders in batches, distributed between the multiple threads
NCORES = uint32(feature('numcores'));

if (NFOLDERS == 1)
  tic;
  pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SubFolders(1), 1);
  toc;
elseif (NFOLDERS <= NCORES)
  ParPool = parpool('local', NFOLDERS);
  tic;
  parfor n = 1:NFOLDERS
    pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SubFolders(n), n);
  end
  toc;
  delete(ParPool);
else  
  Q = idivide(NFOLDERS, NCORES);
  R = mod(NFOLDERS, NCORES);
  
  Count = repmat(uint32(Q), [NCORES, 1]);  
  Count(1:R) = Count(1:R) + 1;
  
  Upper = cumsum(Count);
  Lower = Upper - Count + 1;
  
  SF = cell(NCORES, 1);
  
  for n = 1:NCORES
    SF{n} = SubFolders(Lower(n):Upper(n));
  end
  
  ParPool = parpool('local', NCORES);
  tic;
  parfor n = 1:NCORES 
    pft_FractalDimensionCalculationOnTopLevelFolder(TopLevelFolder, SF{n}, n);
  end
  toc;
  delete(ParPool);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Concatenate the o/p CSV files
Home = pwd;
Away = TopLevelFolder;

if ispc
  pft_MergeFilesInWindows(Home, Away);
elseif isunix
  pft_MergeFilesInLinux(Home, Away);
elseif ismac
  pft_MergeFilesInMacOS(Home, Away);
end

fprintf('Output CSV files merged.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Report completion
fprintf('Driver script completed - all done !\n');

