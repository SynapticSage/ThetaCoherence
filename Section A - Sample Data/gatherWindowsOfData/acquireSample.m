function [times, indices, start_stop_times, start_stop_indices] = ...
	acquireSample(data, sampleParams)
% acquireSample
% 
% This function will be used to simplify the process of selecting
% particular data from the complete trajcetories of animals.
%
% INPUTS
% -----------------------
%
% data, contains general data from which we might want to generate a sample
% of times from
%
%	data.linpos		... all linearized position data
%	data.pos		... all raw position data
%	data.trajinfo	... 
%
% sampleParams ...
%	struct that can contain a variety of data types. For starters,
%	I've added three selection criteria, though I expect the function's
%	selection criteria to increase over time.
%   
%   FIELDS - each field is OPTIONAL, and acts to further constrain the
%   sampled times
%
%   'sampleParams.trajbound_type' = 0 or 1 .. if 0, filter times that are
%   outboud. If 1, filter times that are inbound.
%
%   'sampleParams.circleParams' .. structure that contains data for
%   filtering times circumscribed by a position.
%
%       'sampleParams.circleParams.radius' .. the radius in pixels to
%       detect around the point.
%
%       'sampleParams.circleParams.center' .. specifies [x y] to sample
%       around. Alternatively, one can specify the segment and the method
%       will find the [x y] by filling the .segmentCoordinate field below.
%
%       'sampleParams.circleParams.segment' ..
%       [ segment_integer segment_side], where segment_integer denotes the
%       number of the segment and segment_side encodes the start (0) or end
%       of the segment (1) as 0 or 1.
%
%	'sampleParams.edgeMode' .. resets the sampling method to grab from the
%	edges of the detected sampling periods, a certain window around each
%	edge. This is a struct, and if it exists, acquireSample will enter this
%	mode.
%
%		'sampleParams.edgeMode.window' .. = [indices_before indices_after]
%		This tells the method to sample indices_before time points before
%		and indices_after time points after edges of sample, as defined by
%		00001111 the interface between sampling (1) and non-sampling (0)
%		region.
%
%	NOTES: I'm expecting this struct will be expanded over time to encopass
%	greater and greater levels of selection criteria. I think this function
%	could beecome useful to future analyses, if we make it robust and
%	expandable.
%
% OUTPUTS
% ---------------------
% 'times' ... all times that fall within sampleParams criteria
%
% 'indices' ... all indices that fall within sampleParams criteria
%
% 'start_stop_times' ... the beginning and end of each sample period, where
% each pair is stored in a row and start stop in columns repsectively. So,
% 
%     [ start_1 end_1] 
%     [ start_2 end_2]
%     [ ... ... ...  ]
%     [ start_N end_N]
% 
% If edge_mode is on, then it's has a slightly different output, where 
% start_stop_times is a struct, with fields init_edge and term_edge that
% store start_stop value for those respectively.
%
% 'start_stop_indices' ... same, except with vector indices instead of times.
%

all_times = data.linpos.statematrix.time;
sample = ones(size(all_times));				% Sample, a logical vector describing 
										% time entries that belong in our sample .. 
										% Each section of code below, a
										% constraint test is performed, and
										% the sample is reduced by 0'ing
										% irrelevant time points and 1'ing
										% relevant points.
sample_times = all_times;


%% Subset out radius around points of interest
% This is the section where, if the user inputs points and radii to sample
% around, we move through each point and find the times that fall inside
% circumscribed regions

% Subset out circle of data IF user has provided the field. Do not
% circumscribe if the user has not provided it.
if isfield(sampleParams, 'circleParams')
    
    % If the user specifies the point to sample in the parameters, use
    % that, otherwise, use other criteria. For now, this other criteria can
    % only be segment.
    if( ~isfield(sampleParams.circleParams, 'center') )
        if(isfield(sampleParams.circleParams, 'segment'))
            % User has given a segment input, so we will extract it from
            % the data
            
            % Simplify variable name we will use, for readability
            segmentCoords = data.linpos.segmentInfo.segmentCoords;
			segment = sampleParams.circleParams.segment;
			
			% If segment is a cell, then parse it
			if iscell(segment)
				if ischar(segment{2}) && strcmp(segment{2},'initial')
					segment = [segment{1} 0];
				elseif ischar(segment{2}) && strcmp(segment{2},'final')
					segment = [segment{1} 1];
				else
					disp('ERROR! You passed a cell with an invalid input.');
				end
			end
			
			% Acquire the x coordinate of the segment
			sampleParams.circleParams.center(1) = ...
				segmentCoords(segment(1), segment(2)*2 + 1);
			% Acquire the y coordinate of the segment
			sampleParams.circleParams.center(2) = ...
				segmentCoords(segment(1), segment(2)*2 + 2);
            
        end
    end
    
	% Feed animal (x,y) position list and selection parameters
    trajectoryData= data.pos.data(:,2:3);
    % Setup point to create radius around
    xc = sampleParams.circleParams.center(1); yc = sampleParams.circleParams.center(2);
    x_pos = trajectoryData(:,1); y_pos = trajectoryData(:,2);
    % Find set of distances from that point
    distance_from_center = sqrt(( x_pos - xc ).^2 + (y_pos - yc).^2);
    error_term = mean(diff(abs(sqrt(diff(trajectoryData(:,1).^2+...
        trajectoryData(:,2).^2)))),'omitnan');
    % If user selected rad=0, then implement special algorith, else if
    % radius smaller than typical positional change in pos data then add an
    % error term, else carry on with standard algorithm
    if sampleParams.circleParams.radius < error_term
        sampleParams.circleParams.radius = ...
            sampleParams.circleParams.radius + error_term;
    end
    
    % Get subset of indices that fall inside the radius of circle
    circ_subset_indices = ...
        find(distance_from_center <= sampleParams.circleParams.radius);
	
	% WE have indices that belong, but we need a logical vector
	circ_logical = zeros(size(all_times));
	circ_logical(circ_subset_indices) = ...
		~circ_logical(circ_subset_indices);
	
	% Adjust the sample
	sample = sample & circ_logical;
    sample_times(~sample) = 0;
end

%% Subset out segment transition, if requested
% If segment transition filtering is turned on, then the function will
% operate to grab time points where exiting a segment x and starting a
% sample y. If edge mode is turned on 'entrace' option, will give you
% window around exiting x and 'exit' will give you a window of times around
% the first detection on y.

if isfield(sampleParams,'segmentTransition')
	
	transitions = sampleParams.segmentTransition;
	segmentIndex = data.linpos.statematrix.segmentIndex;
	
	% Mark out all data on non-interesting segments
	interesting_segs = unique(transitions);
	uninteresting_seg_loc = ones(size(segmentIndex));
	for seg = interesting_segs'
		uninteresting_seg_loc = uninteresting_seg_loc & ...
			segmentIndex ~= seg;
	end
	segmentIndex(uninteresting_seg_loc) = NaN;
	
	seg_diff = diff(segmentIndex);
	requested_diff = transitions(:,2) - transitions(:,1);
	
	logical_singtrans		= zeros(size(all_times));	% detects all segment transitions of certain type at all times per loop iteration
	logical_alltrans	= zeros(size(all_times));	% updates to catalogue all points per iteration
	for i = 1:numel(requested_diff)
		
		logical_singtrans = [seg_diff == requested_diff(i); 0];
		logical_alltrans = logical_singtrans | logical_alltrans;
	end
	
	
	clear segmentIndex transitions seg_diff requested_diff;
	clear logical_matchtrans;
	
	% Adjust the sample
	sample = sample & logical_alltrans;
    sample_times(~sample) = 0;
end

%% Subset out the trajectory

if isfield(sampleParams,'trajbound_type')
	
	% Grab a subset of times corresponding to the starts and stops for the
	% particular trajectory type
	subset_trajbound_indices = find(sampleParams.trajbound_type ...
		== data.trajinfo.trajbound);	% subsetting
	trajbound_startStops = ...
		data.trajinfo.trajtime(subset_trajbound_indices,:);	% start-stop times for subset
	
	% For loop over each start-stop time pair, and acquire a logical vector
	% describing which elements are in the pair of times. Use logical OR to
	% gradually create a picture of all times to be investigated.
	
	logical_onetraj			= zeros(size(all_times));	% detects points in a single trajectory per loop iteration
	logical_alltraj			= zeros(size(all_times));	% updates to catalogue all points per iteration
	
	for i = 1:size(trajbound_startStops,1)
		
		% Find which times in the (start, stop) boundary
        % EDIT: changed to sample so that we have a sense of the existing
        % sample already
		logical_onetraj = ( sample_times >= trajbound_startStops(i,1) ) & ...
			( sample_times <= trajbound_startStops(i,2) );
        
        % Subset out so that only one occurs per trajcetory
        diff_onepath = diff(logical_onetraj);
        % initial point of only first path
        initial = find(diff_onepath == 1);
        if isempty(initial)
            continue;
        end
        initial = initial(1) + 1;
        % end point of only first path
        final = find(diff_onepath == -1);
        if isempty(final)
            final = initial + 1;
        else
            final = final(1);
        end
        % change logical to reflect only the first found trajcetory
        logical_onetraj = zeros(size(logical_onetraj));
        logical_onetraj(initial:final) = 1;
        
%         logical_onepath = logical(logical_onepath);
%         hold off;
%         plot(data.pos.data(:,2), data.pos.data(:,3),'--');
%         hold on;
%         plot(data.pos.data(logical_onepath,2),data.pos.data(logical_onepath,3),'-*');
		
		% Add the points found for ith trajectory to total record of times
		logical_alltraj = logical_alltraj | logical_onetraj;
		
        start_stop_indices(i,:)= [initial final];
        start_stop_times(i,:)= [all_times(initial) all_times(final)];
        
	end
	
	% Update the sample
	sample = sample & logical_alltraj;
	
	% Remove variables just used from namespace
	clear logical_start_stop subset_trajbound_indices ...
		trajbound_startStops;
	
end


%% Remove empty indices, samples that didn't match criteria
removal = start_stop_indices == 0;
if any(removal)
    start_stop_indices(removal) = [];
    start_stop_indices = reshape(start_stop_indices, numel(start_stop_indices)/2,2);
    start_stop_times(removal) = [];
    start_stop_times = reshape(start_stop_times, numel(start_stop_times)/2,2);
end

%% If edgeMode on, then transform into edge sample

if isfield(sampleParams,'edgeMode')

% This recasts all times and indices in the manner described in the
% function header of generateTimeAroundEdges

[times, indices, start_stop_times, start_stop_indices] = ...
    generateTimeAroundEdge(all_times, start_stop_indices, ...
    sampleParams.edgeMode.window, ...
	sampleParams.edgeMode.entranceOrExit);
else
    
    indices = find(sample);
    times = all_times(indices);

end












%% HELPER FUNCTIONS ------------------------------------


function [times, indices, start_stop_times, start_stop_indices] = ...
        generateTimeAroundEdge(all_times, ssi, window, edge_string)
    % This function takes in the times generated and converts to times
    % padded around either beginnings or ends of a time sample, and ignores
    % the middle of the sample so that 00000|111111|000000 with 1's
    % representing sampled time and |'s representing sample edges becomes
    % 0011|110000|00000 or 0000|000011|11000.
    %
    % INPUTS
    % 
    %
    % OUTPUTS
    % 
    
    if strcmp(edge_string, 'entrance')
		edge = 1;
	elseif strcmp(edge_string,'exit')
		edge = 2;
	end
    
	% Create entrance window .. the start and stop time
	start_stop_indices = [ssi(:,edge) - window(1), ssi(:,edge) + window(2)];
	
	% When we investigate other segments, other than 1, windows can go out
	% of bounds! Make any that do NaN. This is because pos starts at the
	% moment the tracker starts. TODO not sure if best solution .. but is a
	% problem. Must be set []. If simply move -x into range, it throws off
	% sampling later down the pipeline.
	illegal_indices = start_stop_indices(:,1) < 1;
	start_stop_indices(illegal_indices,:) = [];
	
    % NOW WE HAVE TO RE-DO all other representations of sample times ..
    % they are equivalent forms, but this function must return them.
    
	% REDOING start_stop_times
    start_stop_times = all_times(start_stop_indices);
    % REDOING the sample
    new_sample = zeros(size(all_times));
	sst = start_stop_times;
    
    
    
    for ind = 1:size(start_stop_times,1)
		
        s = all_times > sst(ind,1) & all_times < sst(ind,2);
        new_sample = new_sample | s;
		
	end
    % REDOING the indices
    indices = find(new_sample == 1);
    % REDOING the times
    times = all_times(indices);
            
end

end
