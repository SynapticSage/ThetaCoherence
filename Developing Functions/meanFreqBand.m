function [grams S_summary C_summary] = meanFreqBand(grams,paramSet)
%
% Function that cuts out a relevant region and/or collapses averages that
% signal over its y-axis or its x-axis. In spectrogram land, this means,
% cutting out the bandwidth you care about, and averaging it in frequency
% and/or in time, to create summaries for each sample.

%% Handle parametric inputs
if ~ismember('upper_freq',fields(paramSet))
    disp('Define the upper frequency:');
    keyboard;
end
upper_freq = paramSet.upper_freq;
lower_freq = paramSet.lower_freq;

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
			disp([i1 i2 i3 i4 i5]);
            
            %% Pull out indices between where sampling frequencies
            f_start = maybe_spec_data.Sfreq >= lower_freq;
            f_start = min(find(f_start));
            
            f_stop   = maybe_spec_data.Sfreq <= upper_freq;
            f_stop   = max(find(f_stop));
            
            %% Grab and make S-mean if S exists
            if ismember('S', fields(maybe_spec_data))
            
            % pull out S
            s = maybe_spec_data.S;
                
            % cut out band
			s = s(:,f_start:f_stop);
            
            % mean in freq-dimension
            s = mean(s,1);
            
            % mean in time-dimension
            s = mean(s,2);
            
            % put result into output struct
            grams(a).output{i1,i2,i3,i4,i5}.freqSmean = s;
			
			% add results to summary
			S_summary = [S_summary s];
			
			% add information about lower and upper frequency
			grams(a).output{i1,i2,i3,i4,i5}.freqSmean_lower = ...
				lower_freq;
			grams(a).output{i1,i2,i3,i4,i5}.freqSmean_upper = ...
				upper_freq;
            
            end
            
            %% Grab and make C-mean if C exists
            if ismember('C', fields(maybe_spec_data))
            
            % pull out S
            c = maybe_spec_data.C;
                
            % cut out band
			c = c(:,f_start:f_stop);
            
            % mean in freq-dimension
            c = mean(c,1,'omitnan');
            
            % mean in time-dimension
            c = mean(c,2,'omitnan');
            
            % put result into output struct
            grams(a).output{i1,i2,i3,i4,i5}.freqCmean = c;
			
			% add results to summary
			C_summary = [C_summary c];
			
			% add information about lower and upper frequency
            grams(a).output{i1,i2,i3,i4,i5}.freqCmean_lower = ...
				lower_freq;
			grams(a).output{i1,i2,i3,i4,i5}.freqCmean_upper = ...
				upper_freq;
			
            end
            
            
		end
		
	end
	end
	end
	end
    end
end



end
