function varargout = fhpkg_cns_type_gavg(method, varargin)

% Defines the "gavg" cell type.  This is a subtype of "g" which pools using an average function.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.super = 'g';

p.blockYSize = 16;
p.blockXSize = 16;

return;

%***********************************************************************************************************************

function d = method_fields

d = struct;

return;