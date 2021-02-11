function varargout = fhpkg_cns_type_li2(method, varargin)

% Defines the "li2" cell type.  These cells, together with "li1" cells, implement the lateral inhibition described in
% section 2.3 of [Mutch & Lowe 2006] (under heading "inhibit S1/C1 outputs").  An "li2" group applies the cutoffs
% computed by an "li1" group to a previous group, generating a copy of that group with weak responses set to zero.

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

d = struct;

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "li2" group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level "add"
% method.  D is ignored.  Additional parameters are:
%
%    P.ig - group number of the associated "li1" group.

pgzs = m.groups{p.pg}.zs;
igzs = m.groups{p.ig}.zs;

if ~strcmp(m.layers{igzs(1)}.type, 'li1')
    error('g=%u: "ig" must identify a group of type "li1"', g);
end

zs = numel(m.layers) + (1 : numel(pgzs));

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = [pgzs(i), igzs(i)];

    m.layers{z}.size{1} = m.layers{pgzs(i)}.size{1};
    m = cns_mapdim(m, z, 2, 'copy', pgzs(i));
    m = cns_mapdim(m, z, 3, 'copy', pgzs(i));

end

return;