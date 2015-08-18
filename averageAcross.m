function [avg_specgram] = averageAcross(specgrams, sets)
% Function controls the averaging across spectrograms.

% if flag== trials, Output = Output(animals).{day,epoch,tetrode}

animNum= length(Output);
for i= 1:animNum;
    datSize(i,:)= size(Output(i).output);
end

relevElem=find( ~cellfun(@isempty,Output(i).output));
for el= 1:length(relevElem)
[day(el), epc(el), tet(el), tri(el)]= ind2sub(datSize(i,:),relevElem(el));
end

idx=[day; epc; tet; tri]';

uDay= unique(day);
uEpc= unique(epc);
uTet= unique(tet);
uTri= unique(tri);

if sets == 'trials'
   for a=1:animNum;
        for d=1:length(uDay); 
            for e= 1:length(uEpc);
                for t=1:length(uTet);
                    idxs= idx((idx(:,1)== uDay(d) & idx(:,2)== uEpc(e) & idx(:,3)== uTet(t) ),:);
                    for r=1:length(idxs);
                               tempS(r,:,:)= Output(i).output{uDay(d), uEpc(e), uTet(t), r}.S;
                        tempSerror(r,:,:,:)= Output(i).output{uDay(d), uEpc(e), uTet(t), r}.Serror;
                    end 
                    avg_specgram(a).meanS{     uDay(d), uEpc(e), uTet(t)} = squeeze(mean(tempS,1));
                    avg_specgram(a).meanSerror{uDay(d), uEpc(e), uTet(t)} = squeeze(mean(tempSerror,1));

                end
            end
        end 
   end
    

end