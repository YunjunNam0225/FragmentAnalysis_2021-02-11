function varargout = fhpkg_cns_type_gmax(method, varargin)

% Defines the "gmax" cell type.  This is a subtype of "g" which pools using a maximum function.

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