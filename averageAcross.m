function [avg_specgram] = averageAcross(grams, sets)
% Function controls the averaging across spectrograms.

% if flag== trials, Output = Output(animals).{day,epoch,tetrode}

if ~ismember('coherograms',fields(sets))
    coherence = false;
else
    coherence = true;
end

sets.average={'trial'};
animNum= length(grams);
for a= 1:animNum;
    avg_specgram(a).animal= grams(a).animal;

% retrieve general info on array size and # of dims 
datSize(a,:)=  size(grams(a).output);
datDims(a,:)= ndims(grams(a).output);

% Get nonzero input array indices (linear indexing)
relevElem=find( ~cellfun(@isempty,grams(a).output));

% convert linear indices to subscript (dimensional) indices
[temp_idx{1:datDims}] = ind2sub(datSize(a,:),relevElem);

% assemble into one mat
idx=[temp_idx{:}]; clear temp_idx

% % get unique values from each dimension where data is stored
for u=1:datDims; uVals{u,:}=unique(idx(:,u),'rows')'; end;

if ismember('trial',sets.average) && coherence==false
    for d= uVals{1}
        for e= uVals{2}
            for t= uVals{3}
                
                % get the indices for all relevant inputs for this operation (avg across trials)
                idxs= idx( (idx(:,1)==d & idx(:,2)==e & idx(:,3)==t),:);
                
                for r= 1:length(idxs);
                    % store all gathered S'es and Serrors in temp matrices
                    tempC(r,:,:)       = grams(a).output{d,e,t,r}.S;
                    tempCerror(r,:,:,:)= grams(a).output{d,e,t,r}.Serror;
                    
                    % package mean Specs and SpecErrors, squeeze out singleton
                    avg_specgram(a).output{d,e,t}.S=     squeeze(mean(tempC     ,1));
                    avg_specgram(a).output{d,e,t}.Serror=squeeze(mean(tempCerror,1));
                    
                    % package rest
                    avg_specgram(a).output{d,e,t}.Stime= grams(a).output{d,e,t,1}.Stime;
                    avg_specgram(a).output{d,e,t}.Sfreq= grams(a).output{d,e,t,1}.Sfreq;
                    
                end

            end
        end
    end
elseif ismember('trial',sets.average) && coherence==true
    
    animals = fields(sets.animals);
    
    for d= uVals{1}
        for e= uVals{2}
            for t= sets.animals.(animals{a}).tetrodes
                for t2 = sets.animals.(animals{a}).tetrodes2
                
                % get the indices for all relevant inputs for this
                % operation (avg across trials)
                idxs= idx( (idx(:,1)==d & idx(:,2)==e & ...
                    idx(:,3)==t) & idx(:,4)==t2, :);
                
                for r= 1:length(idxs);
                    
                    input = grams(a).output{d,e,t,t2,r};
                    
                    % store all gathered S'es and Serrors in temp matrices
                    tempC(r,:,:)       = input.C;
                    tempCerror(r,:,:,:)= input.cerror;
                    
                    % package mean Specs and SpecErrors, squeeze out singleton
                    avg_specgram(a).output{d,e,t,t2}.C=     squeeze(mean(tempC     ,1));
                    avg_specgram(a).output{d,e,t,t2}.Cerror=squeeze(mean(tempCerror,1));
                    
                    % package rest
                    avg_specgram(a).output{d,e,t,t2}.Stime= input.Stime;
                    avg_specgram(a).output{d,e,t,t2}.Sfreq= input.Sfreq;
                    
                end
                
                end

            end
        end
    end
    
end 
    
end


end


