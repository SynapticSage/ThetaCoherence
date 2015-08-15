function [xGrams] = generate_xGrams(acquisition, dataToProcess, ...
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

%% Spectrograms! For-loooping over acquisitions
try
if nargin < 3


for a = 1:numel(acquisition)
    
    xGrams(a).animal = acquisition(a).animal;
    
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
                    if dataToProcess.doPlot
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
                    xGrams(a).output{d,e,t}.S = Sfreq;
                    xGrams(a).output{d,e,t}.Stime = Stime;
                    xGrams(a).output{d,e,t}.Sfreq = Sfreq;
                    xGrams(a).output{d,e,t}.Serror = Serror;

                end
            end
        end
    end
end

%% Coherograms!
elseif nargin == 3

for a = 1:numel(acquisition)
    
    xGrams(a).animal = acquisition(a).animal;
    
    for d = dataToProcess.days
        for e = dataToProcess.epochs
            for t = dataToProcess.tetrodes
            for t2 = dataToProcess.tetrodes2
                for trial = 1:size(acquisition.data{d,e,t},1)

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

                    % If plot option is on, plot each one
                    if dataToProcess.doPlot
                        input('Press return to continue');
                        i = imagesc(Stime,Sfreq,C');
                        i.Parent.YDir = 'normal';       % images invert by 
                        figure(1);                       % place figure at top of stack


                        title(['Trial ' num2str(trial)]);
                        xlabel('Time (s)');
                        ylabel('Frequency (hZ)');
                        grid on;
                    end

                    % Place into output structure
%                     grams(a).output{d,e,t}.C = C;
%                     grams(a).output{d,e,t}.phi = phi;
%                     grams(a).output{d,e,t}.Ctime = t;
%                     grams(a).output{d,e,t}.Cfreq = f;
%                     grams(a).output{d,e,t}.cerror = Cerr;

                end
            end
            end
        end
    end
end 
end

% if screws up in for-loop, reset figure style.
catch ME
    set(groot,'DefaultFigureWindowStyle','normal')
end

set(groot,'DefaultFigureWindowStyle','normal')

end 