function p = fhpkg_cvpr06_full_params(q)

% P = fhpkg_cvpr06_full_params(Q) returns a parameter set defining the "full"
% model used in [Mutch & Lowe 2006].  Similar to fhpkg_cvpr06_base_params; see
% that function for more detail.
%
% See also: fhpkg_cvpr06_base_params.

%***********************************************************************************************************************

p.groups = {};

%***********************************************************************************************************************

c = struct;
c.name = 'ri';
c.type = 'ri'; % raw image
c.size = q.bufSize; % [400 600]

p.groups{end + 1} = c;
p.ri = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name        = 'si';
c.type        = 'si'; % scaled image
c.pg          = p.ri; % parent group
c.baseSize    = q.baseSize; % [140 140]
c.scaleFactor = 2 ^ (1/4);
c.numScales   = q.numScales; % 9

p.groups{end + 1} = c;
p.si = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 's1i0';
c.type    = 'ndp';
c.pg      = p.si; % parent group
c.rfCount = 11;
c.rfStep  = 1;
c.fCount  = 12; % num of orientations (probably)
c.fParams = {'gabor', 0.3, 5.6410, 4.5128};

p.groups{end + 1} = c;
p.s1i0 = numel(p.groups);

c = struct;
c.name    = 's1i1';
c.type    = 'li1';
c.pg      = p.s1i0;
c.inhibit = 0.5;

p.groups{end + 1} = c;
p.s1i1 = numel(p.groups);

c = struct;
c.name = 's1';
c.type = 'li2';
c.pg   = p.s1i0;
c.ig   = p.s1i1;

p.groups{end + 1} = c;
p.s1 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c1i0';
c.type    = 'max';
c.pg      = p.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 10;
c.rfStep  = 5;

p.groups{end + 1} = c;
p.c1i0 = numel(p.groups);

c = struct;
c.name    = 'c1i1';
c.type    = 'li1';
c.pg      = p.c1i0;
c.inhibit = 0.5;

p.groups{end + 1} = c;
p.c1i1 = numel(p.groups);

c = struct;
c.name = 'c1';
c.type = 'li2';
c.pg   = p.c1i0;
c.ig   = p.c1i1;

p.groups{end + 1} = c;
p.c1 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name       = 's2';
c.type       = 'grbfs';
c.fSizes     = [4 8 12 16];
c.pg         = p.c1;
c.rfCountMin = min(c.fSizes);
c.rfSpace    = 1;
c.rfStep     = 1;
c.sigma      = 1;

p.groups{end + 1} = c;
p.s2 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c2';
c.type    = 'gmax';
c.pg      = p.s2;
c.rfType  = 'win';
c.sCount  = inf;
c.yCount  = inf;
c.xCount  = inf;
c.sTol    = 1;
c.yxTol   = 0.0575;

p.groups{end + 1} = c;
p.c2 = numel(p.groups);

%***********************************************************************************************************************

return;