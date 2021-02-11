function d = fhpkg_sort(d)

% D = fhpkg_sort(D) sorts a dictionary's features by size.  This increases the
% speed of models that use the dictionary.
%
% See also: fhpkg_combine.

%***********************************************************************************************************************

[ans, inds] = sort(d.fSizes);

d.fSizes = d.fSizes(inds);

if isfield(d, 'fMap')
    d.fVals = d.fVals(:, inds);
    d.fMap  = d.fMap (:, :, inds);
else
    d.fVals = d.fVals(:, :, :, inds);
end

if isfield(d, 'fSPos')
    d.fSPos = d.fSPos(inds);
    d.fYPos = d.fYPos(inds);
    d.fXPos = d.fXPos(inds);
end

return;