function show_subregion( sParamIn )
% internal variables
dMaxOri=max( [ max( sParamIn.sC1Report.F_o(:) ) , max( sParamIn.sC1Report.S_o(:) )] );
iFontSize=8;

% create figure object.
    xCenti=18;yCenti=6;
    hFig=figure('OuterPosition',[0,0,xCenti/2*100,yCenti/2*100],'color','w',...
        'paperpositionmode','auto',...
        'paperunits','centimeters',... % From here, for PDF
      'papersize',[xCenti, yCenti],...
      'paperposition',[0,0,xCenti,yCenti]);

  
%% Draw figures for the feature candidate
% create axes for fragments
    dXLeft=0.05;dYBottom=0.7;dHeight=0.18;
    handles.hFragNat= axes('Position',[dXLeft dYBottom 0.06 dHeight]); 
    dXLeft=dXLeft+0.071;
    handles.hFragOri(1)  =axes('Position',[dXLeft+0.07*1 dYBottom 0.06 dHeight]); 
    handles.hFragOri(2)  =axes('Position',[dXLeft+0.07*2 dYBottom 0.06 dHeight]); 
    handles.hFragOri(3)  =axes('Position',[dXLeft+0.07*3 dYBottom   0.06 dHeight]);
    handles.hFragOri(4)  =axes('Position',[dXLeft+0.07*4 dYBottom   0.06 dHeight]);
    handles.hFragOriBar  =axes('Position',[dXLeft+0.35 dYBottom 0.01 dHeight/2]); %0d
    handles.hFragClr(1)     =axes('Position',[dXLeft+0.07*6 dYBottom 0.06 dHeight]); %0d
    handles.hFragClr(2)     =axes('Position',[dXLeft+0.07*7 dYBottom 0.06 dHeight]); %0d
    handles.hFragClr(3)     =axes('Position',[dXLeft+0.07*8 dYBottom   0.06 dHeight]); %0d
    handles.hFragClrBar  =axes('Position',[dXLeft+0.63 dYBottom 0.01 dHeight/2]); %0d
% visualize natural image fragment
    axes(handles.hFragNat);
    axis image off;hold on;
    image(sParamIn.sFrag.imgNat);
    x0=sParamIn.sFrag.iArea(1);x1=sParamIn.sFrag.iArea(2);y0=sParamIn.sFrag.iArea(3);y1=sParamIn.sFrag.iArea(4);
    line([x0 x1 x1 x0 x0],[y0 y0 y1 y1 y0],'Color','r','LineWidth',1.0);
    dWidth=max([x1-x0,y1-y0]);
    axis([x0-dWidth*0.3,x1+dWidth*0.3,y0-dWidth*0.3,y1+dWidth*0.3]);
    set(gca,'YDir','reverse');
% visualize ORI of feature candidate
    cStrOri={'0\circ','45\circ','90\circ','135\circ'};
    for iOri=1:4
        axes(handles.hFragOri(iOri));
        dMap=squeeze(sParamIn.sC1Report.F_o(iOri,:,:));
        nWidth=size(dMap,2);
        image( repmat( uint8(( 1-dMap/dMaxOri )*255), [1,1,3] ) ); % range: 0 - 255.
        text((nWidth+1)/2,1,cStrOri{iOri},...
                    'VerticalAlignment','bottom','HorizontalAlignment','center',...
                    'fontsize',iFontSize,'fontname','arial');
        adjust_image_axes(handles.hFragOri(iOri))
    end
% color bar for ORI
    axes( handles.hFragOriBar );axis off;
    clrMap=gray(64);
    for iGrad=1:64
        rectangle('position',[0.1,(iGrad-1)*(1/64), 0.5,1/64] ,...
        'FaceColor',clrMap(iGrad,:),...
        'LineStyle','none');
    end
    rectangle('position',[0.1,0, 0.5,1]);
    text(0.7,1,'0.0','fontsize',iFontSize,'fontname','arial');
    text(0.7,0,sprintf('%1.2f', dMaxOri ),...
        'fontsize',iFontSize,'fontname','arial');
    axis([0.1,0.6,0,1]);
    set(gca,'YDir','reverse');
% visualize CLR of feature candidate
    cStrClr={'R','G','B'};
    for iClr=1:3
        axes(handles.hFragClr(iClr));
        dMap=squeeze(sParamIn.sC1Report.F_c(iClr,:,:));
        nWidth=size(dMap,2);
        image( repmat( uint8(( 1-dMap )*255), [1,1,3] ) ); % range: 0 - 255.
        text((nWidth+1)/2,1,cStrClr{iClr},...
                    'VerticalAlignment','bottom','HorizontalAlignment','center',...
                    'fontsize',iFontSize,'fontname','arial');
        adjust_image_axes(handles.hFragClr(iClr))        
    end
% color bar for CLR
    axes( handles.hFragClrBar );axis off;
    clrMap=gray(64);
    for iGrad=1:64
        rectangle('position',[0.1,(iGrad-1)*(1/64), 0.5,1/64] ,...
        'FaceColor',clrMap(iGrad,:),...
        'LineStyle','none');
    end
    rectangle('position',[0.1,0, 0.5,1]);
    text(0.7,1,'0.0','fontsize',iFontSize,'fontname','arial');
    text(0.7,0,'1.0','fontsize',iFontSize,'fontname','arial');
    axis([0.1,0.6,0,1]);    
    set(gca,'YDir','reverse');

%% Draw figures for the stimulus    
% create axes for stimulus
    dXLeft=0.05;dYBottom=0.3;dHeight=0.18;
    handles.hStimNat= axes('Position',[dXLeft dYBottom 0.06 dHeight]); %0d
    dXLeft=dXLeft+0.071;
    handles.hStimOri(1)  =axes('Position',[dXLeft+0.07*1 dYBottom 0.06 dHeight]); %0d
    handles.hStimOri(2)  =axes('Position',[dXLeft+0.07*2 dYBottom 0.06 dHeight]); %0d
    handles.hStimOri(3)  =axes('Position',[dXLeft+0.07*3 dYBottom   0.06 dHeight]); %0d
    handles.hStimOri(4)  =axes('Position',[dXLeft+0.07*4 dYBottom   0.06 dHeight]); %0d
%     handles.hStimOriBar  =axes('Position',[dXLeft+0.35 dYBottom 0.01 dHeight/2]); %0d
    handles.hStimClr(1)     =axes('Position',[dXLeft+0.07*6 dYBottom 0.06 dHeight]); %0d
    handles.hStimClr(2)     =axes('Position',[dXLeft+0.07*7 dYBottom 0.06 dHeight]); %0d
    handles.hStimClr(3)     =axes('Position',[dXLeft+0.07*8 dYBottom   0.06 dHeight]); %0d
%     handles.hStimClrBar  =axes('Position',[dXLeft+0.63 dYBottom 0.01 dHeight/2]); %0d

% Show stim and sub-region
    axes( handles.hStimNat );axis off;
    image(sParamIn.imgStim);
    dDist= sParamIn.sC1Report.dBlendRatio*sum( ( sParamIn.sC1Report.F_o(:) - sParamIn.sC1Report.S_o(:)  ).^2 )+ ...
            (1-sParamIn.sC1Report.dBlendRatio)*sum( ( sParamIn.sC1Report.F_c(:) - sParamIn.sC1Report.S_c(:)  ).^2 );
    text(100,0,...
        sprintf('%1.4f',dDist),...
        'verticalalignment','bottom','fontsize',iFontSize-1);        
    rectangle('position',TBLR2xywh(sParamIn.sC1Report.dTBLR_Stim),...
            'EdgeColor','r','LineWidth',0.6);
    axis image off;
    
    
    iTBLR=sParamIn.sC1Report.iTBLR_S2;
    iTBLR=iTBLR+[-0.5,-0.5,+1,+1];
% Show S2 activation map and sub-region for ORI channels
    for iOri=1:4
        axes(handles.hStimOri(iOri));axis off;
        dMap=squeeze(sParamIn.sC1Report.c1(iOri,:,:));
        nWidth=size(dMap,2); % It is cubic.
        image( repmat( uint8(( 1-dMap/dMaxOri )*255), [1,1,3] ) ); % range: 0 - 255.
        rectangle('position',TBLR2xywh(iTBLR),'edgecolor','r','facecolor','none');        
        axis image off;
        axis([sParamIn.sC1Report.iC1Margin-1, nWidth-sParamIn.sC1Report.iC1Margin+1,...
            sParamIn.sC1Report.iC1Margin-1 nWidth-sParamIn.sC1Report.iC1Margin+1]);
        rectangle('position',[sParamIn.sC1Report.iC1Margin-0.5,...
            sParamIn.sC1Report.iC1Margin-0.5,...
            nWidth-2*sParamIn.sC1Report.iC1Margin+1,...
            nWidth-2*sParamIn.sC1Report.iC1Margin+1],...
                'EdgeColor','k','LineWidth',0.6);
        dDist=sParamIn.sC1Report.F_o(iOri,:,:)-sParamIn.sC1Report.S_o(iOri,:,:);
        dDist=sParamIn.sC1Report.dBlendRatio*sum( dDist(:).^2 );
        text(nWidth-sParamIn.sC1Report.iC1Margin,sParamIn.sC1Report.iC1Margin-1,...
            sprintf('%1.4f',dDist),...
            'verticalalignment','bottom','horizontalalignment','right','fontsize',iFontSize-1);
    end
    
% Show S2 activation map and sub-region for CLR channels
    for iClr=1:3
        axes(handles.hStimClr(iClr));axis off;
        dMap=squeeze(sParamIn.sC1Report.c1_col(iClr,:,:));
        image( repmat( uint8(( 1-dMap )*255), [1,1,3] ) ); % range: 0 - 255.
        rectangle('position',TBLR2xywh(iTBLR),'edgecolor','r','facecolor','none');        
        axis image off;
        axis([sParamIn.sC1Report.iC1Margin-1, nWidth-sParamIn.sC1Report.iC1Margin+1,...
            sParamIn.sC1Report.iC1Margin-1 nWidth-sParamIn.sC1Report.iC1Margin+1]);
        rectangle('position',[sParamIn.sC1Report.iC1Margin-0.5,...
            sParamIn.sC1Report.iC1Margin-0.5,...
            nWidth-2*sParamIn.sC1Report.iC1Margin+1,...
            nWidth-2*sParamIn.sC1Report.iC1Margin+1],...
                'EdgeColor','k','LineWidth',0.6);
        dDist=sParamIn.sC1Report.F_c(iClr,:,:)-sParamIn.sC1Report.S_c(iClr,:,:);
        dDist=(1-sParamIn.sC1Report.dBlendRatio)*sum( dDist(:).^2 );
        text(nWidth-sParamIn.sC1Report.iC1Margin,sParamIn.sC1Report.iC1Margin-1,...
            sprintf('%1.4f',dDist),...
            'verticalalignment','bottom','horizontalalignment','right','fontsize',iFontSize-1);
            
    end    
        
    

end

function adjust_image_axes(hAxes)

    hImg=findobj(hAxes,'type','image');
    XData=get(hImg,'XData');
    YData=get(hImg,'YData');
    dMin=min([XData(1),YData(1)])-0.5;
    dMax=max([XData(2),YData(2)])+0.5;
    rectangle('position',...
        [XData(1)-0.49,YData(1)-0.49,XData(2)-0.02,YData(2)-0.02],...
        'facecolor','none','edgecolor','k','linewidth',1);
    axis image off;
    axis([ dMin dMax dMin dMax]);

end

function dxywh_out=TBLR2xywh(dTBLR_in)
    dxywh_out=[dTBLR_in(3),dTBLR_in(1),...
                        dTBLR_in(4)-dTBLR_in(3),dTBLR_in(2)-dTBLR_in(1)]; 
end
    