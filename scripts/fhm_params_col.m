function p = fhm_params_col(bufSize, s2_type,s2_fSizes,c1sp)
    p.groups={};

    c = struct;
    c.name = 'ri';
    c.type = 'riMultiDim';
    c.size = [3 bufSize(1) bufSize(2)];
    p.groups{end + 1} = c;
    p.ri = numel(p.groups);
    
   %***************************************************************************************************************
   
    c = struct; % Averaging
    c.name    = 'c1';
    c.type    = 'avg';
    c.pg      = p.ri;
    c.sCount  = 1;
    c.sStep   = 1;
    c.rfCount = c1sp;
    c.rfStep  = c.rfCount/2;
    
    p.groups{end + 1} = c;
    p.c1 = numel(p.groups);    
    
    %***************************************************************************************************************
    c = struct; % Distance
    c.name       = 's2';
    c.type       = 'distmdruid';
    c.fSizes     = s2_fSizes;
    c.pg         = p.c1;
    c.rfCountMin = min(c.fSizes);
    c.rfSpace    = 1;
    c.rfStep     = 1;
    c.sigma      = 1;
    
    p.groups{end + 1} = c;
    p.s2 = numel(p.groups);
end
