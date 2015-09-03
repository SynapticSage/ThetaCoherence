function [acquisition beh_data] = ...
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
%
%		'sampleParams.edgeMode.entranceOrExit  .. a string that can take
%		the value of 'entrance' or 'exit'. Determines whether to take
%		window of time when the animal enters or exits the boundary region.
%
%
%	'processOpt' .. struct containing options for the process
%	of sample triggered data windowing.
%
%		'.samplePArams.processOpt.windowPadding' .. If not provided,
%		automatically set to 0, in which case time points outside sample
%		are set to 0's, and length of complete trace of data is preserved.
%		If padding is set to [], it deletes non-sample data, removing
%		padding. This has the effect of only storing the actual values
%		associated with a window of data. If set to NaN, you can retain the
%		length of the vector, but be able to detect what's not sample.
%		Padding of any type takes up extra memory. Setting [] yields the
%		most memory-efficient acquisitions.
%
%
%       'sampleParams.processOpt.singleTrace' .. If provided, grabs a
%       single trace containing all windows of data.
%
%
%   -----------------------------
%
% OUTPUTS ----------
%  
% "acquisition" array such that:
% 
% acquisition(i).animal = animal name
% acquisition(i).data{day,epoch,tetrode} = [] matrix such that each rows
% contains a copy of the data with only relevant values for a detected
% trigger time. There are as many rows as there were triggered events.
%
% Other outputs including timing information follow the form of .data
% field.

%% Handling of optional inputs

% if user did not pass in the field to grab inside imported data, e.g.
% 'data' in theta., then let's default to 'data'.
if ~ismember('datType_sub',fields(dataToGet))
	dataToGet.datType_sub = 'data';
end
% if user did not pass indices, set them
if ~ismember('datType_indices',fields(dataToGet))
	dataToGet.datType_indices = {':',1};
end
% if user did not pass data type, set it
if ~ismember('datType', fields(dataToGet)) ...
		|| isempty(dataToGet.datType)
	dataToGet.datType = 'eeggnd';
end
if isfield(dataToGet, 'processOpt')
	processOpt = dataToGet.processOpt;
end
% if did not pass output option, set
if ~ismember('output', fields(processOpt) )
	processOpt.output = true;
end
% if did not pass save option, set
if ~ismember('save', fields(processOpt) )
	processOpt.save = false;
end

if nargin < 2				% TODO .. bad way to detect default .. fix
	processOpt.windowPadding = 0;
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
	
	% Preallocate cells
	acquisition(a).data = cell(...
		numel(dataToGet.animals.(anim).days), ...
		numel(dataToGet.animals.(anim).epochs), ...
		numel(dataToGet.animals.(anim).tetrodes));
    beh_data(a).data = cell(...
        numel(dataToGet.animals.(anim).days), ...
		numel(dataToGet.animals.(anim).epochs));
	
    for d = dataToGet.animals.(anim).days
        
        % Preprocess the day string to add a 0 before the number if it's less
        % than 10
        if(d < 10)
            day = num2str(['0' num2str(d)]);
        else
            day = num2str(d);
        end
		
        for e = dataToGet.animals.(anim).epochs
			
			% If there's an exception, where we for a single day
			% process a different epoch, enforce it
            exception=[];
			EnforceException;
			
			%% Acquire run data for (animal, day, epoch)
            
			% Generate the file string from each of the cell elements passed from
			% the nested loop over cells
            clear file_cell;
			file_cell{1} = [anim 'linpos' day ];
			file_cell{2} = [anim 'trajinfo' day ];
			file_cell{3} = [anim 'pos' day ];
			
			% load it all up
			for i = 1:numel(file_cell)
				try
				load(file_cell{i});
				catch ME
					disp([file_cell{i} ' not found !!! Check your path.']);
					throw(ME)
				end
			end
			
			% Get epoch of linearized position data!
			data.linpos = linpos{d}{e};
			% Get epoch of trajinfo data!
			data.trajinfo = trajinfo{d}{e};
			% Get epoch of raw position data!
			data.pos = pos{d}{e};
            clear pos linpos trajinfo;

			%% Find times to sample
			
			% Find times!!
			[timesInSample,indicesInSample, start_stop_times, ...
				start_stop_indices] = acquireSample( data, ...
				dataToGet.sampleParams);
			allTimes = data.pos.data(:,1);
			% Get list of continuous time windows - we pass in sample times
			% and well as a list of all times
			
            
            if exist('processOpt') && ...
                    ismember('otherTetrodes',fields(processOpt)) && ...
                    processOpt.otherTetrodes
                tetrodes = dataToGet.animals.(anim).tetrodes2;
            else
                tetrodes = dataToGet.animals.(anim).tetrodes;
            end
            
            for t = tetrodes
				
				% Display processing
				disp(sprintf('Processing day %d, ep %d, tet %d', ...
					d,e,t));
				
				% If there's an exception, where we for a single day
				% process a different epoch, enforce it
				EnforceException;
                
				%% Window out the correct data per tetrode
				% Acquire matrix of windowed data
                [windowedData, time_vec] ...
					= windowData(...
					dataToGet.datType, dataToGet.datType_sub, dataToGet.datType_indices, ...
					anim,d,e,t,...
					start_stop_times, indicesInSample, ...
					processOpt);
				
				%% Add to output if requested
				if processOpt.output
					
					acquisition(a).data{d,e,t} = windowedData;
% 					acquisition(a).time_vec{d,e,t} = windowedData;
                    
                    beh_data(a).sst{d,e} = start_stop_times;
                    beh_data(a).ssi{d,e} = start_stop_indices;
                    beh_data(a).pos{d,e} = data.pos;
                    beh_data(a).linpos{d,e} = data.linpos;
                    beh_data(a).trajinfo{d,e} = data.trajinfo;
					
				end
				
				%% Add to save if requested
				if processOpt.save
					
					OutputsToSave.data = windowedData;
					OutputsToSave.time_vec = time_vec;
                    OutputsToSave.sst = start_stop_times;
                    OutputsToSave.ssi = start_stop_indices;
					
					SaveFileCharacteristics.animal = acquisition(a).animal;
					SaveFileCharacteristics.data_name = 'acquisition';
					SaveFileCharacteristics.numerical_address = [d e t];
					
					saveOutput(SaveFileCharacteristics, OutputsToSave);
					
				end
                
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
	
	line = {ME.stack.line}; name= {ME.stack.name};
    for section = 1:numel(line)
        disp(sprintf('Line %d: %s', ...
            line{section}, name{section}));
    end

    throw(ME);
end

%% Post-processing phase
% return to calling folder and remove dataFolder tree from the path
rmpath(genpath(dataFolder));
cd(initial_folder);

return;		% Exit function










%% HELPER FUNCTIONS -----------------------------------------

% --- Helper function: windowData
function [winData, time_vec] = windowData(dat, dat_sub, dat_ind,...
		anim, day, epo, tet, ...
		windowTimes, indicesInSample, ...
		processOpt)
	
	%% Pre-processing
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
	
	% I is a cell that will store our indices
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
    
    % Detect the class of data in the imported data ... e.g. int16, int32,
    % double, or float, and then store that. Below we will have to convert
    % the logical we multiply, so that matlab doesn't bitch about type
    % incompatability.
    data_class=class(temp.data);
    
    
    % Grab all of the data in the windows of time
    if ismember('singleTrace',fields(processOpt)) && ...
            processOpt.singleTrace % SINGLE-TRACE MODE
        
        temp =  temp.(dat_sub)(I{1},I{2});
        temp(~indicesInSample) = processOpt.windowPadding;
        winData = temp;
        
    else % MULTI-TRACE MODE
        
        % Create 2D matrix that will hold a window of data per trigger time as
        % detected by segment transitions
        winData = zeros( size(windowTimes,1), numel(time_vec) ); 
        
        if ~isempty(processOpt.windowPadding)
%             for ind = 1:size(windowTimes,1)
% 
%                 % Create logical vector for selecting the proper data to store
%                 single_trial_of_interest = (time_vec > windowTimes(ind,1)) & ...
%                     (time_vec < windowTimes(ind,2));
% 
%                 % Multiply by logical to zero out irrelevant data, and store vector
%                 % into a column of the matrix.
%                 winData(ind,:) = cast(single_trial_of_interest', data_class).* ...
%                     temp.(dat_sub)(I{1},I{2});
% 
%                 % Add padding if it's specified
%                 if processOpt.windowPadding ~= 0			
%                     winData(ind,~single_trial_of_interest) = ...
%                         processOpt.windowPadding;
%                 end
% 
%             end
			%% REWRITTEN VECTORIZED WINDOWING -- much faster!
			T = repmat(time_vec,[size(windowTimes(:,1)),1]);
			W_start = repmat(windowTimes(:,1),[1,size(time_vec,2)]);
			W_end = repmat(windowTimes(:,2),[1,size(time_vec,2)]);
			D = repmat(temp.(dat_sub)(I{1},I{2})',[size(windowTimes(:,1)),1]);
			
			trials_of_interest = T > W_start & T < W_end;
			
			winData = cast(trials_of_interest, data_class).* ...
                     D;
				 
			if processOpt.windowPadding ~= 0			
                    winData(~trials_of_interest) = ...
                        processOpt.windowPadding;
            end


        else
            %TODO write situation for [] padding
        end
	end
		
end

% --- Helper function: saveOutput
function saveOutput(SaveFileCharacteristics, OutputsToSave)
	% Exists so that data can be saved per processing cyle instead of
	% pushed into RAM. If an option is turned on, the function will save to
	% hard-drive results instead of throwing into RAM. 4- and 5-dimensional
	% cell arrays can be positively huge in memory, even when their
	% elements are empty.
	
	% Setup shortened names for header strings
	animal = SaveFileCharacteristics.animal;
	data_name = SaveFileCharacteristics.data_name;
	
	% Create string for numerical address
	numerical_address_string = [];
	for num = SaveFileCharacteristics.numerical_address
		numerical_address_string = [numerical_address_string ...
			num2str(num) '-'];
	end
	% Remove last '-'
	numerical_address_string = numerical_address_string(1:end-1);
	
	% Create filename
	filename = [animal data_name numerical_address_string];
	
	% Save all fields in OutputsToSave struct as individual variables,
	% -struct option seperates out the fields
	save(filename,'-struct', 'OutputsToSave');
	
	end

end

