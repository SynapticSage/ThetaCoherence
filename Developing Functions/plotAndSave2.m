function plotAndSave( gram, sets, beh_data, beh_data2)
%PLOTANDSAVE Literally does what it says!
%   pass in spectrograms or coherograms in gram 
%	pass in sets struct containing information about what days, epochs and
%	tetrodes to average over in sets

%% Constants

xy_font_size = 12;
title_font_size = 14;

%% Pre-processing

% Storing the number of plots and the current number of the plots. This is
% so that we can store multiple panels of plots.
num_of_plots = 0;
curr_plot = 0;

%% Setting default options

if isfield(sets,'coherograms') && sets.coherograms == true
	coherograms = true;
    num_of_plots = num_of_plots + 1;
else
    coherograms = false;
end

if isfield(sets,'spectrograms') && sets.spectrogams == true
	spectrograms = true;
    num_of_plots = num_of_plots + 1;
else
    spectrograms = false;
end

% If this field is set and is true, then we should increase the number of
% plots.
if isfield(sets,'plotPositions') && sets.plotPositions == true
    num_of_plots = num_of_plots + 1;
    plotPositions = true;
else
    plotPositions = false; 
end

if isfield(sets,'plotAvgVelocity') && sets.plotAvgVelocity == true
    num_of_plots = num_of_plots + 1;
    plotAvgVelocity = true;
else
    plotAvgVelocity = false; 
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
    
    num_of_plots = num_of_plots+1;
else
    meanFreqPlot = false;
end

if isfield(sets,'trials') && sets.trials == true
	trials = true;
else
    trials = false;
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

%% Startup the subplot
% Calculate number of plots, and form the subplot panes for it.
rows = ceil(sqrt(num_of_plots));
cols = ceil(sqrt(num_of_plots));
subplot(rows,cols,1);

%% Simplifying variable names detailing what to get
animals = fields(sets.animals);
toProcess = sets.animals;

%% Plot various objects
for a = 1:numel(animals)
    for d = toProcess.(animals{a}).days
        for e = toProcess.(animals{a}).epochs
            for t= toProcess.(animals{a}).tetrodes
			for t2 = toProcess.(animals{a}).tetrodes2
				
				% If there's an exception in handling, enforce it. It's a
				% temporary solution, hopefully, until a more elegant one
				% presents.
                exception=[];
				EnforceException;
                
				for tr = 1:sum(~cellfun(@isempty,{gram(a).output{d, e, t,t2,:}}))
                
				if coherograms
                    curr_plot = curr_plot + 1;
                    subplot(rows,cols,curr_plot);
                    plotCoherence;
                end
                
                if spectrograms
                    curr_plot = curr_plot + 1;
                    subplot(rows,cols,curr_plot);
                    plotSpectrogram;
                end
                
                if plotPositions
                    curr_plot = curr_plot + 1;
                    subplot(rows,cols,curr_plot);
                    plotPos;
                end
                
                if plotAvgVelocity
                    curr_plot = curr_plot + 1;
                    subplot(rows,cols,curr_plot);
                    plotVelocity;
                end 
                
                 curr_plot = 0;
                 
                 %% SAVE Section
                 
                 descriptor = '';
                 figfile = [animals{a} descriptor num2str(d) ...
                     '-' num2str(e) '-' num2str(t) '-' num2str(t2) ...
                     '-' num2str(tr)];
                 
                 print('-dpdf', figfile); 
                 print('-dpng', figfile, '-r300'); 
                 saveas(gcf,figfile,'fig'); 
                 print('-depsc2', figfile); 
                 print('-djpeg', figfile);
                
				end
			end
			end
        end
    end
end

%% NESTED PLOT FUNCTIONS ...
    % Each of these controls the behavior of a type of plot
    
    function plotCoherence
        
        %% Adjust data axes
                temp= gram(a).output{d, e, t,t2, tr};
                adjust=(max(temp.Stime)-min(temp.Stime))/2;
                
                temp.Stime=temp.Stime-min(temp.Stime)-adjust;
                
                %% Plot
                set(gcf,'Position',[55 660 560 420]);
                i=imagesc(temp.Stime,temp.Sfreq,temp.C'); colorbar;
                i.Parent.YDir='normal';
				if ~trials
					title([sprintf('Coherence, \n') ...
						gram(a).animal '- Day:' num2str(d)...
						' Epoch:' num2str(e) sprintf('\n')...
						' Tet_X:' num2str(t)...
						'Tet_Y:' num2str(t2) ...
						],'FontSize',title_font_size,'Fontweight','light');
				else
					title([ sprintf('Coherence, ') ...
						gram(a).animal '- Day:' num2str(d)...
						' Epoch:' num2str(e) ...
						' Trial: ' num2str(tr) ...
						 sprintf('\n')...
						' Tet_X =' num2str(t)...
						' Tet_Y =' num2str(t2) ...
						],'FontSize',title_font_size,'Fontweight','light');
				end
                ylabel('Freq','FontSize',xy_font_size,'Fontweight','normal');
                xlabel('Time(s)','FontSize',xy_font_size,'Fontweight','normal');
                set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
                set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);
        
    end

    function plotSpectrogram
        
        %% Plot
                set(gcf,'Position',[55 660 560 420]);
                imagesc(temp.Stime,temp.Sfreq,temp.S'); colorbar;
				if ~trials
					title([gram(a).animal '- Day:' num2str(d)...
						' Epoch:' num2str(e)...
						' Tet:' num2str(t)...
						],'FontSize',18,'Fontweight','normal');
				else
					title([gram(a).animal '- Day:' num2str(d)...
						' Epoch:' num2str(e)...
						' Tet:' num2str(t)...
						' Trial: ' num2str(tr) ...
						],'FontSize',title_font_size,'Fontweight','normal');
				end
                ylabel('Freq','FontSize',xy_font_size,'Fontweight','normal');
                xlabel('Time(s)','FontSize',xy_font_size,'Fontweight','normal');
                set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
                set(gca,'YLim',[min(temp.Sfreq) max(temp.Sfreq)]);
        
    end
    
    function plotVelocity
        
        temp= gram(a).output{d, e, t,t2};
        adjust=(max(temp.Stime)-min(temp.Stime))/2;
        temp.Stime=temp.Stime-min(temp.Stime)-adjust;
        
        if trials
            [speed, sem, binSpec] = getAvgVelocity(gram, beh_data, d,e,t,t2,tr);
        else
            [speed, sem, binSpec] = getAvgVelocity(gram, beh_data, d,e,t,t2);
        end
        
        errorbar(temp.Stime,speed,sem,'-.','linewidth',2,'markersize',25);
        line([0 0],[min(sem)-min(speed) max(sem)+max(speed)],'color','k','linewidth',2,'linestyle','--')
        ylabel('avg. velocity (cm/s)','FontSize',xy_font_size,'Fontweight','normal');
        xlabel('time (s)','FontSize',xy_font_size,'Fontweight','normal');
        set(gca,'XLim',[min(temp.Stime) max(temp.Stime)]);
        set(gca,'YLim',[0 max(speed)]);
        
    end
    
    function plotStrongFreq
        
        %% TO DO
        
    end

    function plotMeanFreq
        
        if isstruct(gram(a).output{d,e,t,t2}) &&...
                ismember('freqSmean', fields(gram(a).output{d,e,t,t2}))
            S_results = [S_results gram(a).output{d,e,t,t2}.freqSmean];
        end
        
        
        if isstruct(gram(a).output{d,e,t,t2}) &&...
                ismember('freqCmean', fields(gram(a).output{d,e,t,t2}))
            C_results = [C_results gram(a).output{d,e,t,t2}.freqCmean];
        end
        
    end
    
    function plotPos
        
        plotSingleSample(beh_data(a).pos{d,e}, beh_data(a).ssi{d,e}, tr);
        
    end
    
    
end

