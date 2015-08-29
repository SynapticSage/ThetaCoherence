function plotStrongestFreqs(grams)

subscripts = getAllSubs(grams);
for s = 1:size(subscripts,1);
	subscripts(s,:)
	a	= subscripts(s,1);	% animals
	d	= subscripts(s,2);	% day
	e	= subscripts(s,3);	% epoch
	t	= subscripts(s,4);	% tetrodeX
	t2	= subscripts(s,5);	% tetrodeY
	tr	= subscripts(s,6);	% trial
	
	data_struct = grams(a).output{d,e,t,t2,tr};
	
	if isfield(data_struct,'CmaxPerTime')
		
		plot( data_struct.Stime, data_struct.CmaxPerTime );
		
		l = data_struct.freqCmean_lower;
		u = data_struct.freqCmean_upper;
		
		axis([-inf inf l u]);
		
		data_address_str = sprintf('\nDay:%d,Epoch:%d,Tetrode%d' , ...
			d,e,t);
		range_str = sprintf('%d-%d',l,u);
		
		title(['Strongest Frequency between ' range_str ...
			data_address_str]);
		xlabel('Time (s)');ylabel('Strongest Coherence Freq (Hz)');
	end
	
	if isfield(data_struct,'SmaxPerTime') 
		
		plot( data_struct.Stime, data_struct.SmaxPerTime);
		
		l = data_struct.freqSmean_lower;
		u = data_struct.freqSmean_upper;
		
		axis([-inf inf l u]);
		
		data_address_str = sprintf('\nDay:%d,Epoch:%d,Tetrode%d' , ...
			d,e,t);
		title(['Strongest Frequency in Spectrogram' ...
			data_address_str]);
		xlabel('Time (s)');ylabel('Strongest Spectrum Freq (Hz)');
	end
	
end

end