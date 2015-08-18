clear all;

% if files.brandeis.edu is in the file system, then add data to path
d = filesep;

if ispc; files_dot_brandeis_edu = '\\files.brandeis.edu\jadhav-lab';
elseif ismac; files_dot_brandeis_edu = '/Volumes/jadhav-lab/';
else files_dot_brandeis_edu = '/home/mcz/DataShare'; end;
path_str = [d 'DATA' d 'sjadhav' d 'HPexpt' d];


if(exist(files_dot_brandeis_edu, 'dir'))
	
	% Adds all data folders to path and subfolders. For now this is
	% how functions will find data.
	path(path,genpath([files_dot_brandeis_edu path_str 'HPa_direct'])) 
	path(path,genpath([files_dot_brandeis_edu path_str 'HPb_direct']))
	path(path,genpath([files_dot_brandeis_edu path_str 'HPc_direct']))
end


%% Parameter Section
% This is where we specifiy which parameters we're interested ... which
% animals, which days/epochs, which tetrodes, and what types of maze and
% electrophysiology parameters to select for.

% Parameters for circumscribing sample around a point
% --------------------------------------------------------
% How large of radius should we sample
sampleParams.circleParams.radius = 20;       % 20 pixel radius
% Where to sample
sampleParams.circleParams.segment = [1 1];   % [1 0] denotes end (1) of segment number 1;
											 % Note: reason second number
											 % encodes start and end of
											 % segment in 0 and 1 is
											 % eventually we may extend
											 % function to request a point
											 % that is some fraction, e.g.
											 % 0.75 from start (0) to end
											 % (1) of segment

% Parameters for selecting trajectory type
% ---------------------------------------------------------
% Which trajectory type to sample?
sampleParams.trajbound_type = 0 ;            % 0 denotes outbound

% Parameters for selecting whether or not to constrain sample to the edge
% of the detected sample zone.  For 30hz sample rate, [15 15] grabs 500
% msec in front and behind 1st boundary crossing. 15 frames foward and
% backward.
 sampleParams.edgeMode.window = [15 15];
 sampleParams.edgeMode.entranceOrExit = 'entrance';

%% DEBUG SECTION: show acquireSample method works

% Load all three data types for day, epoch .. squeeze into data struct
load HPalinpos05;
data.linpos = linpos{5}{2};
load HPapos05;
data.pos = pos{5}{2};
load HPatrajinfo05;
data.trajinfo = trajinfo{5}{2};

% Run the acquireSample function
[time, indices, t_paths, i_paths] = acquireSample(data,sampleParams);

% WORKS!

%% TEST SECTION: show gatherWindowsofData works

dataFolder = './';	% DOES NOT HAVE TO BE IN DATA FOLDER RIGHT NOW ... just add whole data folder heirarchy to path above -- see code line 1 atop!
animals = {'HPa','HPb'};
day_set = [5 6];			% set of days to analyze for all animals ... 
epoch_set = [2 4];		% set of epochs to analyze for all animals ... 
tetrode_set = [1 2];		% set of tetrodes to analyze for all animals ... 

						% .. these could in theory be set individually per
						% animal so that different sets analyzed for
						% different animals


% set .animals field to contain who, which day, which epoch, and which
% tetrodes
for a = 1:numel(animals)
	
	dataToGet.animals.(animals{a}).days = day_set;
	dataToGet.animals.(animals{a}).epochs = epoch_set;
	dataToGet.animals.(animals{a}).tetrodes = tetrode_set;
	
end

% set dataToGet.sampleParams, from the above section
dataToGet.sampleParams = sampleParams;

% specify which electrophysiology data to window!
dataToGet.datType = 'eeg';

% specify process options if any
processOptions.windowPadding = NaN;


% RUN FUNCTION!
acquisition = gatherWindowsOfData(dataFolder, dataToGet, processOptions);

%% TEST SECTION: Getting second acquisition

% dataFolder = './';	% DOES NOT HAVE TO BE IN DATA FOLDER RIGHT NOW ... just add whole data folder heirarchy to path above -- see code line 1 atop!
% animals = {'HPa'};
% day_set = [5];			% set of days to analyze for all animals ... 
% epoch_set = [2];		% set of epochs to analyze for all animals ... 
% tetrode_set = [16];		% set of tetrodes to analyze for all animals ... 
% 
% 						% .. these could in theory be set individually per
% 						% animal so that different sets analyzed for
% 						% different animals
% 
% 
% % set .animals field to contain who, which day, which epoch, and which
% % tetrodes
% for a = 1:numel(animals)
% 	
% 	dataToGet.animals.(animals{a}).days = day_set;
% 	dataToGet.animals.(animals{a}).epochs = epoch_set;
% 	dataToGet.animals.(animals{a}).tetrodes = tetrode_set;
% 	
% end
% 
% 
% % RUN FUNCTION!
% acquisition2 = gatherWindowsOfData(dataFolder, dataToGet, processOptions);

%% Debug generateSpecgrams

dataToProcess.days = [5 6]; dataToProcess.epochs = [2 4]; 
dataToProcess.tetrodes = [1 2]; dataToProcess.tetrodes2 = 16; 

dataToProcess.save = 0;

generate_xGrams(acquisition,dataToProcess);		% add acquisition2 for coherograms

% Run function

%% MAIN ANALYSIS SECTION -- Theta Coherence Analysis Guts


