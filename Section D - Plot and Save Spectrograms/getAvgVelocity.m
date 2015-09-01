function [speed, sem, binSpec] =getAvgVelocity(grams,beh_data, a, d, e, t, t2, tr)
%GETAVGVELOCITY Get average velocity across trials
%   pass in spectrograms or coherograms in gram 
%	pass in sets struct containing information about what days, epochs and
%	tetrodes to average over in sets


if d< 10; dstr= ['0' num2str(d)]; else dstr= num2str(d); end;

% % fix this later
% if d == 1 && e==2; e=4; end; 
% if d == 1 && e==4; e=6; end; Commented out code doesn't work because it
% changes 2 to 4 and then the very next line changes 4 to 6. This has the
% effect of transforming 2 to 6. Reversing the lines doesn't work either.
exception=[];
EnforceException;

posData = beh_data.pos{d,e}.data;
posIndices= beh_data.ssi{d,e};

for i= 1:length(posIndices)
tempidx= posIndices(i,:);
velVector(i,:)= posData(tempidx(1):tempidx(2)-1,5);
end

% have ==> [trials x pos bin #] :::: end goal==> [trials x spec bin #] 
% (sloppy below. padding with NaNs for uneven spectrogram bins) 
%
temp = grams.output{d,e,t,t2,tr};

% calculate relevant dimensions for reshaping and padding
dimSpec= size(temp.Stime,2);
dimTrial= size(velVector,1);
dimPos= size(velVector,2);

% How many NaN columns needed to make pos bin # divisible by spec bin #?
pad= dimSpec- rem(dimPos, dimSpec);

% add NaN columns to the velVector matrix
velVectorPad= [velVector nan([dimTrial, pad])];

% what size are the new pos bins that match up with the spec bin #?
newBinWidth= size(velVectorPad,2)/dimSpec;

% make a 3D matrix [trial x new binsize x spec bin #] 
velVectorBins=reshape(velVectorPad, [dimTrial, newBinWidth, dimSpec]);

% take average across new bin, now have [trial x spec bin #]
newVelVector= squeeze(nanmean(velVectorBins,2));

speed= mean(newVelVector);
sem= std(newVelVector) ./ sqrt(size(newVelVector,1));

binTime= diff(temp.Stime);
binSpec= [newBinWidth, binTime(1)]; 

end