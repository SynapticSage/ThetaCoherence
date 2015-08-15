function [grams] = generate_xGrams(acquisition, dataToProcess, ...
    acquisition2)
% Function that will accept 'acquisition' structure from gather windows of
% data and from it compute either a spectrogram per set of data in
% acquision or some combination of spectrograms.
%
%
% Calculates specgram unless user passes in a second acquisition structure.

% Store figure window style
default_fig = get(groot, 'DefaultFigureWindowStyle');
set(groot,'DefaultFigureWindowStyle','docked')

%% Define Chronux params
% -------------------------------------------
movingwin = [100 10]/1000; %movingwin = [100 10]/1000;                
params.Fs = 1500;
params.fpass = [0 100]; % params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];
params.pad = 7;

%%
try
	
	
%% Spectrograms! For-loooping over acquisitions
if nargin < 3


for a = 1:numel(acquisition)
    
    grams(a).animal = acquisition(a).animal;
    
    for d = dataToProcess.days
        for e = dataToProcess.epochs
            for t = dataToProcess.tetrodes
                for trial = 1:size(acquisition.data{d,e,t},1)
					
					%% Acquire spectrograms for trial
                    specgram_data = acquisition.data{d,e,t}(trial,:);

                    if sum(isnan(specgram_data)) > 0
                        logicalvec = ~isnan(specgram_data);
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(logicalvec)', movingwin,params);
                    else
                        indices = find(acquisition.data{d,e,t}(trial,:) ~= 0);
                        [S, Stime, Sfreq, Serror] = ...
                            mtspecgramc(specgram_data(indices(1):indices(end)), movingwin,params);
                    end

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

                    %% If user asks for output, then do
					if dataToProcess.output
						grams(a).output{d,e,t,trial}.S = Sfreq;
						grams(a).output{d,e,t,trial}.Stime = Stime;
						grams(a).output{d,e,t,trial}.Sfreq = Sfreq;
						grams(a).output{d,e,t,trial}.Serror = Serror;
					end
					
					%% If user asks to save to harddrive, then do
					if dataToProcess.save
						% TODO
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
                for trial = 1:size(acquisition.data{d,e,t},1)

					%% Acquire coherence and spectrograms for trial
                    specgram_data = acquisition.data{d,e,t}(trial,:);
                    specgram_data2 = acquisition2.data{d,e,t2}(trial,:);

                    if sum(isnan(specgram_data)) > 0
                        
                        logicalvec = ~isnan(specgram_data);
                        logicalvec2 = ~isnan(specgram_data2);
                        
                        [C,phi,S12,S1,S2,Stime,Sfreq,confC,phistd,Cerr] = ...
                            cohgramc(specgram_data(logicalvec)',...
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
					if dataToProcess.output
						% Cross-tetrode informations
						grams(a).output{d,e,t,t2,trial}.C = C;
						grams(a).output{d,e,t,t2,trial}.cerror = Cerr;
						grams(a).output{d,e,t,t2,trial}.confC = confC;
						grams(a).output{d,e,t,t2,trial}.phi = phi;
						grams(a).output{d,e,t,t2,trial}.phistd;
						grams(a).output{d,e,t,t2,trial}.S12 = S12;
						grams(a).output{d,e,t,t2,trial}.Stime = Stime;
						grams(a).output{d,e,t,t2,trial}.Sfreq = Sfreq;

						% Single tetrode t information
						grams(a).output{d,e,t,t,trial}.S = S1;
						grams(a).output{d,e,t,t,trial}.Stime = Stime;
						grams(a).output{d,e,t,t,trial}.Sfreq = Stime;

						% Single tetrode t2 information
						grams(a).output{d,e,t2,t2,trial}.S = S2;
						grams(a).output{d,e,t2,t2,trial}.Stime = Stime;
						grams(a).output{d,e,t2,t2,trial}.Sfreq = Stime;
					end
					
					%% If user asks to save data to harddrive, then do
					if dataToProcess.save
						% TODO
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
    set(groot,'DefaultFigureWindowStyle','normal')
	
end

%% Post-processing

set(groot,'DefaultFigureWindowStyle','normal')
return;

%% HELPER FUNCTIONS

	function saveOutput(SaveFileCharacteristics, OutputsToSave)
	% Exists so that data can be saved per processing cyle instead of
	% pushed into RAM. If an option is turned on, the function will save to
	% hard-drive results instead of throwing into RAM. 4- and 5-dimensional
	% cell arrays can be positively huge in memory, even when their
	% elements are empty.
	
	
	
	end

end 