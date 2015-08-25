function [avg_grams] = averageAcross2(grams,paramSet)

	%% Default options
	if ~ismember('average_dat_type', fields(paramSet))
% 		averaging_fields = {'S'};		% What fields to average
		disp('No averaging fields provided! Entering keyboard mode to allow fix.');
		keyboard;
	else
		averaging_fields = paramSet.average_dat_type;
	end
	
	if ismember('dim2avg',fields(paramSet))
		dim2avg = paramSet.dim2avg;		% User can pass in set of dimension to average here
		dimension_inputted = true;
	else
		dimension_inputted = false;
	end

	%% Decide dimension to average
	while ~dimension_inputted
		
		if ~ismember('average_type', fields(paramSet))
			paramSet.average_type = '';
		end
		
		switch paramSet.average_type
			
			case 'trials'
				dim2avg = 4;	
				dimension_inputted = true;
			case 'tetrodes'
				dim2avg = 3;
				dimension_inputted = true;
			case 'days'
				dim2avg = 1;
				dimension_inputted = true;
			case 'epochs'
				dim2avg = 2;
				dimension_inputted = true;
			otherwise
				disp('Error: No dimension inputted, please assist:')
				keyboard;
		end
	end

	%% Make matrix of specgram data
	% This section makes plain matrices of each data type to average,
	% completely amenable to averaging.
	
	spec_cell = grams.output;
	temp_struct = [];
	allocated_data = false;
	
	num_i1 = size(spec_cell,1);
	num_i2 = size(spec_cell,2);
	num_i3 = size(spec_cell,3);
	num_i4 = size(spec_cell,4);
	num_i5 = size(spec_cell,5);
	
	for field = averaging_fields
	for i1 = 1:size(spec_cell,1)
	for i2 = 1:size(spec_cell,2)
	for i3 = 1:size(spec_cell,3)
	for i4 = 1:size(spec_cell,4)
	for i5 = 1:size(spec_cell,5)
		
		
		maybe_spec_data = spec_cell{i1,i2,i3,i4,i5};
		
		if isstruct(maybe_spec_data)
			
			if ismember(field, fields(maybe_spec_data))
			if ~allocated_data
				spec_gram_size = size(maybe_spec_data.(field{1}));
			% ALLOCATE and set all zero data to NaN
				data.(field{1}) = NaN * ones(num_i1, num_i2, num_i3, ...
					num_i4, num_i4, spec_gram_size(end-1), ...
					spec_gram_size(end));
				allocated_data=true;
			end
			
			disp([i1 i2 i3 i4 i5]);
			data.(field{1})(i1,i2,i3,i4,i5,:,:) = ...
				maybe_spec_data.(field{1}); 
			end
			
		end
		
	end
	end
	end
	end
	end
	end
	
	
	%% Average data
	for field	= averaging_fields
		
	sum_count = ~isnan(data.(field{1})(:,:,:,:,:,:,:));
	sum_store = data.(field{1});
	
		for dim		= dim2avg
			
			% sum across dimension
			sum_store = sum(sum_store,dim,'omitnan');
			
			% at the same time, we sum across a matrix that has marked all
			% non-NaN numbers with a 1. This means, the sum for any
			% particular element IS THE NUMBER OF SPECTROGRAMS that have
			% been summed to create a particular element in sum_store!
			sum_count = sum(sum_count,dim);
			
		end
		
		% Here, we divide sum_store by (per element!) the number of
		% elements that have contributed to each elements sum. sum_count
		% has tracked this on an element by element basis. In other words,
		% for each (i1,i2,i3,i4,i5,x,y) sum_count has tracked the number of
		% elements summed in parallel with the summing on spectrograms or
		% coherograms.
		data.(field{1}) = sum_store./sum_count;
	end
	
	% TODO ... what if I sum over two dimensions in a row? Needs to be able
	% to store sum and keep track of how many elements are getting summed
	% per dimension!!!!
	
	%% Re-assign to output structure
	sieve = [inf inf inf inf inf];
	sieve(dim2avg) = 1;
	
	animals = fields(paramSet.animals);
	dataToProcess= paramSet.animals;
	for a = 1:numel(animals)
		anim = animals{a};
		for d	= dataToProcess.(anim).days
		for e	= dataToProcess.(anim).epochs
		for t	= dataToProcess.(anim).tetrodes
			% Count trials
			tr_logical = ~cellfun(@isempty,{grams(a).output{d, e, t,:}});
			numTrials = sum(tr_logical);
		for tr	= 1:numTrials
				
				% For each field, place averaged result
				for field = averaging_fields
					
					d=min(	d,	sieve(1));
					e=min(	e,	sieve(2));
					t=min(	t,	sieve(3));
					tr=min(	tr,	sieve(4));
					
					
					temp  = data.(field{1})(d,e,t,tr,1,:,:);
					dims = size(temp);
					temp = reshape(temp,dims(end-1),dims(end));
					avg_grams(a).output{d,e,t,tr}.(field{1}) = ...
						temp;
				end

		end
		end
		end
		end
	end
	

end