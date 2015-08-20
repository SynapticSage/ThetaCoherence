function plotAndSave( gram, sets )
%PLOTANDSAVE Literally does what it says!
%   pass in spectrograms or coherograms in gram 
%	pass in sets struct containing information about what days, epochs and
%	tetrodes to average over in sets

if ~ismember('trials',fields(sets))
	sets.trials = false;
end

for a= sets.animals;
    for d= sets.days;
        for e= sets.epochs;
            for t= sets.tetrodes;
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

