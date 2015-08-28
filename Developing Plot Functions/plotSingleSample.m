function plotSingleSample(pos,ssi,i)

    if isstruct(pos) 
        data = pos.data;
        init = ssi(i,1);
        fin = ssi(i,2);
    elseif iscell(pos)
        if pos{2}<10; ds=['0' num2str(pos{2})]; else ds=['0' num2str(pos{2})];end
        temp = load([pos{1} 'pos' ds])
        data=temp.pos{pos{2}}{pos{3}}.data;
    end
    
    plot( data(:,2),        data(:,3)       );
    hold on;
    plot( data(init:fin,2), data(init:fin,3),'*-');
    hold off;

end