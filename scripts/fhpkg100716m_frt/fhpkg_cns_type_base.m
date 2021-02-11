function varargout = fhpkg_cns_type_base(method, varargin)

% Contains definitions shared by all cell types.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.abstract = true;
p.methods  = {'initgroup'};

% Regardless of cell type, all layers are three dimensional.  A given cell within a layer is identified by its feature
% number and its y and x indices.  The y and x dimensions of all layers are mapped to absolute retinal positions so that
% correspondences may be established between cells in different layers.

p.dims   = {[1 2] 1 2};
p.dparts = {[2 2] 1 1};
p.dnames = {'f' 'y' 'x'};
p.dmap   = [false true true];

return;

%***********************************************************************************************************************

function d = method_fields

% Previous layer number(s) used to compute this layer.  Set by a cell type's "addgroup" method.
d.pzs = {'lz', 'mv', 'type', 'base'};

% Holds the output value of a cell (either fixed or computed).  Computed by the cell's kernel.
d.val = {'cv', 'cache', 'dflt', 0};

return;

%***********************************************************************************************************************

function m = method_initgroup(m, g)

% Called automatically for each group by the package-level "init" method.  Specific cell types may override it.

for z = m.groups{g}.zs
    m.layers{z}.size{1} = cns_splitdim(m.layers{z}.size{1});
end

return;