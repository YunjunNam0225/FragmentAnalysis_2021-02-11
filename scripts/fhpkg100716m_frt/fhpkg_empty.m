function d = fhpkg_empty(m, g, sizes)

% D = fhpkg_empty(M, G, SIZES) returns an empty feature dictionary.  This is
% useful for starting off a dictionary that you're going to be adding to with
% fhpkg_combine.
%
% Parameters are the same as in fhpkg_sample.
%
% See also: fhpkg_sample, fhpkg_combine.

%***********************************************************************************************************************

zs = m.groups{g}.zs;
fCount = m.layers{zs(1)}.size{1};

d.fVals  = zeros(fCount, max(sizes), max(sizes), 0, 'single');
d.fSizes = zeros(1, 0);
d.fSPos  = zeros(1, 0);
d.fYPos  = zeros(1, 0);
d.fXPos  = zeros(1, 0);

return;
