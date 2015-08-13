function [S,Stime,Sfreq] = generateSpecgrams(acquisition)
% Function that will accept 'acquisition' structure from gather windows of
% data and from it compute either a spectrogram per set of data in
% acquision or some combination of spectrograms.

%% Define Chronux params
% -------------------------------------------
movingwin = [1000 100]/1000; %movingwin = [100 10]/1000;                
params.Fs = 1500;
params.fpass = [0 40]; % params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];

%% Analysis Parameters
trial = params.trials

%% For-loooping over acquisitions



end