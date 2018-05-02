function pft_MergeFilesInWindows(Home, Away)

% Home is the main MATLAB working directory, Away is the top-level folder where o/p is directed
cd(Away);

% List all the local CSV files
Listing = dir('Data-*.csv');
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries = Entries(~Folders);
Entries = sort(Entries); 

% Create and run a merge command
a = 'type Header.csv ';
b = sprintf('%s ', Entries{:});
c = '> Summary-Auto-FD-v0-1.csv 2>nul';

Cmd = [ a b c ];

system(Cmd);

disp(Cmd);

% Return to the Home directory
cd(Home);

end
