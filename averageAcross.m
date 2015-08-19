function [avg_specgram] = averageAcross(specgrams, sets, params)
% Function controls the averaging across spectrograms.

% if flag== trials, Output = Output(animals).{day,epoch,tetrode}

sets={'trial'};
animNum= length(specgrams);
for a= 1:animNum;
    avg_specgram(a).animal= specgrams(a).animal;

% retrieve general info on array size and # of dims 
datSize(a,:)=  size(specgrams(a).output);
datDims(a,:)= ndims(specgrams(a).output);

% Get nonzero input array indices (linear indexing)
relevElem=find( ~cellfun(@isempty,specgrams(a).output));

% convert linear indices to subscript (dimensional) indices
[temp_idx{1:datDims}] = ind2sub(datSize(a,:),relevElem);

% assemble into one mat
idx=[temp_idx{:}]; clear temp_idx

% % get unique values from each dimension where data is stored
for u=1:datDims; uVals{u,:}=unique(idx(:,u),'rows')'; end;

if ismember('trial',sets);
    for d= uVals{1};
        for e= uVals{2};
            for t= uVals{3};
                
                % get the indices for all relevant inputs for this operation (avg across trials)
                idxs= idx( (idx(:,1)==d & idx(:,2)==e & idx(:,3)==t),:);
                
                for r= 1:length(idxs);
                    % store all gathered S'es and Serrors in temp matrices
                    tempS(r,:,:)       = specgrams(a).output{d,e,t,r}.S;
                    tempSerror(r,:,:,:)= specgrams(a).output{d,e,t,r}.Serror;
                    
                    % package mean Specs and SpecErrors, squeeze out singleton
                    avg_specgram(a).output{d,e,t}.meanS=     squeeze(mean(tempS     ,1));
                    avg_specgram(a).output{d,e,t}.meanSerror=squeeze(mean(tempSerror,1));
                    
                    % package rest
                    avg_specgram(a).output{d,e,t}.Stime= specgrams(a).output{d,e,t,1}.Stime;
                    avg_specgram(a).output{d,e,t}.Sfreq= specgrams(a).output{d,e,t,1}.Sfreq;
                    
                end

            end
        end
    end
end
end

end


