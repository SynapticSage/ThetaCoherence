function plotAndSave( gram, sets, acquisition, acquisition2)
%PLOTANDSAVE Literally does what it says!
%   pass in spectrograms or coherograms in gram 
%	pass in sets struct containing information about what days, epochs and
%	tetrodes to average over in sets

%% Setting default options
if ~ismember('trials',fields(sets))
	sets.trials = false;
end

if ~ismember('coherograms',fields(sets))
	coherograms = false;
else
    coherograms = sets.coherograms;
end
if ~ismember('spectrograms',fields(sets))
	spectrograms = false;
else
    spectrograms = sets.spectrograms;
end

if ismember('meanFreqPlot', fields(sets))
    mean_days = sets.meanFreqPlot.days;
    mean_epochs = sets.meanFreqPlot.epochs;
    mean_tets = sets.meanFreqPlot.tetrodes;
    if ismember('tetrodes2',fields(sets.meanFreqPlot))
        mean_tets2 = sets.meanFreqPlot.tetrodes2;
    else
        mean_tets2 = 1;
    end
    
    meanFreqPlot = true;
else
    meanFreqPlot = false;
end

% if ismember('plotAvgVelocity', fields(sets))
%    
%     coherograms = sets.coherograms;
%     spectrograms = false;
%     avgVelocity = true;
%     
% else
%     avgVelocity= false;
%     
% end

%% Simplifying variable names detailing what to get
animals = fields(sets.animals);
toProcess = sets.animals;

%% Spectrograms
if spectrograms
subscripts = getAllSubs(grams);
for s = 1:size(subscripts,1);
	
	a	= subscripts(s,1);	% animals
	d	= subscripts(s,2);	% day
	e	= subscripts(s,3);	% epoch
	t	= subscripts(s,4);	% tetrodeX
	t2	= subscripts(s,5);	% tetrodeY
	tr	= subscripts(s,6);	% trial
                
	%% Adjust data
	temp= gram(a).output{d, e, t, tr};
	adjust=(max(temp.Stime)-min(temp.Stime))/2;

	temp.Stime=temp.Stime-min(temp.Stime)-adjust;

	%% Plot
	q= figure; hold on;
	set(gcf,'Position',[55 660 560 420]);
	imagesc(temp.Stime,temp.Sfreq,temp.S'); colorbar;
	if ~sets.trials
		title([gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e)...
			' Tet:' num2str(t)...
			],'FontSize',18,'Fontweight','normal');
	else
		title([gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e)...
			' Tet:' num2str(t)...
			' Trial: ' num2str(tr) ...
			],'FontSize',18,'Fontweight','normal');
	end
	ylabel('Freq','FontSize',20,'Fontweight','normal');
	xlabel('Time(s)','FontSize',20,'Fontweight','normal');
	set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
	set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);

	%% Save
	if ispc
		savepath= '/home/mcz/Desktop/GitProj/Images/';
		savepath = ['.' filesep];
	elseif ismac
		savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
	end

	if ~sets.trials
		specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' num2str(t) '.png']);
	else

		specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e) '_' num2str(t)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' num2str(t) ...
		'_' num2str(tr) '.png']);
	end

	close
	end
end

%% Coherograms
if coherograms
	
subscripts = getAllSubs(grams);
for s = 1:size(subscripts,1);
	
	a	= subscripts(s,1);	% animals
	d	= subscripts(s,2);	% day
	e	= subscripts(s,3);	% epoch
	t	= subscripts(s,4);	% tetrodeX
	t2	= subscripts(s,5);	% tetrodeY
	tr	= subscripts(s,6);	% trial
                
	%% Adjust data axes
	temp= gram(a).output{d, e, t,t2, tr};
	adjust=(max(temp.Stime)-min(temp.Stime))/2;

	temp.Stime=temp.Stime-min(temp.Stime)-adjust;

	%% Plot
	q= figure; hold on;
	set(gcf,'Position',[55 660 560 420]);
	imagesc(temp.Stime,temp.Sfreq,temp.C'); colorbar;
	if ~sets.trials
		title([sprintf('Coherence, \n') ...
			gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e) sprintf('\n')...
			' Tet_X:' num2str(t)...
			'Tet_Y:' num2str(t2) ...
			],'FontSize',16,'Fontweight','light');
	else
		title([ sprintf('Coherence, ') ...
			gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e) ...
			' Trial: ' num2str(tr) ...
			 sprintf('\n')...
			' Tet_X =' num2str(t)...
			' Tet_Y =' num2str(t2) ...
			],'FontSize',16,'Fontweight','light');
	end
	ylabel('Freq','FontSize',15,'Fontweight','normal');
	xlabel('Time(s)','FontSize',15,'Fontweight','normal');
	set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
	set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);

	%% Save
	if ispc
		savepath= '/home/mcz/Desktop/GitProj/Images/';
		savepath = ['.' filesep];
	elseif ismac
		savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
	end

	if ~sets.trials
		 specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'.png']);
	else
		specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e) '_TetX=' num2str(t) ...
			'_TetY=' num2str(t2)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'_' 'Trial' num2str(tr) '.png']);
	end

	close
	end
end

%% Frequency Means
if meanFreqPlot
    
    S_results = [];
    C_results = [];
    
    subscripts = getAllSubs(grams);
	for s = 1:size(subscripts,1);
	
	a	= subscripts(s,1);	% animals
	d	= subscripts(s,2);	% day
	e	= subscripts(s,3);	% epoch
	t	= subscripts(s,4);	% tetrodeX
	t2	= subscripts(s,5);	% tetrodeY
	tr	= subscripts(s,6);	% trial

        %% Store result
        
        if isstruct(gram(a).output{d,e,t,t2}) &&...
                ismember('freqSmean', fields(gram(a).output{d,e,t,t2}))
            S_results = [S_results gram(a).output{d,e,t,t2}.freqSmean];
        end
        
        
        if isstruct(gram(a).output{d,e,t,t2}) &&...
                ismember('freqCmean', fields(gram(a).output{d,e,t,t2}))
            C_results = [C_results gram(a).output{d,e,t,t2}.freqCmean];
        end
        
	end
    
	%% Plot
	q= figure;

	if ~isempty(S_results)
		bar(mean_days,S_results);
	end

	if ~isempty(C_results)
		bar(mean_days,C_results);
	end

	%% Labeling Figure
	set(gcf,'Position',[55 660 560 420]);

	graphTitle = input('Graph title: ');
	title( [graphTitle ...
		],'FontSize',16,'Fontweight','light');

	ylabel('Coherence','FontSize',15,'Fontweight','normal');
	xlabel('Days','FontSize',15,'Fontweight','normal');
	set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
	set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);

	%% Save
	if ispc
		savepath= '/home/mcz/Desktop/GitProj/Images/';
		savepath = ['.' filesep];
	elseif ismac
		savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
	end

	if ~sets.trials
		 specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'.png']);
	else
		specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e) '_TetX=' num2str(t) ...
			'_TetY=' num2str(t2)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'_' 'Trial' num2str(tr) '.png']);
	end

	close
    
    end
end


if avgVelocity
	
subscripts = getAllSubs(grams);
for s = 1:size(subscripts,1);
	
	a	= subscripts(s,1);	% animals
	d	= subscripts(s,2);	% day
	e	= subscripts(s,3);	% epoch
	t	= subscripts(s,4);	% tetrodeX
	t2	= subscripts(s,5);	% tetrodeY
	tr	= subscripts(s,6);	% trial
				
                
	%% Adjust data axes
	temp= gram(a).output{d, e, t,t2, tr};
	adjust=(max(temp.Stime)-min(temp.Stime))/2;

	temp.Stime=temp.Stime-min(temp.Stime)-adjust;

	%% Plot
	q= figure; hold on;
	set(gcf,'Position',[55 660 560 420]);
	subplot(2,1,1);
	imagesc(temp.Stime,temp.Sfreq,temp.C'); %colorbar;
	line([0 0],[min(temp.Sfreq) max(temp.Sfreq)],'color','k','linewidth',2,'linestyle','--')

	if ~sets.trials
		title([sprintf('Coherence, \n') ...
			gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e) sprintf('\n')...
			' Tet_X:' num2str(t)...
			'Tet_Y:' num2str(t2) ...
			],'FontSize',16,'Fontweight','light');
	else
		title([ sprintf('Coherence, ') ...
			gram(a).animal '- Day:' num2str(d)...
			' Epoch:' num2str(e) ...
			' Trial: ' num2str(tr) ...
			 sprintf('\n')...
			' Tet_X =' num2str(t)...
			' Tet_Y =' num2str(t2) ...
			],'FontSize',16,'Fontweight','light');
	end
	ylabel('Freq','FontSize',15,'Fontweight','normal');
	xlabel('Time(s)','FontSize',15,'Fontweight','normal');
	set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
	set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);

	subplot(2,1,2);
	boundedline([0:length(speed)-1]-length(speed)/2,speed,sem,'alpha');
	line([0 0],[min(sem)-min(speed) max(sem)+max(speed)],'color','k','linewidth',2,'linestyle','--')
	ylabel('avg. velocity (cm/s)','FontSize',15,'Fontweight','normal');
	xlabel('time (s)','FontSize',15,'Fontweight','normal');
	set(gca,'XLim',[min() max()]);
	set(gca,'YLim',[min() max()]);


	%% Save
	if ispc
		savepath= '/home/mcz/Desktop/GitProj/Images/';
		savepath = ['.' filesep];
	elseif ismac
		savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
	end

	if ~sets.trials
		 specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'.png']);
	else
		specific_folder = [gram(a).animal num2str(d) '_' ...
			num2str(e) '_TetX=' num2str(t) ...
			'_TetY=' num2str(t2)];

		mkdir(savepath, specific_folder);
		savepath = [savepath specific_folder filesep];

		saveas(gcf, [savepath gram(a).animal '_' ...
		num2str(d) '_' num2str(e) '_' ...
		'TetX=' num2str(t) ', TetY=' num2str(t2) ...
		'_' 'Trial' num2str(tr) '.png']);
	end

	close
	end
end % of avgVelocity

end % END FUNCTION
