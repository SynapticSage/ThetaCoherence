function [grams] = generate_xGrams(acquisition, dataToProcess, ...
    acquisition2)
% Function that will accept 'acquisition' structure from gather windows of
% data and from it compute either a spectrogram per set of data in
% acquision or some combination of spectrograms.
%
% Acquisition can be one of two things. For one, it can be the output from
% gatherWindowsOfData. It is an an array, where the animal field describes
% the animal, and the data field describes acquisitions of data for that
% animal.
%
% Two, acquisition can be a folder, containing the saved files from
% gatherWindowsOfData. Either will do.
%
% dataToProcess contains options about which data to process. Fields
% contain sets of days, epochs, tetrodes to create spectrograms for. If
% coherence, then add a tetrodes2 field containing the set of tetrodes to
% generate coherences against in the second operand.
%
% Calculates specgram unless user passes in a second acquisition structure.

% Store figure window style
if ismac || ispc
    default_fig = get(groot, 'DefaultFigureWindowStyle');
    set(groot,'DefaultFigureWindowStyle','docked');
end

% if user passed in folder instead of acquisition structure, cd into folder
file_read = false;
if ischar(acquisition)
	% if file reading mode, add to BEGINNING of path, so it's searched
	% first
	path(acquisition,path);
	file_read = true;
end

%% Define Chronux params
% -------------------------------------------  
params.Fs = 1500;
params.fpass = [0 40];		% params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];
if params.fpass(2) == 400
    movingwin = [100 10]/1000; 
end
if params.fpass(2) == 100
    movingwin = [400 40]/1000;
end
if params.fpass(2) == 40
    movingwin = [1000 100]/1000;
end
if params.fpass(2) <= 10
    movingwin = [8000 800]/1000; 
end

% params.pad = 7;			% smooths frequency representation

%% Default parameters if not inputted
if ~ismember('output', fields(dataToProcess))
	dataToProcess.output = true;
end
if ~ismember('save', fields(dataToProcess))
	dataToProcess.save = false;
end
if ~ismember('plot', fields(dataToProcess))
	dataToProcess.plot = false;
end

%%
try
	
	
%% Spectrograms! For-loooping over acquisitions
if nargin < 3


for a = 1:numel(acquisition)
    
    grams(a).animal = acquisition(a).animal;
    
    for d = dataToProcess.days
        for e = dataToProcess.epochs
            for t = dataToProcess.tetrodes
                for trial = 1:size(acquisition(a).data{d,e,t},1)
					
					%% Acquire spectrograms for trial
					
					% Set specgram data, either from file or from
					% acquisition struct
					if file_read
						
						% select file and load
						file_string = [acquisition(a).animal ...
							'acquisition' num2str(d) num2str(e) ...
							num2str(t)];
						temp = load(file_string);
						
						% set specgram data
						specgram_data = temp.data(trial,:);
						
					else
						specgram_data = acquisition(a).data{d,e,t}(trial,:);
					end

					% Subset out relevant indices and plot
                    if any(isnan(specgram_data))
                        subset = ~isnan(specgram_data);
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(subset)', movingwin, params);
                    else
                        subset = find(acquisition(a).data{d,e,t}(trial,:) ~= 0);
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(subset(1):subset(end))', movingwin,params);
					end
		  
				  %% Z-score
				  % Unable to test atm, draft code
				  %Stime = Stime - length(Stime)/(params.Fs * 2); % This will make time start -win(1) instead of 0

				  % Unable to test atm, draft code
		%		  % to figure out- importing relevant mean data, or meangrnd data. Differentiate between S and Sgrnd?
		%		  if zscore == 1
		%			meanspecgnd = eeggndspec{d}{e}{t}.meanspec;
		%        		stdspecgnd = eeggndspec{d}{e}{t}.stdspec;
		%        		
		%			% Z-score
		%			S_zscr = bsxfun(@minus,S,meanspecgnd(1:size(S,2))); 
		%        		S_zscr = bsxfun(@rdivide,S,stdspecgnd(1:size(S,2)));
		%		  end

                    %% If plot option is on, plot each one
                    if dataToProcess.plot
                        input('Press return to continue');
                        i = imagesc(Stime,Sfreq,S');
                        i.Parent.YDir = 'normal';       % images invert by 
                        figure(1);                       % place figure at top of stack


                        title(['Trial ' num2str(trial)]);
                        xlabel('Time (s)');
                        ylabel('Frequency (hZ)');
                        grid on;
                    end

                    %% If user asks for output to RAM or harddrive
					if dataToProcess.output || dataToProcess.save
						Output.S = S;
						Output.Stime = Stime;
						Output.Sfreq = Sfreq;
						Output.Serror = Serror;
					end
					
					%% If user asks to output to RAM
					if dataToProcess.output
						grams(a).output{d,e,t,trial} = Output;
					end
					
					%% If user asks to save to harddrive, then do
					if dataToProcess.save
						
						SaveFileCharacteristics.animal = ...
							acquisition(a).animal;
						SaveFileCharacteristics.data_name = ...
							'spec';
						SaveFileCharacteristics.numerical_address = ...
							[d e t trial];
						
						saveOutput(SaveFileCharacteristics, Output);
					end

                end
            end
        end
    end
end
end

%% Coherograms! (and spectrograms)
%
if nargin == 3

for a = 1:numel(acquisition)
    
    grams(a).animal = acquisition(a).animal;
    
    for d = dataToProcess.days
        for e = dataToProcess.epochs
            for t = dataToProcess.tetrodes
            for t2 = dataToProcess.tetrodes2
                for trial = 1:size(acquisition(a).data{d,e,t},1)

					%% Acquire coherence and spectrograms for trial
                    specgram_data = acquisition(a).data{d,e,t}(trial,:);
                    specgram_data2 = acquisition2(a).data{d,e,t2}(trial,:);

                    if sum(isnan(specgram_data)) > 0
                        
                        subset = ~isnan(specgram_data);
                        logicalvec2 = ~isnan(specgram_data2);
                        
                        [C,phi,S12,S1,S2,Stime,Sfreq,confC,phistd,Cerr] = ...
                            cohgramc(specgram_data(subset)',...
                            specgram_data2(logicalvec2)', movingwin,params);
                    else
                        
                        indices = find(acquisition.data{d,e,t}(trial,:) ~= 0);
                        indices2 = find(acquisition.data{d,e,t2}(trial,:) ~= 0);
                        
                        [C,phi,S12,S1,S2,Stime,Sfreq,confC,phistd,Cerr] = ...
                            mtspecgramc(specgram_data(indices(1):indices(end))',...
                            specgram_data2(indices2(1):indices2(end))',movingwin,params);
                    end

                    %% If plot option is on, plot each one
                    if dataToProcess.plot
                        input('Press return to continue');
                        i = imagesc(Stime,Sfreq,C');
                        i.Parent.YDir = 'normal';       % images invert by 
                        figure(1);                       % place figure at top of stack


                        title(['Trial ' num2str(trial)]);
                        xlabel('Time (s)');
                        ylabel('Frequency (hZ)');
                        grid on;
					end

					%% If user asks for output, then add to proper cell locs
					if dataToProcess.output || dataToProcess.save
						% Cross-tetrode informations
						Output12.C = C;
						Output12.cerror = Cerr;
						Output12.confC = confC;
						Output12.phi = phi;
						Output12.phistd = phistd;
						Output12.S12 = S12;
						Output12.Stime = Stime;
						Output12.Sfreq = Sfreq;

						% Single tetrode t information
						Output1.S = S1;
						Output1.Stime = Stime;
						Output1.Sfreq = Stime;

						% Single tetrode t2 information
						Output2.S = S2;
						Output2.Stime = Stime;
						Output2.Sfreq = Stime;
					end
					
					%% If user asks to output from function/RAM
					if dataToProcess.output
						grams(a).output{d,e,t,t2,trial} = Output12;
						grams(a).output{d,e,t,t,trial} = Output1;
						grams(a).output{d,e,t2,t2,trial} = Output2;
					end
					
					%% If user asks to save data to harddrive, then do
					if dataToProcess.save
						
						% Save coherence for t & t2
						SaveFileCharacteristics.animal = ...
							acquisition(a).animal;
						SaveFileCharacteristics.data_name = ...
							'coher';
						SaveFileCharacteristics.numerical_address = ...
							[d e t t2 trial];
						saveOutput(SaveFileCharacteristics, Output12);
						
						% Save spectrogram t
						SaveFileCharacteristics.data_name = ...
							'spec';
						SaveFileCharacteristics.numerical_address = ...
							[d e t trial];
						saveOutput(SaveFileCharacteristics,Output1);
						
						% Save spectrogram t2
						SaveFileCharacteristics.numerical_address = ...
							[d e t2 trial];
						
						saveOutput(SaveFileCharacteristics,Output2);
						
					end
					

                end
            end
            end
        end
    end
end 
end


catch ME				% if screws up in for-loop, reset figure style.
	%% Error post-processing
    set(groot,'DefaultFigureWindowStyle',default_fig)
	disp(ME.message);
	
	if file_read
		rmpath(acquisition);
	end
end

%% Post-processing

%set(groot,'DefaultFigureWindowStyle',default_fig)
if file_read		% return to calling directory if file_read mode on
	rmpath(acquisition);
end

return;

%% HELPER FUNCTIONS

	function saveOutput(SaveFileCharacteristics, OutputsToSave)
	% Exists so that data can be saved per processing cyle instead of
	% pushed into RAM. If an option is turned on, the function will save to
	% hard-drive results instead of throwing into RAM. 4- and 5-dimensional
	% cell arrays can be positively huge in memory, even when their
	% elements are empty.
	
	% Setup shortened names for header strings
	animal = SaveFileCharacteristics.animal;
	data_name = SaveFileCharacteristics.data_name;
	
	% Create string for numerical address
	numerical_address_string = [];
	for num = SaveFileCharacteristics.numerical_address
		numerical_address_string = [numerical_address_string ...
			num2str(num) '-'];
	end
	% Remove last '-'
	numerical_address_string = numerical_address_string(1:end-1);
	
	% Create filename
	filename = [animal data_name numerical_address_string];
	
	% Save all fields in OutputsToSave struct as individual variables,
	% -struct option seperates out the fields
	save(filename,'-struct', 'OutputsToSave');
	
	end

end 
