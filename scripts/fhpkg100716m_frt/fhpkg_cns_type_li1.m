function varargout = fhpkg_cns_type_li1(method, varargin)

% Defines the "li1" cell type.  These cells, together with "li2" cells, implement the lateral inhibition described in
% section 2.3 of [Mutch & Lowe 2006] (under heading "inhibit S1/C1 outputs").  "li1" cells look at all the cells in
% a single (y, x) position in the previous layer and decide what the cutoff value should be.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.methods = {'addgroup'};

p.blockYSize = 16;
p.blockXSize = 16;

return;

%***********************************************************************************************************************

function d = method_fields

d.inhibit = {'gp', 'private'}; % Inhibition level per [Mutch & Lowe 2006].

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "li1" group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level "add"
% method.  D is ignored.  Additional parameters are:
%
%    P.inhibit - inhibition level per [Mutch & Lowe 2006].

pgzs = m.groups{p.pg}.zs;

m.groups{g}.inhibit = p.inhibit;

zs = numel(m.layers) + (1 : numel(pgzs));

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = pgzs(i);

    m.layers{z}.size{1} = 1;
    m = cns_mapdim(m, z, 2, 'copy', pgzs(i));
    m = cns_mapdim(m, z, 3, 'copy', pgzs(i));

end

return;