function [avg_specgram] = averageAcross(specgrams, sets, params)
% Function controls the averaging across spectrograms.

% if flag== trials, Output = Output(animals).{day,epoch,tetrode}
sets='trials';
animNum= length(specgrams);

for a= 1:animNum;

% retrieve general info on array size and # of dims 
datSize(a,:)= size(specgrams(a).output);
datDims(a,:)= ndims(specgrams(a).output);

% Get nonzero input array indices (linear indexing)
relevElem=find( ~cellfun(@isempty,specgrams(a).output));

% convert linear indices to subscript (dimensional) indices
[day, epc, tet, tri]=ind2sub(datSize(a,:),relevElem);

% assemble into one mat
idx= [day epc tet tri];

% get unique values from each dimension where data is stored
uDay= unique(day); uEpc= unique(epc);
uTet= unique(tet); %uTri= unique(tri);

if sets == 'trials';
    for d= 1:length(uDay);
        for e= 1:length(uEpc);
            for t= 1:length(uTet);
                
                % get the indices for all relevant inputs for this operation (avg across trials)
                idxs= idx((idx(:,1)== uDay(d) &...
                           idx(:,2)== uEpc(e) &...
                           idx(:,3)== uTet(t) ),:);
                
                for r= 1:length(idxs);
                    % store all gathered S'es and Serrors in temp matrices
                    tempS(r,:,:)=...
                    specgrams(a).output{uDay(d), uEpc(e), uTet(t), r}.S;
                    tempSerror(r,:,:,:)=...
                    specgrams(a).output{uDay(d), uEpc(e), uTet(t), r}.Serror;
                end
                
                % package mean Specs and SpecErrors, squeeze out singleton
                avg_specgram(a).output{uDay(d), uEpc(e), uTet(t)}...
                .meanS     =squeeze(mean(tempS     ,1));
                avg_specgram(a).output{uDay(d), uEpc(e), uTet(t)}...
                .meanSerror=squeeze(mean(tempSerror,1));
            end
        end
    end
end
end

