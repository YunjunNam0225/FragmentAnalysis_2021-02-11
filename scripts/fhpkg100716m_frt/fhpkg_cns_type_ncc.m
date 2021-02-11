function varargout = fhpkg_cns_type_ncc(method, varargin)

% Defines the "ncc" cell type.  This is a subtype of "s1" which computes filter responses using a normalized dot
% product.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.super = 's1';

p.blockYSize = 16;
p.blockXSize = 16;

return;

%***********************************************************************************************************************

function d = method_fields

d = struct;

return;