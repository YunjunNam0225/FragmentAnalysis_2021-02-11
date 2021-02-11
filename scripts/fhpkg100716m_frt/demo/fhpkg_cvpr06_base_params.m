function p = fhpkg_cvpr06_base_params(q)

% P = fhpkg_cvpr06_base_params(Q) returns a parameter set defining the "base"
% model used in [Mutch & Lowe 2006].  Pass this parameter set to fhpkg_model (as
% illustrated in fhpkg_cvpr06_run) to generate the corresponding CNS network
% model.
%
%    Q.bufSize - Size of buffer for storing images (before scaling).  Larger
%    images will be shrunk using imresize.
%
%    Q.baseSize - Size of the initial image pyramid (after scaling) at the most
%    detailed scale.  This affects the size of all higher levels.
%
%    Q.numScales - Number of scales in the initial image pyramid.
%
% The parameters needed to define each group depend on the cell type; see each
% cell type's ".m" file for a description of its parameters.
%
% See also: fhpkg_model, fhpkg_cvpr06_run.

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
c.fParams = {'gabor', 0.3, 5.6410, 4.5128};

p.groups{end + 1} = c;
p.s1 = numel(p.groups);

%***********************************************************************************************************************

c = struct;
c.name    = 'c1';
c.type    = 'max';
c.pg      = p.s1;
c.sCount  = 2;
c.sStep   = 1;
c.rfCount = 10;
c.rfStep  = 5;

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
c.type    = 'max';
c.pg      = p.s2;
c.sCount  = inf;
c.rfCount = inf;

p.groups{end + 1} = c;
p.c2 = numel(p.groups);

%***********************************************************************************************************************

return;