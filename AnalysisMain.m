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
	
	disp('Adding animal folders to path! ...');
	
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

% ----------------------------------------------------------
% Parameters for circumscribing sample around a point
% --------------------------------------------------------
% How large of radius should we sample

sampleParams.circleParams.radius = 20;       % 20 pixel radius
% Where to sample
% [1 1] denotes [segment_1 end_of_it]
% % sampleParams.circleParams.segment = [1 1];
sampleParams.circleParams.segment = {1, 'final'}; % end of segment 1


% Note: Second number encodes start and end of segment in 0 and 1.
% Eventually we may extend function to request a point that is some
% fraction, e.g. 0.75 from start (0) to end (1) of segment

% ----------------------------------------------------------
% Parameters for controlling which segment transitions to sample
% ----------------------------------------------------------

% sampleParams.segmentTransition = [1 4; 1 5];

% ----------------------------------------------------------
% Parameters for selecting trajectory type to sample
% ---------------------------------------------------------
% Which trajectory type to sample?
sampleParams.trajbound_type = 0 ;            % 0 denotes outbound


% ---------------------------------------------------------------------
% Pameters for controlling edge mode, i.e. triggering on entrance/exit
% ----------------------------------------------------------------------
% Edge mode refers to a mode where we sample from the edges of a choice
% region. Adding it into the struct activates it. Placing a window subfield
% controlls the size of the window in front and behind sample region
% entrance or exit. Its unit is frames.  For 30hz sample rate, [15 15]
% grabs 15 frames in front and behind boundary crossing. entranceOrExit
% subfield controls whether to sample entrance or exit.
 sampleParams.edgeMode.window = [150 150];
 sampleParams.edgeMode.entranceOrExit = 'entrance';
 

 % --------------------------------------------------------------------
 % Parmeters for controlling which data to acquire spec or coheregrams
 % ------------------------------------------------------------------------
    

animal_set = {'HPa'};       
day_set = 2:5;			% set of days to analyze for all animals ...
epoch_set = [2];
tetrode_set = [1];
tetrode_set2 = [17];

averaged_trials = 'both';

% ----------------------------------------------------------------------
% Parameters for controlling what data to window, and how to pad samples
% -----------------------------------------------------------------------

% specify which electrophysiology data to window!
paramSet.datType = 'eeggnd';	% this can read any wave data type

% specify padding if any. gatherWindowsOfData requires NaN padding right
% now, as this tells lets downstream code quickly ignore parts of the eeg
% data that are not relevant to sampling above.
processOpt.windowPadding = NaN;

%%%%%%%% PRE-PROCESSING SUB-SECTION %%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------------------
% Where to save data
% ---------------------
saveFolder = ['./'];

% ---------------------
% Processing options -- whether to output to file, to RAM, or plot
% ---------------------

processOpt.output = true; processOpt.save = false;
processOpt.plot = false;					% Controls plotting during spectrogram extraction -- Section D plots now, so this is an easter egg.
paramSet.processOpt = processOpt;


%% A. Gather Windows of Data

disp('Acquiring windows of data at requested sample points...');

% Acquire from first set of tetrodes

processOpt.otherTetrodes = false;
acquisition = gatherWindowsOfData(saveFolder, paramSet);

if exist('tetrode_set2','var')		% Acquire for TetrodeY Set, if user asked for it
    paramSet.processOpt.otherTetrodes = true;
    acquisition2 = gatherWindowsOfData(saveFolder, paramSet);
end

%% B. Generate Spectrograms

disp('Generating spec- or coherograms...');

if exist('tetrode_set2','var')		% TETRODE PAIRS
    grams = generate_xGrams(acquisition,paramSet,acquisition2);
else								% SINGLE TETRODE SET	
    grams = generate_xGrams(acquisition,paramSet);
end


%% C. Average Spectrograms/Coherograms

disp('Averaging data...');

if exist('tetrode_set2','var')
    paramSet.coherograms=true;
end

paramSet.average = {'trial'};

avg_grams = averageAcross(grams,paramSet);


%% D. Plot and Save Spectrograms/Coherograms

disp('Plotting and saving data...');

    
for trials = [true false]
	paramSet.trials = trials;
	if trials; g = grams; else; g = avg_grams; end
	plotAndSave(g,paramSet, acquisition, acquisition2);
end

%% E. Analyze Spectrograms/Coherograms Components
% This script in this section are temporary and will be replaced by a
% better-designed, more well-commented function.

disp('Grouping desired frequencies and averaging per day...');

% Place desired bandwidth here
paramSet.lower_freq = 6;
paramSet.upper_freq = 12;
paramSet.estimate_best_freq = true;

[grams S_summary C_summary] = ...
	meanInFreqBand(avg_grams, paramSet);


%% F. Plot Analyzed Components
% This script in this section are temporary and will be replaced by a
% better-designed, more well-commented function.

hold on;
PlotSummaryBars;

disp('FINISHED DAY');

