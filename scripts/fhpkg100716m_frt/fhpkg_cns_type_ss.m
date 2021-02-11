function varargout = fhpkg_cns_type_ss(method, varargin)

% Defines the "ss" cell type.  An "ss" cell computes the response of a patch of cells in the previous layer to a stored
% (learned) template of the same size.  The second "s" stands for "sparse" -- the stored templates may ignore the
% values of some features at any given position.
%
% Note that the stored templates can have different sizes, which means that not all templates will 'fit' at all
% positions.  When this occurs, output cells will have the value cns_fltmin.
%
% This is an abstract type; the particular function used to compute the response is undefined (and left to subtypes).

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.abstract = true;
p.methods  = {'addgroup', 'initgroup'};

return;

%***********************************************************************************************************************

function d = method_fields

d.rfCountMin = {'gp', 'private', 'int'}; % Minimum size of a (square) template.
d.rfSpace    = {'gp', 'private', 'int'}; % Separation of units within a template (1 = contiguous).

% Hold the stored values that make up the templates.  These are stored in a sparse format (see fhpkg_sparsify).  Both
% come from the dictionary, in the "addgroup" method below.  fMap2 is generated in the "initgroup" method below.
d.fVals = {'ga', 'private', 'cache', 'dims', {1 [2 2]}, 'dparts', {1 [1 2]}, 'dnames', {'p' 'nf'}};
d.fMap2 = {'ga', 'private', 'cache', 'dims', {1 [2 2]}, 'dparts', {1 [1 2]}, 'dnames', {'p' 'nf'}, 'int'};

% Size of each template.  Comes from the dictionary, set in the "addgroup" method below.
d.fSizes = {'ga', 'private', 'dims', {[1 2]}, 'dparts', {[1 1]}, 'dnames', {'nf'}, 'int'};

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "ss" group G, defined by parameters P and dictionary D, to a network model.  Called from fhpkg_model via the
% package-level "add" method.  Additional parameters are:
%
%    P.rfCountMin - minimum size of a (square) template.
%
%    P.rfSpace - separation of units within a template (1 = contiguous).
%
%    P.rfStep - distance between "ss" cell centers, in number of previous layer units.  Commonly 1.

pgzs = m.groups{p.pg}.zs;

if ~isfield(d, 'fSizes')
    d.fSizes = [];
    d.fVals  = [];
    d.fMap   = [];
    d.fSPos  = [];
    d.fYPos  = [];
    d.fXPos  = [];
end

if any(d.fSizes < 1), error('invalid fSizes value'); end
if mod(p.rfSpace, 2) == 1
    temp = (mod(d.fSizes, 2) == 1);
    if any(temp) && ~all(temp)
        error('when rfSpace is odd, fSizes must be all even or all odd');
    end
end

if isempty(d.fSizes)
    if isempty(d.fVals), d.fVals = reshape(d.fVals,    0, 0); end
    if isempty(d.fMap ), d.fMap  = reshape(d.fMap , 3, 0, 0); end
end

if size(d.fVals, 2) ~= numel(d.fSizes)
    error('dimension 2 of fVals must match the length of fSizes');
end

if size(d.fMap, 1) ~= 3
    error('dimension 1 of fMap must have size 3');
end
if size(d.fMap, 2) ~= size(d.fVals, 1)
    error('dimension 2 of fMap must match dimension 1 of fVals');
end
if size(d.fMap, 3) ~= size(d.fVals, 2)
    error('dimension 3 of fMap must match dimension 2 of fVals');
end

m.groups{g}.rfCountMin = p.rfCountMin;
m.groups{g}.rfSpace    = p.rfSpace;
m.groups{g}.fVals      = d.fVals;
m.groups{g}.fMap       = d.fMap;
m.groups{g}.fSizes     = d.fSizes(:);
m.groups{g}.fSPos      = d.fSPos(:); % May be needed by "g" filter.
m.groups{g}.fYPos      = d.fYPos(:); % May be needed by "g" filter.
m.groups{g}.fXPos      = d.fXPos(:); % May be needed by "g" filter.

rfWidthMin = 1 + (p.rfCountMin - 1) * p.rfSpace;

zs = numel(m.layers) + (1 : numel(pgzs));

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = pgzs(i);

    m.layers{z}.size{1} = numel(d.fSizes);
    m = cns_mapdim(m, z, 2, 'int', pgzs(i), rfWidthMin, p.rfStep, p.parity);
    m = cns_mapdim(m, z, 3, 'int', pgzs(i), rfWidthMin, p.rfStep, p.parity);

end

return;

%***********************************************************************************************************************

function m = method_initgroup(m, g)

% Generates fMap2 from fMap (which comes from the dictionary).  This format is a bit more memory efficient.  Called
% automatically by cns('init') via the package-level "init" method.

m = cns_super(m, g);

c = m.groups{g};

pz = m.layers{c.zs(1)}.pzs(1);
fCounts = m.layers{pz}.size{1};

if any(fCounts > 256)
    error('previous group can have at most 256x256 features');
end
if any(c.fSizes > 128)
    error('maximum fSizes value cannot exceed 128');
end

fs = double(shiftdim(c.fMap(1, :, :))) - 1;
ys = double(shiftdim(c.fMap(2, :, :))) - 1;
xs = double(shiftdim(c.fMap(3, :, :))) - 1;

cs = sum(fs >= 0, 1);
f0 = mod(fs, fCounts(1));
f1 = floor(fs / fCounts(1));

is = f0;
is = is + f1 * 256;
is = is + ys * 256 * 256;
is = is + xs * 256 * 256 * 256;

c.fMap2 = [cs; is]; % The first position in the table for each template is the number of values.

m.groups{g} = c;

return;