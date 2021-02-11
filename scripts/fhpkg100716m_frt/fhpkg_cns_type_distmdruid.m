function varargout = fhpkg_cns_type_distmdruid(method, varargin)

% Defines the "gsedistdm" cell type.  This is a subtype of "sdm" which computes responses using squared Euclidean distance with mask.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.super   = 'sdmdruid';
p.methods = {'addgroup'};

p.blockYSize = 32;
p.blockXSize = 16;

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