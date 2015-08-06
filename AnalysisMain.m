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

%% DEBUG SECTION: show acquireSample method works

% Load all three data types for day, epoch .. squeeze into data struct
load HPalinpos05;
data.linpos = linpos{5}{2};
load HPapos05;
data.pos = pos{5}{2};
load HPatrajinfo05;
data.trajinfo = trajinfo{5}{2};

% Run the acquireSample function
[time, indices] = acquireSample(data,sampleParams)

% WORKS!

%% TEST SECTION: show gatherWindowsofData works

dataFolder = '~/Documents/MATLAB/LabProjects/DATA';
animals = {'HPa'};
day_set = [5];			% set of days to analyze for all animals ... 
epoch_set = [2];		% set of epochs to analyze for all animals ... 
tetrode_set = [1];		% set of tetrodes to analyze for all animals ... 
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
dataToGet.datType = 'theta';

% RUN FUNCTION!
acquisition = gatherWindowsOfData(dataFolder, dataToGet);

%% MAIN ANALYSIS SECTION -- Theta Coherence Analysis Guts


