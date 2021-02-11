function varargout = fhpkg_cns_type_c(method, varargin)

% Defines the "c" cell type.  A "c" cell pools the values of nearby cells (in position or scale) in a previous group.
%
% This is an abstract type; the particular pooling function is undefined (and left to subtypes).

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

% Note: both these fields are set by the "addgroup" method below.

d.yCount = {'gp', 'private', 'mv'}; % Height of the pooling window, in number of input cells (at the finest scale).
d.xCount = {'gp', 'private', 'mv'}; % Width of the pooling window, in number of input cells (at the finest scale).

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "c" group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level "add"
% method.  D is ignored.  Additional parameters are:
%
%    P.sCount - number of scales across which a cell pools.  Inf = all scales.
%
%    P.sStep - step size (in scale) with which we tile the previous group.  Commonly 1.
%
%    P.rfType - type of pooling over (y, x); either 'int' or 'win'.
%
% If P.rfType == 'int', we tile in integral steps over the previous layer; the following quantities are numbers of
% cells in the previous layer (at the finest scale being pooled):
%
%       P.rfCount - size of the (square) receptive field.  Inf = global pooling.
%
%       P.rfStep - distance between "c" cell centers.
%
% If P.rfType == 'win', we slide a window over the previous layer; however, the following quantities are specified in
% terms of pixels in the first (finest) scale in the scaled image, and need not be integers:
%
%       P.yCount, P.xCount - height and width of the sliding window.
%
%       P.yStep, P.xStep - vertical and horizontal distance between sliding window positions.
%
%       P.yMargin, P.xMargin - vertical and horizontal margins.  Positive quantities mean we ignore positions near the
%       edges, and negative quantities mean we slide the window off the edges.
%
%       P.ig - group number of the scaled image.

pgzs = m.groups{p.pg}.zs;

if isfield(p, 'sNos')
    % rfType must be 'int'
    pzs = cell(1, numel(p.sNos));
    for i = 1 : numel(p.sNos)
        pzs{i} = pgzs(p.sNos{i});
    end
else
    if p.sCount >= cns_intmax
        pzs = {pgzs};
    else
        if numel(pgzs) < p.sCount, error('g=%u: not enough input layers', g); end
        pzs = {};
        for i = 1 : p.sStep : numel(pgzs) - p.sCount + 1
            pzs{end + 1} = pgzs(i) + (0 : p.sCount - 1);
        end
    end
end

if isfield(p, 'rfType')
    mode = p.rfType;
else
    mode = 'int';
end

switch mode
case 'int'

    if any(p.rfCount >= cns_intmax)

        if ~isscalar(p.rfCount)
            error('multiple pooling sizes must all be finite');
        end

        m.groups{g}.yCount = cns_intmax;
        m.groups{g}.xCount = cns_intmax;

        yArgs = {cns_intmax};
        xArgs = {cns_intmax};

    else

        m.groups{g}.yCount = p.rfCount(:)';
        m.groups{g}.xCount = p.rfCount(:)';

        yArgs = {min(p.rfCount), p.rfStep, p.parity};
        xArgs = {min(p.rfCount), p.rfStep, p.parity};

    end

case 'win'

    if ~isscalar(p.yCount) || ~isscalar(p.xCount)
        error('multiple pooling sizes not allowed with rfType "win"');
    end

    if xor(p.yCount >= cns_intmax, p.xCount >= cns_intmax)
        error('yCount and xCount must be both finite or both infinite');
    end

    if p.yCount >= cns_intmax

        if p.sCount < cns_intmax
            error('for rfType "win", y/xCount cannot be infinite with sCount finite');
        end

        % We don't use "infinite" here because we want to have a window size for the "g" subclass to use.

        m.groups{g}.yCount = 1 / m.layers{pgzs(1)}.y_space;
        m.groups{g}.xCount = 1 / m.layers{pgzs(1)}.x_space;

        yArgs = {cns_intmax};
        xArgs = {cns_intmax};

    else

        % Window size is expressed in full-scale image coordinates.

        iz = m.groups{p.ig}.zs(1);
        yFactor = m.layers{iz}.y_space / m.layers{pgzs(1)}.y_space;
        xFactor = m.layers{iz}.x_space / m.layers{pgzs(1)}.x_space;

        m.groups{g}.yCount = p.yCount * yFactor;
        m.groups{g}.xCount = p.xCount * xFactor;

        yArgs = num2cell([p.yCount, p.yStep, p.yMargin] * yFactor);
        xArgs = num2cell([p.xCount, p.xStep, p.xMargin] * xFactor);

    end

otherwise

    error('invalid rfType');

end

zs = numel(m.layers) + (1 : numel(pzs));

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = pzs{i};

    m.layers{z}.size{1} = m.layers{pzs{i}(1)}.size{1} * numel(m.groups{g}.yCount);
    m = cns_mapdim(m, z, 2, mode, pzs{i}(1), yArgs{:});
    m = cns_mapdim(m, z, 3, mode, pzs{i}(1), xArgs{:});

end

return;

%***********************************************************************************************************************

function m = method_initgroup(m, g)

% Called automatically by cns('init') via the package-level "init" method.

numPool = numel(m.groups{g}.yCount);

for z = m.groups{g}.zs

    pz = m.layers{z}.pzs(1);
    fCounts = m.layers{pz}.size{1};

    m.layers{z}.size{1} = fCounts .* [numPool 1];

end

m = cns_super(m, g);

return;
