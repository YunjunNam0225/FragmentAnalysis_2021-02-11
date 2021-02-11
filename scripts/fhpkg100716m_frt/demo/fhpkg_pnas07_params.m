function p = fhpkg_pnas07_params(q)

% P = fhpkg_pnas07_params(Q) returns a parameter set defining the model used in
% [Serre et al. 2007].  Pass this parameter set to fhpkg_model (as illustrated
% in fhpkg_pnas07_run) to generate the corresponding CNS network model.
%
%    Q.bufSize - Size of buffer for storing images (before scaling).  Larger
%    images will be shrunk using imresize.
%
%    Q.baseSize - Size of the initial image pyramid (after scaling) at the most
%    detailed scale.  This affects the size of all higher levels.
%
%    Q.numScales - Number of scales in the initial image pyramid.
%
% The parameters needed to define each group depend on the cell type, and are
% determined by that cell type's ".m" file.
%
% See also: fhpkg_model, fhpkg_pnas07_run.

%***********************************************************************************************************************

p.groups = {};

%***********************************************************************************************************************

c = struct;
c.name = 'ri';
c.type = 'ri';
c.size = q.bufSize;

p.groups{end + 1} = c;
p.ri = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name        = 'si';
c.type        = 'si';
c.pg          = p.ri;
c.baseSize    = q.baseSize;
c.scaleFactor = 2 ^ (1/4);
c.numScales   = q.numScales;

p.groups{end + 1} = c;
p.si = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 's1';
c.type    = 'ndp';
c.pg      = p.si;
c.rfCount = 11;
c.rfStep  = 1;
c.fCount  = 4;
c.fParams = {'gabor', 0.3, 3.5, 2.8};

p.groups{end + 1} = c;
p.s1 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c1';
c.type    = 'max';
c.pg      = p.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 8;
c.rfStep  = 3;

p.groups{end + 1} = c;
p.c1 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name       = 's2b';
c.type       = 'grbfnorms';
c.fSizes     = [5 : 2 : 15];
c.pg         = p.c1;
c.rfCountMin = min(c.fSizes);
c.rfSpace    = 1;
c.rfStep     = 1;
c.sigma      = 1/3;

p.groups{end + 1} = c;
p.s2b = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c2b';
c.type    = 'max';
c.pg      = p.s2b;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
p.c2b = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name       = 's2';
c.type       = 'grbfnorms';
c.fSizes     = [3];
c.pg         = p.c1;
c.rfCountMin = min(c.fSizes);
c.rfSpace    = 1;
c.rfStep     = 1;
c.sigma      = 1/3;

p.groups{end + 1} = c;
p.s2 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c2';
c.type    = 'max';
c.pg      = p.s2;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 8;
c.rfStep  = 3;

p.groups{end + 1} = c;
p.c2 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name       = 's3';
c.type       = 'grbfnorms';
c.fSizes     = [3];
c.pg         = p.c2;
c.rfCountMin = min(c.fSizes);
c.rfSpace    = 1;
c.rfStep     = 1;
c.sigma      = 1/3;

p.groups{end + 1} = c;
p.s3 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c3';
c.type    = 'max';
c.pg      = p.s3;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
p.c3 = numel(p.groups);

%***********************************************************************************************************************

return;