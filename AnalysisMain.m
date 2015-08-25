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
% ANIMAL, HPb
% -----------------------
% Tetrodes			Area
% -----------------------
% 1-7		...		CA1
% 8-14		...		PFC
% 15-20		...		iCA1
%
% ----------------------
% Best for HPb
% ----------------------
% 
%  1,3,4,6 for CA1; 9 for PFC

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
    
     clear all;
    
    path_added = true;
end
    
clear sampleParams acquisition acquisition2 grams avg_grams

%% Parameter Section

% This is where we specifiy which parameters we're interested ... which
% animals, which days/epochs, which tetrodes, and what types of maze and
% electrophysiology parameters to select for.

% Parameters for circumscribing sample around a point
% --------------------------------------------------------
% How large of radius should we sample
sampleParams.circleParams.radius = 15;       % 20 pixel radius
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

    
animal_set = {'HPb'};       
day_set = dy;			% set of days to analyze for all animals ...
epoch_set = 2;
if dy == 1
    epoch_set = 4;
end
tetrode_set = [1];
tetrode_set2 = [9];

averaged_trials = 'both';

% Parameters for controlling what data to window, and how to pad samples
% --------
% specify which electrophysiology data to window!
paramSet.datType = 'eeggnd';
% specify padding if any. gatherWindowsOfData requires NaN padding right now.
processOpt.windowPadding = NaN;

% Pre-processing for Gathering Data Windows

paramSet.sampleParams = sampleParams;

% set .animals field to contain who, which day, which epoch, and which
% tetrodes
for a = 1:numel(animal_set)
	
	paramSet.animals.(animal_set{a}).days = day_set;
	paramSet.animals.(animal_set{a}).epochs = epoch_set;
	paramSet.animals.(animal_set{a}).tetrodes = tetrode_set;
    if exist('tetrode_set2','var')
        paramSet.animals.(animal_set{a}).tetrodes2 = tetrode_set2;
    end
	
end

% Where to save data
% ---------------------
saveFolder = ['./'];

%% Gather Windows of Data

disp('Acquiring windows of data at requested sample points...');

processOpt.output = true; processOpt.save = false;

% Acquire from first set of tetrodes

processOpt.otherTetrodes = false;
acquisition = gatherWindowsOfData(saveFolder, paramSet,...
	processOpt);

if exist('tetrode_set2','var')
    processOpt.otherTetrodes = true;
    acquisition2 = gatherWindowsOfData(saveFolder, paramSet,...
        processOpt);
end


%% Generate Spectrograms

disp('Generating spec- or coherograms...');

% Options that control functional output
processOpt.save = 0; processOpt.output = 1; processOpt.plot = 0;

if exist('tetrode_set2','var')
    grams = generate_xGrams(acquisition,paramSet,processOpt,acquisition2);
else
    grams = generate_xGrams(acquisition,paramSet,processOpt);
end

%% Average Across Spectrograms

disp('Averaging data...');

if exist('tetrode_set2','var')
    paramSet.coherograms=true;
end

paramSet.average = {'trial'};

avg_grams = averageAcross(grams,paramSet);


%% Plotting and saving

disp('Plotting and saving data...');

    
paramSet.trials = true;
plotAndSave(grams,paramSet);

disp('FINISHED DAY');

