function [params] = baselinecoherogram(prefix, days, epochs, tets, ...
	do_wrtgnd,varargin)
% Shantanu - Nov 2012. 
% From Kenny and Maggies - event_spectrograms .m and calcriptriggerredspectrograms.m respectively
% This is for getting baseline values for given eeg tets for normalization when needed. Save These. 

% sj_HPexpt_baselinespecgram('HPa', 8, [1:5], [1:20], 0);
% sj_HPexpt_baselinespecgram('HPa', 2, [1:5], [1:20], 0);

% sj_HPexpt_baselinespecgram('HPb', 1, [1:7], 1:20, 0)
% sj_HPexpt_baselinespecgram('HPa', 2, [1:5], [14,15], 0);
% sj_HPexpt_baselinespecgram('HPb', 2, [1:5], [4,9,16], 0);
% sj_HPexpt_baselinespecgram('HPb', 6, [1:5], [4,9,16], 0);

% RY 2015 - Used baselinespecgram as a template for baselinecoherogram.
% Kept original overall coding style intact, as much as possible.

directoryname = pwd;

if nargin<1,
    keyboard
    error('Please enter Expt Prefix and Day No!');
end
if nargin<2,
    keyboard
    error('Please enter Day No!');
end
if nargin<3,
    epochs=1; %% Epochs 
end
if nargin<4,
    tets=1; %
end
if nargin<5,
    do_wrtgnd=0; % Whether to also do with respect to ground
end


% Define Chronux params
% -------------------------------------------
movingwin = [1000 100]/1000; %movingwin = [100 10]/1000;                
params.Fs = 1500;
params.fpass = [0 40]; % params.fpass = [0 400];
params.tapers = [3 5];
params.err = [2 0.05];

%set variable options
for option = 1:2:length(varargin)-1
    switch varargin{option}
        case 'movingwin'
            movingwin = varargin{option+1};
        case 'fpass'
    	    params.fpass = varargin{option+1};
    end
end

savetag = 'tmp';

if params.fpass(2) == 400
    savetag = '';
    movingwin = [100 10]/1000; 
end
if params.fpass(2) == 100
    savetag = 'mid';
    movingwin = [400 40]/1000;
end
if params.fpass(2) == 40
    movingwin = [1000 100]/1000;
    savetag = 'low';
end
if params.fpass(2) <= 10
    movingwin = [8000 800]/1000; 
    savetag = 'floor';
   
end

% SET DATA
% -------------------------------------------

% % Load times file - if it will be needed
% % ---------------------------------------
% currdir = pwd;
% cd(rawdir);
% dayfolders = dir;
% daystr = sprintf('%02d', day);
% for i = 3:length(dayfolders)
%     if dayfolders(i).isdir
%         if strcmp(daystr,dayfolders(i).name(1:2))
%             disp(upper(dayfolders(i).name))
%             cd(dayfolders(i).name);
%             load times;
%         end
%     end
% end
% cd(currdir);
% Now Getting Range directly from times file
% userange = ranges(epoch+1,:); % 1st row is allepochs. So you need +1
% usename = names{epoch+1}(end-15:end);

% Get EEGs and spectrogram it
% ------------------------------
% cd([directoryname,'/EEG/']);
savedir = [directoryname,'/EEGCoh/'];

for d=1:length(days)
    
    day = days(d);
    if (day<10)
        daystring = ['0',num2str(day)];
    else
        daystring = num2str(day);
    end
    
    
    for t1=1:length(tets)
        tet1=tets(t1);
        
        if (tet1<10)
            tetstring1 = ['0',num2str(tet1)];
        else
            tetstring1 = num2str(tet1);
		end
		
		for tet2 = tets( find( tets<t1 ) )
			
			if (tet2<10)
				tetstring2 = ['0',num2str(tet2)];
			else
				tetstring2 = num2str(tet2);
			end
			
			eegcoh = []; dummy=[]; % Save 1 file for each tet in a day 
			
			if do_wrtgnd==1
				eeggndcoh = []; dummy_gnd = [];
			end

			flaggnd=0;
			for ep=1:length(epochs)
				
				epoch=epochs(ep);
				
				eeg=[]; eeggnd=[];
				
				disp(['Doing Day ',num2str(day) ', Ep ',num2str(epoch),...
					', Tet1 ',num2str(tet1), ', Tet2 ' num2str(tet2)]);
				eeg1f = [prefix,'eeg',daystring,'-', ...
					num2str(epoch),'-',tetstring1];
				eeg2f = [prefix,'eeg',daystring,'-', ...
					num2str(epoch),'-',tetstring2];
				eeg1 = load(eeg1f);
				eeg2 = load(eeg2f);
				
				coherogram = ...
					cohgramc( eeg1.eeg{day}{epoch}{tet1}.data, ...
					eeg2.eeg{day}{epoch}{tet2}.data,movingwin,params);
				
				% --------------------------------------------
				eegcoh{day}{epoch}{tet1}{tet2}.meanspec = mean(coherogram,1);
				eegcoh{day}{epoch}{tet1}{tet2}.stdspec = std(coherogram,1);
				dummy=[dummy; coherogram]; % For combining across epochs            

				% If do the gnd channel also          
				if do_wrtgnd==1
					eeg1f = [prefix,'eeggnd',daystring,'-', ...
					num2str(epoch),'-',tetstring1];
					eeg2f = [prefix,'eeggnd',daystring,'-', ...
						num2str(epoch),'-',tetstring2];
					
					if exist([eeg1f,'.mat'],'file') == 2 && ...
							exist([eeg2f, '.mat'],'file') == 2
						
						flaggnd=1;
						eeg1 = load(eeg1f);
						eeg2 = load(eeg2f);
						
						coherogram_gnd = cohgramc(...
							eeg1.eeggnd{day}{epoch}{tet1}.data,...
							eeg2.eeggnd{day}{epoch}{tet2}.data,...
							movingwin,params);
						
						eeggndcoh{day}{epoch}{tet1}{tet2}.meanspec = ...
							mean(coherogram_gnd,1);
						eeggndcoh{day}{epoch}{tet1}{tet2}.stdspec = ...
							std(coherogram_gnd,1);
						dummy_gnd=[dummy_gnd;coherogram_gnd];
						% Dont save specgram in file - its too big
						%eeggndspec{day}{epoch}{tet}.specgram  = [];
					end
				end

				% Dont save specgram in file - its too big
				% --------------------------------------------
				%eegspec{day}{epoch}{tet}.specgram  = [];

			end % end epochs


			% Also save mean and std for whole day. Save in fields for 
			% 1st epoch - [FIXED This has become last epoch now - by accident. Fix later]
			eegcoh{day}{1}{tet1}{tet2}.meandayspec=mean(dummy,1);
			eegcoh{day}{1}{tet1}{tet2}.stddayspec=std(dummy,1); 
			% Save File for current day and tet
			savefile = [savedir,prefix,'eegcoh',savetag,daystring,...
				'-Tet1',tetstring1, '-Tet2', tetstring2]
			save(savefile,'eegcoh');

			if ((do_wrtgnd==1) && (flaggnd==1))
				eeggndcoh{day}{1}{tet1}{tet2}.meandayspec=mean(dummy_gnd,1);
				eeggndcoh{day}{1}{tet1}{tet2}.stddayspec=std(dummy_gnd,1);
				%eegspec=eeggndspec; % To have the same name - Do this
				savefile = [savedir,prefix,'cohgndspec',savetag, daystring,...
					'-Tet1',tetstring1,'-Tet2', tetstring2]
				save(savefile,'eeggndcoh');
			end
			
			
		end % end tets2
    end % end tets1
end % end days

end