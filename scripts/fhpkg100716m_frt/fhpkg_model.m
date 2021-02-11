function m = fhpkg_model(p, lib)

% M = fhpkg_model(P, LIB) creates a full CNS network model structure that can
% be instantiated on a GPU using cns('init').
%
%    P.groups{g} - A structure containing parameters specific to that group of
%    layers.
%
%    LIB.groups{g} - The dictionary for that group of layers, if any.
%
% This function calls the package-level method "add", which in turn calls the
% appropriate cell type's "addgroup" method.  See these methods for details on
% the parameters needed.
%
% See also: fhpkg_cvpr06_base_params.

%***********************************************************************************************************************

if (nargin < 2) || ~isfield(lib, 'groups')
    lib.groups = {};
end

m = cns_package('new', 'fhpkg');

for g = 1 : numel(p.groups)

    if (numel(lib.groups) < g) || isempty(lib.groups{g})
        d = struct;
    else
        d = lib.groups{g};
    end

    m = cns_package('add', m, p.groups{g}, d);

end

return;
