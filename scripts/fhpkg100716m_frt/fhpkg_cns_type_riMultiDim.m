function varargout = fhpkg_cns_type_riMultiDim(method, varargin)

% Defines the "raw image" cell type.  An "ri" layer just holds an input image without computing anything.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.kernel  = false;
p.methods = {'addgroup'};

return;

%***********************************************************************************************************************

function d = method_fields

d = struct;

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add raw image group G, defined by parameters P, to a network model.  The group will comprise a single layer.  Called
% from fhpkg_model via the package-level "add" method.  D is ignored.  Additional parameters are:
%
%    P.size - a two element vector specifying the (y, x) size of the raw image layer.  This should be large enough
%    that most images will fit without resizing.

z = numel(m.layers) + 1;

m.layers{z}.type    = p.type;
m.layers{z}.groupNo = g;
m.layers{z}.pzs     = [];

m.layers{z}.size{1} = p.size(1);
m = cns_mapdim(m, z, 2, 'pixels', p.size(2));
m = cns_mapdim(m, z, 3, 'pixels', p.size(3));

return;