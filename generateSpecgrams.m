function [specgrams] = generateSpecgrams(acquisition, dataToProcess)
% Function that will accept 'acquisition' structure from gather windows of
% data and from it compute either a spectrogram per set of data in
% acquision or some combination of spectrograms.

% Store figure window style
default_fig = get(groot, 'DefaultFigureWindowStyle');
set(groot,'DefaultFigureWindowStyle','docked')

%% Define Chronux params
% -------------------------------------------
movingwin = [100 10]/1000; %movingwin = [100 10]/1000;                
params.Fs = 1500;
params.fpass = [0 40]; % params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];
params.pad = 9;

%% For-loooping over acquisitions
try
for a = 1:numel(acquisition)
    
    specgrams(a).animal = acquisition(a).animal;
    
    for d = dataToProcess.days
        for e = dataToProcess.epochs
            for t = dataToProcess.tetrodes
                for trial = 1:size(acquisition.data{d,e,t},1)

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

                    % If plot option is on, plot each one
                    if params.doPlot
                        input('Press return to continue');
                        i = imagesc(Stime,Sfreq,S');
                        i.Parent.YDir = 'normal';       % images invert by 
                        figure(1);                       % place figure at top of stack


                        title(['Trial ' num2str(trial)]);
                        xlabel('Time (s)');
                        ylabel('Frequency (hZ)');
                        grid on;
                    end

                    % Place into output structure
                    specgrams(a).output{d,e,t}.S = S;
                    specgrams(a).output{d,e,t}.Stime = Stime;
                    specgrams(a).output{d,e,t}.Sfreq = Sfreq;
                    specgrams(a).output{d,e,t}.Serror = Serror;

                end
            end
        end
    end
end

% if screws up in for-loop, reset figure style.
catch
set(groot,'DefaultFigureWindowStyle','normal')
end

set(groot,'DefaultFigureWindowStyle','normal')

end 