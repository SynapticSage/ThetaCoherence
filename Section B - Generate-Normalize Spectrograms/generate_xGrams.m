function [grams] = generate_xGrams(acquisition, paramSets...
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
% paramSets contains options about which data to process, as well as
% options for how to process them. Fields contain sets of days, epochs,
% tetrodes to create spectrograms for. If coherence, then add a tetrodes2
% field containing the set of tetrodes to generate coherences against in
% the second operand.
%
% Calculates specgram unless user passes in a second acquisition structure,
% which then defaults to coherograms.
% --------
% OUTPUT
% --------
% grams.output{d,e,t,...} which contains spectrogram or coherogram
% information in a struct for every single day epoch tetrode trial or day
% epoch tetrodeX tetrodeY trial.
%
% e.g. grams.output{1,4,1,17,1} contains coherogram, frequency/time axes,
% and std-error for day 1, epoch 4, tetrodeX 1, tetrodeY 17, trial 1
%

% Store figure window style
% if ismac || ispc
%     default_fig = get(groot, 'DefaultFigureWindowStyle');
%     set(0,'DefaultFigureWindowStyle','docked');
% end

% if user passed in folder instead of acquisition structure, cd into folder
file_read = false;
if ischar(acquisition)
	% if file reading mode, add to BEGINNING of path, so it's searched
	% first
	path(acquisition,path);
	file_read = true;
    read_loc = acquisition;
end
zscore =0; 

%% Define Chronux params
% -------------------------------------------  
params.Fs = 1500;
params.fpass = [0 20];		% params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];
if params.fpass(2) >= 400
    movingwin = [100 10]/1000; 
end
if params.fpass(2) == 100
    movingwin = [400 40]/1000;
    savetag = '';
end
if params.fpass(2) == 40
    movingwin = [1000 100]/1000;
    savetag = 'mid';
end
if params.fpass(2) == 20
    movingwin = [4000 400]/1000;
    savetag = 'low';
end
if params.fpass(2) == 10
    movingwin = [8000 800]/1000; 
    savetag = 'floor';

end

 %params.pad = 1;			% smooths frequency representation

%% Default parameters if not inputted
if isfield(paramSets, 'processOpt')
	processOpt = paramSets.processOpt;
end
if ~ismember('output', fields(paramSets))
	processOpt.output = true;
end
if ~ismember('save', fields(paramSets))
	processOpt.save = false;
end
if ~ismember('plot', fields(paramSets))
	processOpt.plot = false;
end

%% Simplify variables before loop
animals = fields(paramSets.animals);
animalcount = numel(animals);
paramSets = paramSets.animals;

try
	
	
%% Spectrograms! For-loooping over acquisitions
if nargin < 4


for a = 1:animalcount
    
	grams(a).animal = animals{a};
	if ~file_read; assert(isequal(animals{a},acquisition(a).animal)); end
    
    for d = paramSets.(animals{a}).days
        for e = paramSets.(animals{a}).epochs
            for t = paramSets.(animals{a}).tetrodes
				
				% If there's an exception in handling, enforce it. It's a
				% temporary solution, hopefully, until a more elegant one
				% presents.
                exception=[];
				EnforceException;
				
				% If file, read in, else access address in acquisition
				% struct
				if file_read
					% select file and load
					file_string = [read_loc animals{a} ...
						'acquisition' num2str(d) '-' num2str(e) '-' ...
						num2str(t) '.mat'];
					temp = load(file_string);
					data =temp.data;
				else
					data = acquisition(a).data{d,e,t};	
				end
				
                for trial = 1:size(data,1)
					
					%% Acquire spectrograms for trial
					
					% set specgram data
					specgram_data = data(trial,:);
%                     specgram_data = cast(specgram_data,'double');
						
					% Subset out relevant indices and plot
                    if any(isnan(specgram_data))
						
                        subset = ~isnan(specgram_data);
						
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(subset)' , movingwin, params);
					else
						
                        subset = find(acquisition(a).data{d,e,t}(trial,:) ~= 0);
						
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(subset(1):subset(end))', movingwin,params);
					end
		  
				  %% Z-score
				  % Unable to test atm, draft code
				  %Stime = Stime - length(Stime)/(params.Fs * 2); % This will make time start -win(1) instead of 0

				  % Unable to test atm, draft code
		 		  % to figure out- importing relevant mean data, or meangrnd data. Differentiate between S and Sgrnd?
				  if zscore == 1
                      
                     if d< 10; dstr= ['0' num2str(d)]; else dstr= num2str(d); end;
                     if t< 10; tstr= ['0' num2str(t)]; else tstr= num2str(t); end;

                    zscoredir= ['/home/mcz/DataShare/DATA/sjadhav/HPExpt/' animals{1} '_direct/EEGSpec/'];
                    datadir= [animals{1} 'eeggndspec' savetag dstr '-Tet' tstr '.mat' ];
                    
                    load([ zscoredir datadir]);
                    
					meanspecgnd = eeggndspec{d}{e}{t}.meanspec;
		       		stdspecgnd =  eeggndspec{d}{e}{t}.stdspec;
		       		
					% Z-score
					S = bsxfun(@minus,S,meanspecgnd(1:size(S,2))); 
		       		S = bsxfun(@rdivide,S,stdspecgnd(1:size(S,2)));
				  end

                    %% If plot option is on, plot each one
                    if processOpt.plot
                        input('Press return to continue');
                        clf
                        i = imagesc(Stime,Sfreq,S');
                        i.Parent.YDir = 'normal';       % images invert by 
                        figure(1);                       % place figure at top of stack


                        title(['Trial ' num2str(trial)]);
                        xlabel('Time (s)');
                        ylabel('Frequency (hZ)');
                        grid on;
                    end

                    %% If user asks for output to RAM or harddrive
					if processOpt.output || processOpt.save
						Output.S = S;
						Output.Stime = Stime;
						Output.Sfreq = Sfreq;
						Output.Serror = Serror;
                        Output.acquis.sst=acquisition(a).sst{d,e,t};
                        Output.acquis.ssi=acquisition(a).ssi{d,e,t};

					end
					
					%% If user asks to output to RAM
					if processOpt.output
						grams(a).output{d,e,t,trial} = Output;
					end
					
					%% If user asks to save to harddrive, then do
					if processOpt.save
						
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
if nargin == 4

for a = 1:animalcount
    
    grams(a).animal = animals{a};
	if ~file_read; assert(isequal(animals{a},acquisition(a).animal)); end
    
    for d = paramSets.(animals{a}).days
        for e = paramSets.(animals{a}).epochs
            for t = paramSets.(animals{a}).tetrodes
            for t2 = paramSets.(animals{a}).tetrodes2
				
				% If there's an exception in handling, enforce it. It's a
				% temporary solution, hopefully, until a more elegant one
				% presents.
                exception=[];
				EnforceException;
				
				% If file, read in, else access address in acquisition
					% struct
					if file_read
						% select file and load
						file_string = [animals{a} ...
							'acquisition' num2str(d) '-' num2str(e) '-' ...
							num2str(t) '.mat'];
						temp = load(file_string);
						data =temp.data;
					else
						data = acquisition(a).data{d,e,t};	
						data2= acquisition2(a).data{d,e,t2};
					end
				
                for trial = 1:size(data,1)

					% If there's an exception in handling, enforce it. It's a
					% temporary solution, hopefully, until a more elegant one
					% presents.
					EnforceException;
					
					
					%% Acquire coherence and spectrograms for trial
					
					specgram_data=data(trial,:);
					specgram_data2=data2(trial,:);

                    if any(isnan(specgram_data))
                        
                       logicalvec1 = ~isnan(specgram_data);
%                      logicalvec2 = ~isnan(specgram_data2);
                        
                        [C,phi,S12,S1,S2,Stime,Sfreq,confC,phistd,Cerr] = ...
                            cohgramc(specgram_data(logicalvec1)',...
                            specgram_data2(logicalvec1)', movingwin,params);
                    else
                        
                        indices = find(acquisition.data{d,e,t}(trial,:) ~= 0);
                        indices2 = find(acquisition.data{d,e,t2}(trial,:) ~= 0);
                        
                        [C,phi,S12,S1,S2,Stime,Sfreq,confC,phistd,Cerr] = ...
                            mtspecgramc(specgram_data(indices(1):indices(end))',...
                            specgram_data2(indices2(1):indices2(end))',movingwin,params);
                    end

                    %% If plot option is on, plot each one
                    if processOpt.plot
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
					if processOpt.output || processOpt.save
						% Cross-tetrode informations
						Output12.C = C;
						Output12.cerror = Cerr;
						Output12.confC = confC;
						Output12.phi = phi;
						Output12.phistd = phistd;
						Output12.S12 = S12;
						Output12.Stime = Stime;
						Output12.Sfreq = Sfreq;
                        Output12.acquis.sst=acquisition(a).sst{d,e,t};
                        Output12.acquis.ssi=acquisition(a).ssi{d,e,t};

						% Single tetrode t information
						Output1.S = S1;
						Output1.Stime = Stime;
						Output1.Sfreq = Stime;
                        Output1.acquis.sst=acquisition(a).sst{d,e,t};
                        Output1.acquis.ssi=acquisition(a).ssi{d,e,t};


						% Single tetrode t2 information
						Output2.S = S2;
						Output2.Stime = Stime;
						Output2.Sfreq = Stime;
                        Output12.acquis.sst=acquisition2(a).sst{d,e,t};
                        Output12.acquis.ssi=acquisition2(a).ssi{d,e,t};

					end
					
					%% If user asks to output from function/RAM
					if processOpt.output
						grams(a).output{d,e,t,t2,trial} = Output12;
						grams(a).output{d,e,t,t,trial} = Output1;
						grams(a).output{d,e,t2,t2,trial} = Output2;
					end
					
					%% If user asks to save data to harddrive, then do
					if processOpt.save
						
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
    % Display error data
	disp(ME.message);
	line = {ME.stack.line}; name= {ME.stack.name};
    for section = 1:numel(line)
        disp(sprintf('Line %d: %s', ...
            line{section}, name{section}));
	end
	% Reset what function changed
% 	set(groot,'DefaultFigureWindowStyle',default_fig)
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
