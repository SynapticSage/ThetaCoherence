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
if(isfield(sampleParams, 'circleParams'))
    
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
			
            % Acquire the x coordinate of the segment
            sampleParams.circleParams.center(1) = ...
                segmentCoords(segment(1), segment(2)*2 + 1);
            % Acquire the y coordinate of the segment
            sampleParams.circleParams.center(2) = ...
                segmentCoords(segment(1), segment(2)*2 + 2);
            
        end
    end
	
	% feed animal (x,y) position list and selection parameters
	circ_subset_indices = circumscribePoint( data.pos.data(:,2:3), ...
		sampleParams.circleParams);
	
	% WE have indices that belong, but we need a logical vector
	circ_logical = zeros(size(all_times));
	circ_logical(circ_subset_indices) = ...
		~circ_logical(circ_subset_indices);
	
	% Adjust the sample
	sample = sample & circ_logical;
    sample_times(~sample) = 0;
	
end

%% Subset out the trajectory

if(isfield(sampleParams,'trajbound_type'))
	
	% Grab a subset of times corresponding to the starts and stops for the
	% particular trajectory type
	subset_trajbound_indices = find(sampleParams.trajbound_type ...
		== data.trajinfo.trajbound);	% subsetting
	trajbound_startStops = ...
		data.trajinfo.trajtime(subset_trajbound_indices,:);	% start-stop times for subset
	
	% For loop over each start-stop time pair, and acquire a logical vector
	% describing which elements are in the pair of times. Use logical OR to
	% gradually create a picture of all times to be investigated.
	
	logical_onepath			= zeros(size(all_times));	% detects points in a single trajectory per loop iteration
	logical_times			= zeros(size(all_times));	% updates to catalogue all points per iteration
	
	for i = 1:size(trajbound_startStops,1)
		
		% Find which times in the (start, stop) boundary
        % EDIT: changed to sample so that we have a sense of the existing
        % sample already
		logical_onepath = ( sample_times > trajbound_startStops(i,1) ) & ...
			( sample_times < trajbound_startStops(i,2) );
        
        % Subset out so that only one occurs per trajcetory
        diff_onepath = diff(logical_onepath);
        % initial point of only first path
        initial = find(diff_onepath == 1); 
        initial = initial(1) + 1;
        % end point of only first path
        final = find(diff_onepath == -1);
        final = final(1);
        % change logical to reflect only the first found trajcetory
        logical_onepath = zeros(size(logical_onepath));
        logical_onepath(initial:final) = 1;
		
		% Add the points found for ith trajectory to total record of times
		logical_times = logical_times | logical_onepath;
		
	end
	
	% Update the sample
	sample = sample & logical_times;
	
	% Remove variables just used from namespace
	clear logical_start_stop subset_trajbound_indices ...
		trajbound_startStops;
	
end

%% Return total sample
%i.e. correct times from sample logical
times = all_times(sample);
indices = find(sample);
[start_stop_times, start_stop_indices] = ...
	generateContiguousSamples(sample, all_times);

%% If edgeMode on, then transform into edge sample

if ismember('edgeMode', fields(sampleParams))

% This recasts all times and indices in the manner described in the
% function header of generateTimeAroundEdges
[times, indices, start_stop_times, start_stop_indices] = ...
    generateTimeAroundEdges(all_times, start_stop_indices, ...
    sampleParams.edgeMode.window);

end












%% HELPER FUNCTIONS ------------------------------------

function [ indices ] = circumscribePoint( trajectoryData, circumParams )
%CIRCLESAMPLE returns indices for a circle of points around a position
%   circleSample obtains indices of a circle of points around a position
%   provided by the user.
%
% ------ INPUTS
%
% 'trajectoryData',
%	matrix containing fields detailing the trajectory structure to find
%	the proper indices on ... trajectoryData is a time * 2 matrix, where
%	the first column is x and the second column is y coordinate.
%
% 'circumParams'
%	structure containing fields detaling the parameters controlling the
%	sampling process.
%
%	'circumParams.radius' controls the sampling radius
%	'circumParams.center' = 1x2 [x y] coordinate of the point to draw the
%	radius around and sample from.
%
% ------ OUTPUTS
%
% indices
%	contains the indices that describe points in the trajectory data that
%	are inside the circle specified by the circumParams


%% Pre-processing phase .. simplify variable names
xc = circumParams.center(1); yc = circumParams.center(2);

x_pos = trajectoryData(:,1); y_pos = trajectoryData(:,2);

%% Processing, pulling points

distance_from_center = sqrt(( x_pos - xc ).^2 + (y_pos - yc).^2);

indices = find(distance_from_center < circumParams.radius);


end

function [start_stop_times, start_stop_indices] = ...
		generateContiguousSamples(Samples, allTimes)
% This function detects contiguous times in the sample times and outputs,
% and re-casts the times into a list of starts and stops. Each row is a
% start stop pair. In between each start stop pair are contiguous times.
%

% find start of relevant idx (+1 since diff)
diff_sample_start_idx=find(diff(Samples)==1)+1; 
% find end of relevant idx
diff_sample_end_idx=find(diff(Samples)==-1);
% gen times from master time vector
start_stop_times=[allTimes(diff_sample_start_idx), allTimes(diff_sample_end_idx)];
% return already found idxs
start_stop_indices=[diff_sample_start_idx, diff_sample_end_idx];

end

function [times, indices, start_stop_times, start_stop_indices] = ...
        generateTimeAroundEdges(all_times, ssi, window)
    % This function takes in the times generated and converts to times
    % padded around the beginnings and ends of a time sample, and ignores
    % the middle of the sample so that 00000|111111|000000 with 1's
    % representing sampled time and |'s representing sample edges becomes
    % 0011|110011|110000.
    %
    % INPUTS
    % 
    %
    % OUTPUTS
    %
    %
    
    % 4 x N matrix, where the first two columns hold the start/stop times
    % of the beginning of the sample period and the last two columns hold
    % the start/stop times of the end of the sample period.
    
	% Create entrance window .. the start and stop time
	start_stop_indices{1} = [ssi(:,1) - window(1), ssi(:,1) + window(2)];
	start_stop_indices{2} = [ssi(:,2) - window(1), ssi(:,2) + window(2)];
	
	% Break if edge cases found! -- this will be thrown out if our data
	% fails to trigger them
	assert(min(min(start_stop_indices{1})) > 0);
	assert(max(max(start_stop_indices{2})) > numel(all_times) );
	
    % NOW WE HAVE TO RE-DO all other representations of sample times ..
    % they are equivalent forms, but this function must return them.
    
	% REDOING start_stop_times
    start_stop_times{1} = all_times(start_stop_indices{1});
	start_stop_times{2} = all_times(start_stop_indices{2});
    
    % REDOING the sample
    new_sample = zeros(size(all_times));
	sst = start_stop_times;
    for ind = 1:size(start_stop_times.initEdge,1)
        
        s = (all_times > sst{1}(ind,1) & all_times < sst{2}(ind,2)) ...
            | (all_times > sst{1}(ind,1) & all_times < sst{2}(ind,2));         % TODO vector-ize this for-loop
        
        new_sample = new_sample | s;
        
    end
    
    % REDOING the indices
    indices = find(new_sample);
    
    % REDOING the times
    times = all_times(indices);
            
end

end
