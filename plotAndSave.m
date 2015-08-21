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
	sets.coherograms = false;
end
if ~ismember('spectrograms',fields(sets))
	sets.spectrograms = true;
end

%% Simplifying variable names detailing what to get
animals = fields(sets.animals);
toProcess = sets.animals;

%% Plotting over all requested data
if sets.spectrograms
for a = animals
    for d = toProcess.(animals(a)).days;
        for e = toProcess.(animals(a)).epochs;
            for t= toProcess.(animals(a)).tetrodes;
				
				for t2 = sets.tetrodes2;
				
				for tr = 1:sum(~cellfun(@isempty,{gram(a).output{d, e, t,:}}))
                
                temp= gram(a).output{d, e, t, tr};
                adjust=(max(temp.Stime)-min(temp.Stime))/2;
                
                temp.Stime=temp.Stime-min(temp.Stime)-adjust;
                
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
                
				if ispc
					savepath= '/home/mcz/Desktop/GitProj/Images/';
                    savepath = './';
				elseif ismac
					savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
				end
                
				if ~sets.trials
					saveas(gcf, [savepath gram(a).animal '_' ...
					num2str(d) '_' num2str(e) '_' num2str(t) '.png']);
				else
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

if sets.coherograms
for a = animals
    for d = toProcess.(animals(a)).days
        for e = toProcess.(animals(a)).epochs
            for t= toProcess.(animals(a)).tetrodes
			for t2 = toProcess.(animals(a)).tetrodes2
                
				for tr = 1:sum(~cellfun(@isempty,{gram(a).output{d, e, t,:}}))
                    
                temp= gram(a).output{d, e, t,t2, tr};
                adjust=(max(temp.Stime)-min(temp.Stime))/2;
                
                temp.Stime=temp.Stime-min(temp.Stime)-adjust;
                
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
                
				if ispc
					savepath= '/home/mcz/Desktop/GitProj/Images/';
                    savepath = './';
				elseif ismac
					savepath= '~/Documents/MATLAB/LabProjects/Data/LongerLowerPassSpecsHpa5/';
				end
                
				if ~sets.trials
					saveas(gcf, [savepath gram(a).animal '_' ...
					num2str(d) '_' num2str(e) '_' ...
					'TetX=' num2str(t) ', TetY=' num2str(t2) ...
					'.png']);
				else
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




end

