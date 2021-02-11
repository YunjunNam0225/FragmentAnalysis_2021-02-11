function p = fhm_params(q,s2_type,s2_fSizes,s1_fVals,c1sp)
%     if nargin < 6, is_s1frag = false; end
    if nargin < 7, is_colfrag = false; end

    p.groups = {};
    %***************************************************************************************************************
    c = struct;
    c.name = 'ri';
    c.type = 'ri';
    c.size = q.bufSize;
    p.groups{end + 1} = c;
    p.ri = numel(p.groups);

    c = struct;
    c.name        = 'pf';
    c.type        = 'pf';
    c.pg          = p.ri;
    c.baseSize    = q.baseSize;
%     c.scaleFactor = 2 ^ (1/4);
    c.scaleFactor = 1;
    c.numScales   = q.numScales;

    p.groups{end + 1} = c;
    p.pf = numel(p.groups);
    %***************************************************************************************************************
    c = struct;
    c.name    = 's1';
    c.type    = 'ndp';
    c.pg      = p.pf;
    c.rfCount = size(s1_fVals,1); 
    c.rfStep  = 1;
    c.fCount  = 4; 
    c.fParams = {'custom'};
    c.fVals = s1_fVals;

    p.groups{end + 1} = c;
    p.s1 = numel(p.groups);
    %***************************************************************************************************************
%     if ~is_s1frag
    c = struct;
    c.name    = 'c1';
    c.type    = 'max';
    c.pg      = p.s1;
    c.sCount  = 1;
    c.sStep   = 1;
    c.rfCount = c1sp; % C1 spatial pooling
    c.rfStep  = c.rfCount/2;

    p.groups{end + 1} = c;
    p.c1 = numel(p.groups);
%     end
    %***************************************************************************************************************
    c = struct;
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
    %***************************************************************************************************************
    if(false) % UNUSED. Only S2 is necessary to calculate d_ori and d_col
        c = struct;
        c.name    = 'c2';
        if strcmp(s2_type,'gsedistd') || strcmp(s2_type,'gsedistdm') || strcmp(s2_type,'gsedistdm4')
            c.type    = 'min';
        elseif strcmp(s2_type,'gnccd')
            c.type = 'max';
        end

        c.pg      = p.s2;
        c.sCount  = inf;
        c.rfCount = inf;

        p.groups{end + 1} = c;
        p.c2 = numel(p.groups);
    end
    %***************************************************************************************************************
end
