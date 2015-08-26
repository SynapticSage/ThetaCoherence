% EnforceException
%
% Place inside process loop to implement exceptions in processing over sets
% of days. For example, if for one day, you'd like to process a different
% epoch. It's an inelegant solution, and I will be thinking about better
% solutions, but in the mean time, placing this script will do the trick.
% BETTER SOLUTION WOULD BE TO CHANGE ALL LOOPS to the loop type in
% AverageAcross2, except for gatherWindowsOfData. Then functions will not
% have to personally track which cellular elements have data.
%
% Calling a script in 4 functions is better than hard-coding it into 4
% functions. If you want to stop the exception, you just go to one place,
% here, and comment it out.

% Stores which exceptions have been applied in a function
if ~isstruct(exception)
    exception.init=[];
end

if d == 1 && e == 4 && ~ismember('d14',fields(exception))
	e = 6;
    exception.d16 = true;
end

if d == 1 && e == 2 && ~ismember('d16',fields(exception))
	e = 4;
    exception.d14 = true;
end

if d >=6 && d<=8 && e == 4
    e = 2;
end
	