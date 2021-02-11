function varargout = fhpkg_cns_type_sd(method, varargin)

% Defines the "sd" cell type.  An "sd" cell computes the response of a patch of cells in the previous layer to a stored
% (learned) template of the same size.  The "d" stands for "dense" -- the stored templates contain values for every
% feature at every position.
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

% Holds the stored values that make up the templates.  The "f" dimension represents features in the previous
% layer, and the "nf" dimension represents the template number.  Comes from the dictionary, set in the "addgroup"
% method below.
d.fVals = {'ga', 'private', 'cache', 'dims', {[1 2] 1 2 [1 2]}, 'dparts', {[2 2] 1 1 [3 3]}, ...
    'dnames', {'f' 'y' 'x' 'nf'}};

% Size of each template.  Comes from the dictionary, set in the "addgroup" method below.
d.fSizes = {'ga', 'private', 'dims', {[1 2]}, 'dparts', {[1 1]}, 'dnames', {'nf'}, 'int'};

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "sd" group G, defined by parameters P and dictionary D, to a network model.  Called from fhpkg_model via the
% package-level "add" method.  Additional parameters are:
%
%    P.rfCountMin - minimum size of a (square) template.
%
%    P.rfSpace - separation of units within a template (1 = contiguous).
%
%    P.rfStep - distance between "sd" cell centers, in number of previous layer units.  Commonly 1.

pgzs = m.groups{p.pg}.zs;
pfCount = m.layers{pgzs(1)}.size{1};

if ~isfield(d, 'fSizes')
    d.fSizes = [];
    d.fVals  = [];
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

if isempty(d.fSizes) && isempty(d.fVals)
    d.fVals = reshape(d.fVals, pfCount, p.rfCountMin, p.rfCountMin, 0);
end

if size(d.fVals, 1) ~= pfCount
    error('dimension 1 of fVals must match the previous group''s feature count');
end
if size(d.fVals, 2) ~= size(d.fVals, 3)
    error('dimensions 2 and 3 of fVals must be the same size');
end
if size(d.fVals, 2) < max([d.fSizes(:)', 0])
    error('dimensions 2 and 3 of fVals are smaller than the largest fSize');
end
if size(d.fVals, 4) ~= numel(d.fSizes)
    error('dimension 4 of fVals must match the length of fSizes');
end

m.groups{g}.rfCountMin = p.rfCountMin;
m.groups{g}.rfSpace    = p.rfSpace;
m.groups{g}.fVals      = d.fVals;
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

% Called automatically by cns('init') via the package-level "init" method.

m = cns_super(m, g);

c = m.groups{g};

pz = m.layers{c.zs(1)}.pzs(1);
fCounts = m.layers{pz}.size{1};

c.fVals_size = cns_size(c.fVals, 4);
c.fVals_size{1} = fCounts;

m.groups{g} = c;

return;