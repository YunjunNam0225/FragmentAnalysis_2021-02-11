function varargout = fhpkg_cns_type_s1(method, varargin)

% Defines the "s1" cell type.  An "s1" group applies precomputed filters (eg. gabor filters) to an image.
%
% This is an abstract type; the particular function used to apply the filters is undefined (and left to subtypes).

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

% Holds the precomputed filters.  Automatically computed by the "initgroup" method below.
d.fVals = {'ga', 'private', 'cache', 'dims', {1 2 [1 2]}, 'dparts', {1 1 [2 2]}, 'dnames', {'y' 'x' 'f'}};

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "s1" group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level "add"
% method.  D is ignored.  Additional parameters are:
%
%    P.rfCount - size of the (square) filters in pixels.
%
%    P.rfStep - distance between "s1" cell centers, in pixels.  Commonly 1.
%
%    P.fCount - number of precomputed filters.
%
%    P.fParams - a cell array of parameters that define the filter function.  The first element is the function name,
%    eg., 'gabor', and the remaining elements depend on the function.

pgzs = m.groups{p.pg}.zs;

if m.layers{pgzs(1)}.size{1} ~= 1
    error('g=%u: previous group must have only a single feature', g);
end

m.groups{g}.rfCount = p.rfCount;
m.groups{g}.fParams = p.fParams;

if strcmp(p.fParams{1}, 'custom')
    if numel(p.fParams) > 1, error('too many fParams'); end
    if ~isequal(size(p.fVals), [p.rfCount p.rfCount p.fCount]), error('invalid fVals size'); end
    m.groups{g}.fVals = p.fVals;
end

zs = numel(m.layers) + (1 : numel(pgzs));

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = pgzs(i);

    m.layers{z}.size{1} = p.fCount;
    m = cns_mapdim(m, z, 2, 'int', pgzs(i), p.rfCount, p.rfStep, p.parity);
    m = cns_mapdim(m, z, 3, 'int', pgzs(i), p.rfCount, p.rfStep, p.parity);

end

return;

%***********************************************************************************************************************

function m = method_initgroup(m, g)

% Generates the precomputed filters.  Called automatically by cns('init') via the package-level "init" method.

c = m.groups{g};

if ~strcmp(c.fParams{1}, 'custom')

    fCount = m.layers{c.zs(1)}.size{1};

    switch c.fParams{1}
    case 'gabor', c.fVals = GenerateGabor(c.rfCount, fCount, c.fParams{2 : end});
    otherwise   , error('invalid filter type');
    end

    for f = 1 : fCount
        a = c.fVals(:, :, f);
        a = a - mean(a(:));
        a = a / sqrt(sum(a(:) .* a(:)));
        c.fVals(:, :, f) = a;
    end

end

m.groups{g} = c;

m = cns_super(m, g);

return;

%***********************************************************************************************************************

function fVals = GenerateGabor(rfCount, fCount, aspectRatio, lambda, sigma)

fVals = zeros(rfCount, rfCount, fCount);

points = (1 : rfCount) - ((1 + rfCount) / 2);

for f = 1 : fCount

    theta = (f - 1) / fCount * pi;

    for j = 1 : rfCount
        for i = 1 : rfCount

            x = points(j) * cos(theta) - points(i) * sin(theta);
            y = points(j) * sin(theta) + points(i) * cos(theta);

            if sqrt(x * x + y * y) <= rfCount / 2
                e = exp(-(x * x + aspectRatio * aspectRatio * y * y) / (2 * sigma * sigma));
                e = e * cos(2 * pi * x / lambda);
            else
                e = 0;
            end

            fVals(i, j, f) = e;

        end
    end

end

return;