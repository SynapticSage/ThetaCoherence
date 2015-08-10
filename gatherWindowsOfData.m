function [acquisition] = ...
	gatherWindowsOfData(dataFolder,dataToGet)
% function gatherWindowsOfData
% for gathering all data for an (animal/prefix epoch day tet) tuple or set of
% tuples. This function will be used to gather up all of the eeg data
% around a point of interest for analysis. The point of interest comes from
% calling a function that detects transitions from segment x to segment y
% on the maze.
%
% INPUTS -----------
%
% dataFolder - the folder containing the relevant piece of data we'd like
% to process
% 
% dataToGet - type = struct
%   This data type is a struct whose fields contain all of the relevant
%   information about which animals, which days, which epochs, and which
%   tetrodes to obtain transition point data for
%
%   --- fields of dataToGet ---
% 
%	'.animals' .. this field is a struct. Each animal to be analyzed gets
%	it's own field. e.g.
%	
%		.animals.HPa
%		.animals.HPb
%
%	Each animal field contains fields describing a list of
%	days, epochs, and tetrodes to acquire for that animal. Reason I've
%	chosen this way is to allow painless multi-animal analysis, by a single
%	function. No for-looping over animals in the Main function calling it.
%	Animals are allowed to each have their own sets of days, epochs,
%	tetrodes.
%   
%   '.datType', .. refers to the data type in the prefix of the file we're
%   to load, be it eeg, theta, thetagnd, et cetera. So e.g.,
%
%		.datType = 'eeg' ", or
%		.datType = 'thetagnd'
%
%	OPTIONALS -- probably won't need to use these
%
%	'.datType_sub' .. (OPTIONAL) refers to the field inside the
%	dataType to read in. This defaults to 'data'. Meaning, if you enter
%	'theta' for .datType and nothing for .datType_subfield, it will window
%	theta{days}{epochs}{tetrodes}.data
%
%	'.datType_field' .. (OPTIONAL) refers to strings that label the columns
%	of a data array. e.g. 
%	theta.field = 'filtered_amplitude instantaneous_phase*10000 envelope_magnitude'
%	User can specify 'filtered_amplitude' here and this function will seek
%	out the column with it.
%																							<----TODO: Implement this
%
%	'.datType_indices' (OPTIONAL) refers to the form of the index in a cell
%	array, e.g. {1,':'}, which would specify entries in data to grab.
%
%	This parameter selects chich type of data to window.
%
%
%   '.sampleParams' .. struct that describes the characteristics of the
%   time points to sample. This structure will include any information
%   about the maze or behavior we might need to gather windows of data.
%   It's a struct giving it the ability to flex to fit new data types in
%   the future if we chose to window around different parameters. It's
%   designed to be robust/extensible, and pretty much just sends this
%   struct straight into acquireSample function to obtain times. In this
%   alpha version, acquireSample can select a times on an entire segment,
%   or on a subset of a segment. Times can also be selected for a
%   trajectory class (inbound or outbound).
%
%		'sampleParams.trajbound_type' = 0 or 1 .. if 0, filter times that
%		are outboud. If 1, filter times that are inbound.
%
%		'sampleParams.circleParams' .. structure that contains data for
%		filtering times circumscribed by a position.
%
%			'sampleParams.circleParams.radius' .. the radius in pixels to
%			detect around the point.
%
%			'sampleParams.circleParams.center' .. specifies [x y] to sample
%			around. Alternatively, one can specify the segment and the
%			method will find the [x y] by filling the .segmentCoordinate
%			field below.
%
%			'sampleParams.circleParams.segment' .. [ segment_integer
%			segment_side], where segment_integer denotes the number of the
%			segment and segment_side encodes the start (0) or end of the
%			segment (1) as 0 or 1.
%   -----------------------------
%
% OUTPUTS ----------
%  
% "acquisition" array such that:
% 
% acquisition(i).animal = animal name
% acquisition(i).data{day,epoch,tetrode} = [] matrix such that each column
% contains a copy of the data with only relevant values for a detected
% trigger time. There are as many columns as there were triggered events.
% 

%% Handling of optional inputs

% if user did not pass in the field to grab inside imported data, e.g.
% 'data' in theta., then let's default to 'data'.
if(~ismember('datType_sub',fields(dataToGet)))
	dataToGet.datType_sub = 'data';
end

% if user did not pass indices, set them
if(~ismember('datType_indices',fields(dataToGet)))
	dataToGet.datType_indices = {':',1};
end


%% Preprocessing Steps

% record initial folder so we can get back to it
initial_folder = pwd;

% change directory into the file address containing the data to acquire
cd(dataFolder);
path(path,genpath(dataFolder)); % all all subfolders to path so we'll definitely be able to detect the data


%% Processing Loop

try % try-catch block in case data is not found, returns to calling folder and THEN (and only then) throws an error .. the folder return would not occur if we allowed matlab to handle the error.
	
% Prepare list of animals to process, creates a cell of them from the
% fields of the animal field in the dataToGet structure.
animal_list = fields(dataToGet.animals);

% Prepare struct, generates one set of windowed data per animal, with data
% indexed by {day, epoch, tetrode}
acquisition.animal = []; % strores animal name
acquisition.data = {};	 % stores a matrix in each {day, epoch, tetrode}

for a = 1:numel(animal_list)
	
	% Assign animal name
	anim = animal_list{a};
	acquisition(a).animal = anim;
	
	% Preallocate cell
	acquisition(a).data = cell(...
		numel(dataToGet.animals.(anim).days), ...
		numel(dataToGet.animals.(anim).epochs), ...
		numel(dataToGet.animals.(anim).tetrodes+1));
	
    for d = dataToGet.animals.(anim).days
        
        % Preprocess the day string to add a 0 before the number if it's less
        % than 10
        if(d < 10)
            day = num2str(['0' num2str(d)]);
        else
            day = num2str(d);
        end
		
        for e = dataToGet.animals.(anim).epochs
			
			%% Acquire run data for (animal, day, epoch)
            
			% Generate the file string from each of the cell elements passed from
			% the nested loop over cells
			file_cell{1} = [anim 'linpos' day ];
			file_cell{2} = [anim 'trajinfo' day ];
			file_cell{3} = [anim 'pos' day ];
			
			% load it all up
			for i = 1:numel(file_cell)
				load(file_cell{i});
			end
			
			% Get epoch of linearized position data!
			data.linpos = linpos{d}{e};
			% Get epoch of trajinfo data!
			data.trajinfo = trajinfo{d}{e};
			% Get epoch of raw position data!
			data.pos = pos{d}{e};

			%% Find times to sample
			
			% Find times!!
			[timesInSample,indicesInSample, start_stop_times, ...
				start_stop_indices] = acquireSample( data, ...
				dataToGet.sampleParams);
			allTimes = data.pos.data(:,1);
			% Get list of continuous time windows - we pass in sample times
			% and well as a list of all times
			
			%% Window out the correct data per tetrode
            for t = dataToGet.animals.(anim).tetrodes
                
				% Acquire matrix of windowed data
                [acquisition(a).data{d,e,t}, acquisition(a).time_vec{d,e,t}] ...
					= windowData(...
					dataToGet.datType, dataToGet.datType_sub, dataToGet.datType_indices, ...
					anim,d,e,t,...
					start_stop_times);
                
			end % of tetrode loop
			
		end % of epoch loop
	end % of day loop
end % of animal loop

% Catching errors
catch ME
% Decommision the folders we added into the path at the start of the
% function.
disp('ERROR IN gatherWindowOfData...');
disp('Throwing exception data...');
rmpath(genpath(dataFolder));
cd(initial_folder);
throw(ME);

end












%% Helper functions -----------------------------------------
% --- Helper function: processTuple
function [winData, time_vec] = windowData(dat, dat_sub, dat_ind,...
		anim, day, epo, tet, ...
		windowTimes)
    
    % Preprocess the day string to add a 0 before the number if it's less
    % than 10
    if(day < 10)
        day_str = ['0' num2str(day)];
    else
        day_str = num2str(day);
	end
	
	% Preprocess the tetrode string to add a 0 before the number if it's less
    % than 10
	if(tet < 10)
		tet_str = ['0' num2str(tet)];
	else
		tet_str = num2str(tet);
	end
	
	% ind is a cell that will store our indices
	I = dat_ind;

    %% Acquire LFP or Spike data at these detected times
    file_string = [ anim dat day_str '-' num2str(epo) '-' tet_str ];
    data_import = load(file_string);
    
    % Have to assign the variable that comes out of load, which is itself
    % could be a variety of names to a general name
    temp = [];
    eval(['temp = data_import.' dat '{' num2str(day) '}' ...
		'{' num2str(epo) '}{' num2str(tet) '};']);
    
    % Now we need to estimate the time corresponding to the points in the
    % data
    time_start = temp.starttime;
    time_end = temp.starttime + ...
		(1/temp.samprate) * size( temp.(dat_sub)(I{1},I{2}) , 1);   
    % Estimate time vector for the data set
    time_vec = linspace(time_start, time_end, ...
		size(temp.(dat_sub)(I{1},I{2}),1));										% TO IMPROVE : Need to allow user to input field of data, and use that to determine column number
    
    % Create 2D matrix that will hold a window of data per trigger time as
    % detected by segment transitions
    winData = zeros( size(windowTimes,1), numel(time_vec) );
    
    % Detect the class of data in the imported data ... e.g. int16, int32,
    % double, or float, and then store that. Below we will have to convert
    % the logical we multiply, so that matlab doesn't bitch about type
    % incompatability.
    data_class=class(temp.data);
    
    
    % Grab all of the data in the windows of time
    for ind = 1:size(windowTimes,1)
        
        % Create logical vector for selecting the proper data to store
        times_of_interest = (time_vec > windowTimes(ind,1)) & ...
            (time_vec < windowTimes(ind,2));
        
        % Multiply by logical to zero out irrelevant data, and store vector
        % into a column of the matrix.
        winData(ind,:) = cast(times_of_interest', data_class).* ...
			temp.(dat_sub)(I{1},I{2});											% TO IMPROVE: Need to AUTOMATICALLY  cast times_of_interest to whatever the data's type is!

	end
    
    % Return the data points
    return;
    
end

%% Post-processing phase
% return to calling folder and remove dataFolder tree from the path
rmpath(genpath(dataFolder));
cd(initial_folder);

end

