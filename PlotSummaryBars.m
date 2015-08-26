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
	bar(day_set, C_summary);
	
	%% Label
	
	xlabel('Day');
	ylabel('Coherence Strength');
	axis([1 inf 0 1]);
	
end