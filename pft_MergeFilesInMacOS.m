function pft_MergeFilesInMacOS(Home, Away)

% Home is the main MATLAB working directory, Away is the top-level folder where o/p is directed
cd(Away);

% List all the local CSV files
Listing = dir('Data-*.csv');
Entries = { Listing.name };
Folders = [ Listing.isdir ];
Entries = Entries(~Folders);
Entries = sort(Entries); 

% Create and run a merge command
a = 'cat Header.csv ';
b = sprintf('%s ', Entries{:});
c = '> Summary-Auto-FD-v0.csv 2>/dev/null';

Cmd = [ a b c ];

disp(Cmd);

system(Cmd);

% Return to the Home directory
cd(Home);

end
