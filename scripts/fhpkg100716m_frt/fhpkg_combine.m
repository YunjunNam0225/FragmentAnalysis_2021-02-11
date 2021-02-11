function d = fhpkg_combine(d1, d2)

% D = fhpkg_combine(D1, D2) combines the features in two dictionaries to make
% a larger dictionary.
%
% See also: fhpkg_sample, fhpkg_empty, fhpkg_sort.

%***********************************************************************************************************************

d.fSizes = [d1.fSizes, d2.fSizes];

% TODO: this needs to be able to handle features of different sizes
if isfield(d1, 'fMap')
    d.fVals = [d1.fVals, d2.fVals];
    d.fMap  = cat(3, d1.fMap, d2.fMap);
else
    d.fVals = cat(4, d1.fVals, d2.fVals);
end

if isfield(d1, 'fSPos')
    d.fSPos = [d1.fSPos, d2.fSPos];
    d.fYPos = [d1.fYPos, d2.fYPos];
    d.fXPos = [d1.fXPos, d2.fXPos];
end

return;