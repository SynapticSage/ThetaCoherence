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
	subplot(4,3,i);
	bar(day_set, C_summary,'b');
	title([num2str(l) '-' num2str(l+1)]);
	i=i+1;
	%% Label
	
	xlabel('Day');
	ylabel('Coherence Strength');
	axis([1 inf 0 0.8]);
	
end