function [grams S_summary C_summary] = meanInFreqBand(grams,paramSet)
% FUNCTION meanInFreqBand(grams,paramSet)
%
% paramSet must-haves -- upper_freq, lower_freq
% paramSet optionals -- estimate_best_freq
%
% Function that cuts out a relevant region and/or collapses averages that
% signal over its y-axis or its x-axis. In spectrogram land, this means,
% cutting out the bandwidth you care about, and averaging it in frequency
% and/or in time, to create summaries for each sample.
%
% paramSet can contain upper and lower frequency to control frequency
% sampling. Alternatively, they're set to inf and -inf respectively -- a
% potentially useful mode that causes the function to take the
% mean power of all frequencies.
% 
% paramSet also takes an optional input, estimate_best_freq, which adds to
% the coherogram and spectrogram structs a field that estimates a
% "strongest" frequency of the signal per time bin.

%% Handle parametric inputs
if ~ismember('upper_freq',fields(paramSet))
    disp('Define the upper frequency:');
    keyboard;
end
if ~exist('upper_freq')
	upper_freq = paramSet.upper_freq;
else
	upper_freq = inf;
	disp('No frequency upper bound ...');
end
if ~exist('lower_freq')
	lower_freq = paramSet.lower_freq;
	disp('No frequency lower bound ...');
else
	lower_freq = -inf;
end
if ~exist('estimate_best_freq') && ...
		ismember('estimate_best_freq',fields(paramSet))
	estimate_best_freq = paramSet.estimate_best_freq;
else
	estimate_best_freq = false;
end

%% Initialize outputs
S_summary = [];
C_summary = [];

%% Process!
animals = fields(paramSet.animals);
for a = 1:numel(animals)
    
spec_cell = grams(a).output;

	for i1 = 1:size(spec_cell,1)
	for i2 = 1:size(spec_cell,2)
	for i3 = 1:size(spec_cell,3)
	for i4 = 1:size(spec_cell,4)
	for i5 = 1:size(spec_cell,5)
		
		maybe_spec_data = spec_cell{i1,i2,i3,i4,i5};
		
        % If it has something, then perform averaging
		if isstruct(maybe_spec_data)
			fprintf('Componifying day %d, ep %d, tetX %d, tetY %d, tr %d \n', ...
				i1,i2,i3,i4,i5);
            
            %% Pull out indices between where sampling frequencies
            ind_start = maybe_spec_data.Sfreq >= lower_freq;
            ind_start = min(find(ind_start));
            
            ind_stop   = maybe_spec_data.Sfreq <= upper_freq;
            ind_stop   = max(find(ind_stop));
            
            %% Prepare to grab and make S- or C-mean if S or C exist
			field = {};
            if ismember('S', fields(maybe_spec_data))
				field{numel(field)+1} = 'S';
			end
			if ismember('C', fields(maybe_spec_data))
				field{numel(field)+1} = 'C';
			end
            
			%% Process fields that exist
			for f = 1:numel(field)
            
			f = field{f};
			
            % pull out S
            g = maybe_spec_data.(f);
                
            % cut out band
			g = g(:,ind_start:ind_stop);
            
			if estimate_best_freq
				
				sfreq = maybe_spec_data.Sfreq(ind_start:ind_stop);
				
% 				freq_est_trace = ...
% 					expectedValueFrequencyAtTime(g,sfreq);
				
				max_freq_curve = highestFrequencyAtTime(g,sfreq);
				
				best_freq_field = [f 'maxPerTime'];
				grams(a).output{i1,i2,i3,i4,i5}.(best_freq_field) = ...
					max_freq_curve;
				
			end
			
			% mean in freq-dimension
            g = mean(g,2,'omitnan');
            
            % mean in time-dimension
            g = mean(g,1,'omitnan');
            
            % put result into output struct
			new_field = ['freq' f 'mean'];
            grams(a).output{i1,i2,i3,i4,i5}.(new_field) = g;
			
			% add results to optional summary output variables
			eval([f '_summary = [' f '_summary g];']);
			
			% add information about lower and upper frequency
			new_field_lower = [new_field '_lower'];
			new_field_upper = [new_field '_upper'];
            grams(a).output{i1,i2,i3,i4,i5}.(new_field_lower) = ...
				lower_freq;
			grams(a).output{i1,i2,i3,i4,i5}.(new_field_upper) = ...
				upper_freq;
			
            end
            
            
		end
		
	end
	end
	end
	end
    end
end

%% Helper function
	function [trace, gram_logical] = expectedValueFrequencyAtTime(g,sfreq)
	% Grabs frequency per time as determined by weighting by power of each
	% frequency at that time.
		total_power_per_time = sum(g,2);
		
		for i = 1:numel(sfreq)
			for j = 1:numel(total_power_per_time)
				g(j,i)  = g(j,i) * sfreq(i)/total_power_per_time(j);
			end
		end
		
		trace = sum(g,2);
			
	end
		

	function [trace, gram_logical] = highestFrequencyAtTime(g,sfreq)
		% Grabs simply the maximum frequency present at a particular time.
		% Future version will create a logical gram matrix, as that may be
		% useful in the analysis pipeline downstream.
		
		[~,maxIndicesAtEachTime] = max(g,[],2);
		maxFrequenciesPerTime = sfreq(maxIndicesAtEachTime);
		
		% Return the curve of numbers
		trace = maxFrequenciesPerTime;
		% Return something the size of the spectrogram with 1's marking the
		% found frequency, and 0's marking the non-found freqs
		
	end

end
