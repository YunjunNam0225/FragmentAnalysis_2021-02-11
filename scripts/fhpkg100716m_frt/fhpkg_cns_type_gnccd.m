function varargout = fhpkg_cns_type_gnccd(method, varargin)

% Defines the "gnccd" cell type.  This is a subtype of "sd" which computes responses using NCC.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.super   = 'sd';
p.methods = {'addgroup'};

p.blockYSize = 16;
p.blockXSize = 8;

return;

%***********************************************************************************************************************

function d = method_fields

d.sigma = {'gp', 'private'}; % Standard deviation of the gaussian.

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "grbfd" group G, defined by parameters P and dictionary D, to a network model.  Called from fhpkg_model via the
% package-level "add" method.  Additional parameters are:
%
%    P.sigma - standard deviation of the gaussian.

m = cns_super(m, p, d, g);

m.groups{g}.sigma = p.sigma;

return;