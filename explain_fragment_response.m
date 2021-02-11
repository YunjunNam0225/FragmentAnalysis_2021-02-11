function [sOut]=explain_fragment_response(FR_OPTION, sFragIn,imgStimIn )
if( iscell(imgStimIn) )
    fprintf(1,'This function only receives a single image in the third parameter.\n');
    return;
end

%% Convert image to fit to CNS module
    nBand=length(sFragIn.iBandRange);
    [nStimHeight nStimWidth,iDummy] = size(imgStimIn);
    imgStimOri=single(mean(imgStimIn,3)/255);
            % Conver to gray scale image for ORI calculation

    imgStimColor=single(shiftdim(imgStimIn,2))/255;
                % Reshape original image([h x w x 3]) to imgTarget
                % ([3 x h x w]) for putting in CNS module (3: RGB).
        
%% Prepare variables
    iFragSize=size(sFragIn.dFeatureCandidate,2);
    dBackgroundGray=128/255;% GRAY = 0.502 (=128/255)

%% Calculation for each band    
    CNS=FR_OPTION.CNS;
    dMinDistInEachBand=zeros(1,nBand);    
        % Distance for each band will be calculated, then the minimum
        % will be found.    
    cC1Report=cell(1,nBand); 
        % We do not know the band with the minimum distance yet, so all information
        % related to c1 layers should be saved during the calculations for
        % each band
    
    for iBandIndex=1:nBand
        iBand=sFragIn.iBandRange(iBandIndex);
        fprintf(1,'[band: %d]\n',iBand);
        %% Initialize model for ORI and Color
        % variable for Gabor filter            
        iC1Overlap = CNS.iC1SP(iBand)/2; % Spatial pooling size for C1 layer.
        iS1FilterSize=CNS.iS1FilterSizeList(iBand*2-1);
        s1_fVals = set_fvals(CNS.filters,iS1FilterSize,length(CNS.iRot),iBand*2);
        
        % Image padding. bd: The width of boundary around the stimulus image        
        bd=(iS1FilterSize-1)+CNS.iC1SP(iBand)+iC1Overlap*(iFragSize-1);
        iPadSize=[nStimHeight+bd*2 nStimWidth+bd*2];
        imgPad=dBackgroundGray*ones(iPadSize,'single');  % [h x w] 
        iPadPosY=bd+1: bd+nStimHeight; % position to put the stim images
        iPadPosX=bd+1 : bd+nStimWidth;
        
        % Generate model for CNS
        q.bufSize   = iPadSize; q.baseSize  = iPadSize; q.numScales = 1;
        p = fhm_params(q,CNS.s2_type,iFragSize,s1_fVals,CNS.iC1SP(iBand));
        lib=struct;lib.groups{p.s2} = set_dict(...
            sFragIn.dFeatureCandidate(1:4,:,:),1,sFragIn.iMaskPos);
        m = fhpkg_model(p, lib);

        % The same procedure for RGB channels
        bd_col = bd - floor(iS1FilterSize/2);        
            % CNS model for color does not have S1 layer.
            % Therefore, pad image size should be shirinked with
            % floor( iS1FilterSize/2 ) pixels.
        iPadSize_col=[nStimHeight+bd_col*2 nStimWidth+bd_col*2];
        imgPad_col=dBackgroundGray*ones([3 iPadSize_col],'single');  % [3 x h x w] 
        iPadPosY_col = bd_col+1   :   bd_col+nStimHeight;
        iPadPosX_col = bd_col+1   :   bd_col+nStimWidth;
        p_col = fhm_params_col(iPadSize_col, CNS.s2_type,iFragSize, CNS.iC1SP(iBand));
        lib=struct;lib.groups{p_col.s2}=set_dict(...,
            sFragIn.dFeatureCandidate(5:7,:,:),1,sFragIn.iMaskPos);
        m_col = fhpkg_model( p_col, lib);
        
        %%  run CNS for local orientations
        cns('init', m, CNS.platform);
        fprintf(1,'   ORI: ');
        imgPad(iPadPosY,iPadPosX)=imgStimOri; % put Stim onto imgPad
        fhpkg_loadimage(m,imgPad);   % replace image for CNS
        cns('run');                  % run!        
        s2 =  cns('get',m.groups{p.s2}.zs, 'val') ; % get activation map for S2
        c1 = cns('get',4,'val'); % In ORI model, the fourth layer is corresponding to C1.
        fprintf(1,'\n');
        cns('done'); % release CNS.

        %% run CNS for colors
        cns('init', m_col, CNS.platform);
        fprintf(1,'   CLR: ');
        imgPad_col(:,iPadPosY_col,iPadPosX_col)=imgStimColor;
        cns('set',{1,'val', imgPad_col });
        cns('run');
        s2_col = cns('get',m_col.groups{p_col.s2}.zs,'val');           
        c1_col = cns('get',2,'val'); % In color model, the second layer is corresponding to C1.
        fprintf(1,'\n');
        cns('done'); % release CNS
            
        
        %% Blend ORI and color activation maps with blending ratio (alpha)
        dBlended=squeeze(sFragIn.dBlendRatio*s2+(1-sFragIn.dBlendRatio)*s2_col);
        [dMinDistInEachBand(iBandIndex),indBest]=min(dBlended(:)); % Find Min Dist
        [yMinDist,xMinDist]=ind2sub( size(dBlended),indBest);      % and its position

        %% find Location of sub-region with the Min. Dist.
        % the center of sub-region should be found from S2 layer for
        % internal reason.
        iMaskPos=sFragIn.iMaskPos;%for simple coding
        iTBLR_S2=[yMinDist+iMaskPos(1),yMinDist+iMaskPos(2),xMinDist+iMaskPos(3),xMinDist+iMaskPos(4)]; 
                % for easier calculation, change to [top, bottom, left, right] format
                % this location will be used to draw rectangle in S2 map
        dCenterYX_S2=[(iTBLR_S2(1)+iTBLR_S2(2))/2,(iTBLR_S2(3)+iTBLR_S2(4))/2];
        dCenterYX_ZeroOne=m_col.layers{2}.y_start+((dCenterYX_S2-1)*m_col.layers{2}.y_space);
            % transform the center position in the activation map (from 1 to S2_width)
            % to the relative position (from 0.0 to 1.0).
            % x_pos=x_start+index_in_matrix*x_space
        dCenterYX_S1=(dCenterYX_ZeroOne-m_col.layers{1}.y_start)/m_col.layers{1}.y_space+1;
            % transform the relative position to the index in S1 map (stim in pad)
            % index_in_matrix=(x_pos-x_start)/x_space
        dCenterYX_Stim=dCenterYX_S1-bd_col;
            % the position before the padding.
        
        % the size of sub-region should be found from C1 layer
        iRFSize(iBand)=uint32( m_col.layers{1}.size{2} * 2 * m_col.layers{3}.x_start );
        dRFSize=[iRFSize(iBand)*( iMaskPos(2)-iMaskPos(1)+1 )/iFragSize,...
                                iRFSize(iBand)*( iMaskPos(4)-iMaskPos(3)+1 )/iFragSize];
        dTBLR_Stim=[dCenterYX_Stim(1)-dRFSize(1)/2,dCenterYX_Stim(1)+dRFSize(1)/2,...
                dCenterYX_Stim(2)-dRFSize(2)/2,dCenterYX_Stim(2)+dRFSize(2)/2];
            
                
        %% Make report for C1 layer
        sC1Report=struct;
        sC1Report.c1=c1;sC1Report.c1_col=c1_col; % S2 map
        sC1Report.iTBLR_S2=iTBLR_S2;
        sC1Report.dTBLR_Stim=dTBLR_Stim;
        sC1Report.iC1Margin=bd/iPadSize(1)*m_col.layers{2}.size{2};
        sC1Report.F_o=sFragIn.dFeatureCandidate(1:4,[iMaskPos(1):iMaskPos(2)]+1,[iMaskPos(3):iMaskPos(4)]+1);
        sC1Report.F_c=sFragIn.dFeatureCandidate(5:7,[iMaskPos(1):iMaskPos(2)]+1,[iMaskPos(3):iMaskPos(4)]+1);
        sC1Report.S_o=c1(:,iTBLR_S2(1):iTBLR_S2(2),iTBLR_S2(3):iTBLR_S2(4));  
        sC1Report.S_c=c1_col(:,iTBLR_S2(1):iTBLR_S2(2),iTBLR_S2(3):iTBLR_S2(4));  
        sC1Report.iBand=iBand;
        sC1Report.dBlendRatio=sFragIn.dBlendRatio;
        
        cC1Report{iBandIndex}=sC1Report;

    end

    %% Find out the band achieved the minimum distance.
    [dTemp,iMinBandIndex]=min(dMinDistInEachBand);
    
    %% Visualize the fragment and c1 map for the band with the Min. Dist.
    sParam=struct;
    sParam.sFrag=sFragIn;
    sParam.imgStim=imgStimIn;
    sParam.sC1Report=cC1Report{iMinBandIndex};
    show_subregion(sParam);
    
    
end

function fVals = set_fvals(filters,rfsz,nrot,ifilt)
% Need optimization
    fVals = zeros(rfsz,rfsz,nrot);
    si = (ifilt-1)*nrot; % start index
    for k  =  1:4
        tmp = reshape(filters(1:rfsz^2,si+k),rfsz,rfsz);
        for i=1:rfsz
            for j=1:rfsz
                fVals(i,j,k) = tmp(i,j);
            end
        end
    end
end

function d = set_dict(dDict,iFrList,iMaskPos)
    d=struct;
    nFrag = length(iFrList);
    
    d.fVals  = dDict(:,:,:,iFrList);
    d.fSizes = size(dDict,2) * ones(nFrag,1);
    d.fSPos  = ones(nFrag,1);
    d.fYPos  = 0.5*ones(nFrag,1);
    d.fXPos  = 0.5*ones(nFrag,1);
    d.mPos  = iMaskPos;
end