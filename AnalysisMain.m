%% Putting Data Files on Path and Clearing Variables


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

clear all;


%% Parameter Section
% This is where we specifiy which parameters we're interested ... which
% animals, which days/epochs, which tetrodes, and what types of maze and
% electrophysiology parameters to select for.

% Parameters for circumscribing sample around a point
% --------------------------------------------------------
% How large of radius should we sample
sampleParams.circleParams.radius = 20;       % 20 pixel radius
% Where to sample
% [1 0] denotes end (1) of segment number 1;
sampleParams.circleParams.segment = [1 1];  
% Note: Second number encodes start and end of segment in 0 and 1.
% Eventually we may extend function to request a point that is some
% fraction, e.g. 0.75 from start (0) to end (1) of segment

% Parameters for selecting trajectory type
% ---------------------------------------------------------
% Which trajectory type to sample?
sampleParams.trajbound_type = 0 ;            % 0 denotes outbound

% Pameters for controlling edge mode
% ----------------------------------------------------------------------
% Edge mode refers to a mode where we sample from the edges of a choice
% region. Adding it into the struct activates it. Placing a window subfield
% controlls the size of the window in front and behind sample region
% entrance or exit. Its unit is frames.  For 30hz sample rate, [15 15]
% grabs 15 frames in front and behind boundary crossing. entranceOrExit
% subfield controls whether to sample entrance or exit.
 sampleParams.edgeMode.window = [75 75];
 sampleParams.edgeMode.entranceOrExit = 'entrance';
 
 % Parmeters for controlling which data to acquire spec or coheregrams from
 % ------------------------------------------------------------------------
 %
animal_set = {'HPa'};
day_set = [5];			% set of days to analyze for all animals ... 
epoch_set = [2 4];		% set of epochs to analyze for all animals ... 
tetrode_set = [1:3];

% Parameters for controlling what data to window, and how to pad samples
% --------
% specify which electrophysiology data to window!
dataToProcess.datType = 'eeggnd';
% specify padding if any. gatherWindowsOfData requires NaN padding right now.
processOptions.windowPadding = NaN;

% Where to save data
% ---------------------
%
saveFolder = './';

%% Pre-processing for Gathering Data Windows

dataToProcess.sampleParams = sampleParams;

% set .animals field to contain who, which day, which epoch, and which
% tetrodes
for a = 1:numel(animal_set)
	
	dataToProcess.animals.(animal_set{a}).days = day_set;
	dataToProcess.animals.(animal_set{a}).epochs = epoch_set;
	dataToProcess.animals.(animal_set{a}).tetrodes = tetrode_set;
	
end

%% Gather Windows of Data

tic
acquisition = gatherWindowsOfData(saveFolder, dataToProcess,...
	processOptions);
toc

%% Description of Tetrodes
% From tetinfo files
%
% -----------------------
% ANIMAL, HPa
% -----------------------
% Tetrodes			Area
% -----------------------
% 1-7		...		CA1
% 8-14		...		iCA1
% 15-20		...		PFC
%
% -----------------------
% ANIMAL, HPa
% -----------------------
% Tetrodes			Area
% -----------------------
% 1-7		...		CA1
% 8-14		...		PFC
% 15-20		...		iCA1


%% Generate Spectrograms

% Of the acquisition, what to turn into spectrograms
dataToProcess.days = day_set; dataToProcess.epochs = epoch_set; 
dataToProcess.tetrodes = tetrode_set; 
dataToProcess.tetrodes2 = 16; % tetrodes2 controls tetrodes in operand 2 of coherogram

% Options that control functional output
dataToProcess.save = 0; dataToProcess.output = 1; dataToProcess.plot = 0;

tic
specgrams = generate_xGrams(acquisition,dataToProcess);
toc

%% Average Across Spectrograms

sets = 'trial';

avg_specgram = averageAcross(specgrams,sets);

%% Plotting and saving

sets=[];
sets.animals = [1];
sets.days = day_set; sets.epochs = epoch_set; sets.tetrodes = tetrode_set;
sets.trials = false;

plotAndSave(avg_specgram,sets);

