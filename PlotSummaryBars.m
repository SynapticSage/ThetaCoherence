% Temporary solution

if exist('S_summary') && ~isempty(S_summary)
	
	%% Plot
	bar(day_set, S_summary);
	
	%% Label
	
	xlabel('Day');
	ylabel('Power');
	
end

if exist('C_summary') && ~isempty(C_summary)
	
	%% Plot
	bar(1:numel(C_summary), C_summary,'b');
	title([num2str(paramSet.lower_freq) '-' num2str(paramSet.upper_freq)]);
	%% Label
	
	xlabel('Epoch wrt All Days');
	ylabel('Coherence Strength');
	axis([0 inf 0 1]);
	
end