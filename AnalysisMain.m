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

%% Putting Data Files on Path and Clearing Variables


% if files.brandeis.edu is in the file system, then add data to path
d = filesep;

if ispc; files_dot_brandeis_edu = '\\files.brandeis.edu\jadhav-lab';
elseif ismac; files_dot_brandeis_edu = '/Volumes/jadhav-lab/';
else files_dot_brandeis_edu = '/home/mcz/DataShare'; end;
path_str = [d 'DATA' d 'sjadhav' d 'HPexpt' d];
path_added = false;


if path_added || (~path_added && exist(files_dot_brandeis_edu, 'dir'))
	
	% Adds all data folders to path and subfolders. For now this is
	% how functions will find data.
	path(path,genpath([files_dot_brandeis_edu path_str 'HPa_direct'])) 
	path(path,genpath([files_dot_brandeis_edu path_str 'HPb_direct']))
	path(path,genpath([files_dot_brandeis_edu path_str 'HPc_direct']))
    path_added = true;
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
 sampleParams.edgeMode.window = [150 150];
 sampleParams.edgeMode.entranceOrExit = 'entrance';
 
 % Parmeters for controlling which data to acquire spec or coheregrams from
 % ------------------------------------------------------------------------
 %
animal_set = {'HPa'};
day_set = [5];			% set of days to analyze for all animals ... 
epoch_set = [2 4];		% set of epochs to analyze for all animals ... 
tetrode_set = [9 12 14];

% Parameters for controlling what data to window, and how to pad samples
% --------
% specify which electrophysiology data to window!
sets.datType = 'eeggnd';
% specify padding if any. gatherWindowsOfData requires NaN padding right now.
processOpt.windowPadding = NaN;

% Where to save data
% ---------------------
%
saveFolder = './';

%% Pre-processing for Gathering Data Windows

sets.sampleParams = sampleParams;

% set .animals field to contain who, which day, which epoch, and which
% tetrodes
for a = 1:numel(animal_set)
	
	sets.animals.(animal_set{a}).days = day_set;
	sets.animals.(animal_set{a}).epochs = epoch_set;
	sets.animals.(animal_set{a}).tetrodes = tetrode_set;
    if exist('tetrode2_set')
        sets.animals.(animal_set{a}).tetrodes2 = tetrode2_set;
    end
	
end

%% Gather Windows of Data

processOpt.output = true; processOpt.save = false;

tic
acquisition = gatherWindowsOfData(saveFolder, sets,...
	processOpt);
toc


%% Generate Spectrograms

% Options that control functional output
processOpt.save = 0; processOpt.output = 1; processOpt.plot = 0;

tic
specgrams = generate_xGrams(acquisition,sets,processOpt);
toc

%% Average Across Spectrograms

sets.average = {'trial'};

avg_specgrams = averageAcross(specgrams,sets);

%% Plotting and saving

plotAndSave(avg_specgrams,sets);

