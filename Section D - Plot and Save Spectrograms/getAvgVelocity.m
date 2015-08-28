function [speed, error, sem] =getAvgVelocity(grams, sets, acquisition, a, d, e, t, t2, tr)
%GETAVGVELOCITY Get average velocity across trials
%   pass in spectrograms or coherograms in gram 
%	pass in sets struct containing information about what days, epochs and
%	tetrodes to average over in sets


if d< 10; dstr= ['0' num2str(d)]; else dstr= num2str(d); end;

posPath= [acquisition.animal 'pos' dstr '.mat'];
load(posPath);
posData= pos{1,1}{1,e}.data;
posIndices=acquisition.ssi{d,e};

for i= 1:length(posIndices);
temp= posIndices(i,:);
velVector(i,:)= posData(temp(1):temp(2),5);
end

speed= mean(velVector);
sem= std(velVector) ./ sqrt(size(velVector,1));

errorbar(1:301,speed,sem);

end