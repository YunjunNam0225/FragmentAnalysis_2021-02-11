function FR_OPTION=init_fr()

persistent bAlreadyInitialized; % For tasks, such as path settings
if( isempty( bAlreadyInitialized ) )
    % Path setting
    strThisFile= mfilename('fullpath'); % The name of this file
    [strThisDir] = fileparts(strThisFile); % The directory of this file
    addpath(genpath(strThisDir));
    bAlreadyInitialized=true;
end


    %% Parameters for CNS module
    CNS=struct;
    CNS.iRot=[90 -45 0 45]; %Angles of Gabor filter
    CNS.Div=[4 4 3.9 3.9 3.8 3.8 3.7 3.7 3.6 3.6 3.5 3.5 3.4 3.4 3.3 3.3 3.2 3.2];
    CNS.iS1FilterSizeList    = [7 7 11 11 15 15 19 19 23 23 27 27 31 31 35 35 39 39];
    CNS.s2_type = 'gsedistdm';
    [fDummy,CNS.filters] = init_gabor(CNS.iRot, CNS.iS1FilterSizeList, CNS.Div);
    CNS.iC1SP = [8:2:22]; % Spatial pooling size for each band. Refer to handout page 6.
    CNS.iS2EdgeSize=[50,40,34,29,26,23,20,19;...
                          50,40,33,29,25,23,20,19;...
                          50,40,33,29,25,23,20,19;...
                          50,40,33,29,25,23,20,19];
    CNS.platform='gpu'; 
    cns('done');                    
                
    %% Output struct
    FR_OPTION=struct;                        
    FR_OPTION.CNS=CNS;
    
    
end
