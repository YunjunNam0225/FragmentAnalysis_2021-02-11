function [dOut]=calculate_fragment_response(FR_OPTION, sFragIn,cStimListIn )


%% Convert image to fit to CNS module
    nStim=size(cStimListIn,2);
    nBand=length(sFragIn.iBandRange);
    [nStimHeight nStimWidth,iDummy] = size(cStimListIn{1});
    cStimOri=cell(1,nStim);
    cStimColor=cell(1,nStim);
    for iStim = 1:nStim
        cStimOri{iStim}=single(mean(cStimListIn{iStim},3)/255);
                % Conver to gray scale image for ORI calculation

        cStimColor{iStim}=single(shiftdim(cStimListIn{iStim},2))/255;
                % Reshape original image([h x w x 3]) to imgTarget
                % ([3 x h x w]) for putting in CNS module (3: RGB).
    end
    
%% Prepare variables
    iFragSize=size(sFragIn.dFeatureCandidate,2);
    dBackgroundGray=128/255;% GRAY = 0.502 (=128/255)

%% Loop for each band    
    CNS=FR_OPTION.CNS;
    dMinDistInEachBand=zeros(nBand,nStim);
        % Distance for each band will be calculated, then the minimum
        % will be found.
        
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
        s2_all=zeros(nStim,m.layers{p.s2}.size{2},m.layers{p.s2}.size{3},'single');
            % each slice of s2_all is corresponding to 
            % \sum(| f_o - s_o |^2) in (3) of the manuscript.
        cns('init', m, CNS.platform);
        fprintf(1,'   ORI: ');
        for iStim=1:nStim % replace image and repeat
            if( mod(iStim,100)==1 ) fprintf(1,'%d, ',iStim); end
            imgPad(iPadPosY,iPadPosX)=cStimOri{iStim}; % put Stim onto imgPad
            fhpkg_loadimage(m,imgPad);   % replace image for CNS
            cns('run');                  % run!
            s2_all(iStim,:,:) =  cns('get',m.groups{p.s2}.zs, 'val') ; % get activation map for S2
        end

        fprintf(1,'\n');
        cns('done'); % release CNS.

        %% run CNS for colors
        s2_all_col=zeros(nStim,m_col.layers{p_col.s2}.size{2},m_col.layers{p_col.s2}.size{3},'single');
            % each slice of s2_all is corresponding to 
            % \sum(| f_c - s_c |^2) in (3) of the manuscript.
        cns('init', m_col, CNS.platform);
        fprintf(1,'   CLR: ');
        for iStim=1:nStim % replace image and repeat
            if( mod(iStim,100)==1 ) fprintf(1,'%d, ',iStim); end
            imgPad_col(:,iPadPosY_col,iPadPosX_col)=...
                            cStimColor{iStim};
            cns('set',{1,'val', imgPad_col });
            cns('run');
            s2_all_col(iStim,:,:)...
                            = cns('get',m_col.groups{p_col.s2}.zs,'val');            
        end
        fprintf(1,'\n');
        cns('done'); % release CNS
            
        
        %% Blend ORI and color activation maps with blending ratio (alpha)
        dBlended=sFragIn.dBlendRatio*s2_all+(1-sFragIn.dBlendRatio)*s2_all_col;
        dMinDistInEachBand(iBandIndex,:) = min(min(dBlended, [], 3), [], 2);
            % each element of dMinDistInEachBand is corresponing to d' 
            % in the manuscript.

    end
    
    dOut=exp(-1*min(dMinDistInEachBand,[],1));
        % Find the minimum across the bands, and transfer with RBF.
        % each element of this vector is corresponding to x in (5)
        % of the manuscript.
    
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