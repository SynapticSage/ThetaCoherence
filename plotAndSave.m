function plotAndSave( gram, sets)
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

%% Simplifying variable names detailing what to get
animals = fields(sets.animals);
toProcess = sets.animals;

%% Spectrograms
if spectrograms
for a = 1:numel(animals)
    for d = toProcess.(animals{a}).days;
        for e = toProcess.(animals{a}).epochs;
            for t= toProcess.(animals{a}).tetrodes;
				
				for t2 = toProcess.(animals{a}).tetrodes2;
				
				for tr = 1:sum(~cellfun(@isempty,{gram(a).output{d, e, t,:}}))
                
				% If there's an exception in handling, enforce it. It's a
				% temporary solution, hopefully, until a more elegant one
				% presents.
				EnforceException;
                
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
        end
    end
end
end
end

%% Coherograms
if coherograms
for a = 1:numel(animals)
    for d = toProcess.(animals{a}).days
        for e = toProcess.(animals{a}).epochs
            for t= toProcess.(animals{a}).tetrodes
			for t2 = toProcess.(animals{a}).tetrodes2
				
				% If there's an exception in handling, enforce it. It's a
				% temporary solution, hopefully, until a more elegant one
				% presents.
				EnforceException;
                
				for tr = 1:sum(~cellfun(@isempty,{gram(a).output{d, e, t,t2,:}}))
                
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
			end
        end
    end
end
end

%% Frequency Means
if meanFreqPlot
    
    S_results = [];
    C_results = [];
    
    for a   = 1
    for d   = mean_days
    for e   = mean_epochs
    for t   = mean_tets
    for t2  = mean_tets2

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
    end
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

