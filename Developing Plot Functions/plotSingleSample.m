function plotSingleSample(pos,ssi,i)
    
    data = pos.data;
    init = ssi(i,1);
    fin = ssi(i,2);
    center = round((ssi(i,2)-ssi(i,1))/2) + ssi(i,1);
    
    plot( data(:,2),        data(:,3)       );
    hold on;
    plot( data(init:fin,2), data(init:fin,3),'*-');
     plot( data(center,2), data(center,3),'o','LineWidth',2,...
    'MarkerSize',10,...
    'MarkerEdgeColor','b',...
    'MarkerFaceColor',[0.5,0.5,0.5]);
    hold off;

end