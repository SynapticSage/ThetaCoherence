function plotSingleSample(pos,ssi,i)
    
    data = pos.data;
    init = ssi(i,1);
    fin = ssi(i,2);
    
    plot( data(:,2),        data(:,3)       );
    hold on;
    plot( data(init:fin,2), data(init:fin,3),'*-');
    hold off;

end