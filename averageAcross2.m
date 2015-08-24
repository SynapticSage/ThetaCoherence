function [avg_grams] = averageAcross2(grams,paramSet)

	%% Default options
	if ~ismember('average_dat_type', fields(paramSet))
		averaging_fields = {'S'};		% What fields to average
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
				disp('Error: Improper input')
				in = input('trials, tetrodes, days, epochs?');
		end
	end

	%% Make matrix of specgram data
	% This section makes plain matrices of each data type to average,
	% completely amenable to averaging.
	
	spec_cell = grams.output;
	temp_struct = [];
	allocated_data = false;
	
	for field = averaging_fields
	for i1 = 1:size(spec_cell,1)
	for i2 = 1:size(spec_cell,2)
	for i3 = 1:size(spec_cell,3)
	for i4 = 1:size(spec_cell,4)
	for i5 = 1:size(spec_cell,5)
		
		if ~allocated_data
			% ALLOCATE and set all zero data to NaN
		end
		
		maybe_spec_data = spec_cell{i1,i2,i3,i4,i5};
		
		if isstruct(maybe_spec_data)
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
	
	
	%% Average data
	for dim		= dim2avg
		for field	= averaging_fields
				data.(field{1}) = mean(data.(field{1}),dim);
		end
	end
	
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