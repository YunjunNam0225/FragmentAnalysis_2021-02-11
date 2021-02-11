function d = fhpkg_sample(m, g, sizes, numSamples, mask, rad)

% D = fhpkg_sample(M, G, SIZES, NUMSAMPLES) returns a dictionary of features
% sampled at random positions and scales from the current values of the feature
% hierarchy, i.e. from a single image.  Generally you will call this for many
% images and use fhpkg_combine to make a larger dictionary.
%
%    M - The network model which is currently instantiated on the GPU.
%
%    G - The number of the group we are sampling patches from.
%
%    SIZES - A vector of possible patch sizes.
%
%    NUMSAMPLES - The number of features to sample.
%
% See also: fhpkg_sparsify, fhpkg_combine, fhpkg_sort.

%***********************************************************************************************************************

if nargin < 5, mask = []; end

unknown = single(cns_fltmin);

zs = m.groups{g}.zs;

fCount = m.layers{zs(1)}.size{1};

vals    = cell (1, numel(zs));
yMargs  = zeros(1, numel(zs));
xMargs  = zeros(1, numel(zs));
yCounts = zeros(1, numel(zs));
xCounts = zeros(1, numel(zs));
yStarts = zeros(1, numel(zs));
xStarts = zeros(1, numel(zs));
ySpaces = zeros(1, numel(zs));
xSpaces = zeros(1, numel(zs));

for s = 1 : numel(zs)

    z = zs(s);

    vals{s} = cns('get', z, 'val');

    known = shiftdim(any(vals{s} > unknown, 1), 1);
    y = find(any(known, 2), 1, 'first');
    if ~isempty(y)
        yMargs (s) = y - 1;
        yCounts(s) = find(any(known, 2), 1, 'last') - y + 1;
    end
    x = find(any(known, 1), 1, 'first');
    if ~isempty(x)
        xMargs (s) = x - 1;
        xCounts(s) = find(any(known, 1), 1, 'last') - x + 1;
    end

    yStarts(s) = m.layers{z}.y_start;
    xStarts(s) = m.layers{z}.x_start;
    ySpaces(s) = m.layers{z}.y_space;
    xSpaces(s) = m.layers{z}.x_space;

end

% Count the number of valid sample positions for each feature size (n) and scale (s).

nCounts  = zeros(1, numel(sizes));
nsCounts = cell (1, numel(sizes));
for n = 1 : numel(sizes)
    nsCounts{n} = cumsum(max(yCounts - sizes(n) + 1, 0) .* max(xCounts - sizes(n) + 1, 0));
    nCounts(n) = nsCounts{n}(end);
end
nCounts = cumsum(nCounts);

numSamples = min(numSamples, nCounts(end));

d.fVals  = zeros(fCount, max(sizes), max(sizes), numSamples, 'single');
d.fSizes = zeros(1, numSamples);
d.fSPos  = zeros(1, numSamples);
d.fYPos  = zeros(1, numSamples);
d.fXPos  = zeros(1, numSamples);

for nf = 1 : numSamples

    while true

        n = find(randi(nCounts(end)) <= nCounts, 1);
        s = find(randi(nsCounts{n}(end)) <= nsCounts{n}, 1);
        % n = randi(numel(nCounts));
        % s = randi(numel(nsCounts{n}));
        % if yCounts(s) < sizes(n), continue; end
        % if xCounts(s) < sizes(n), continue; end

        y = randi(yCounts(s) - sizes(n) + 1) + yMargs(s);
        x = randi(xCounts(s) - sizes(n) + 1) + xMargs(s);
        yPos = yStarts(s) + (y - 1 + (sizes(n) - 1) / 2) * ySpaces(s);
        xPos = xStarts(s) + (x - 1 + (sizes(n) - 1) / 2) * xSpaces(s);

        if ~isempty(mask)
            % Make sure this position contains at least some of the object.
            [y1, y2] = cns_getrfdistat(m, 2, 'y', yPos, rad);
            [x1, x2] = cns_getrfdistat(m, 2, 'x', xPos, rad);
            if ~any(reshape(mask(y1 : y2, x1 : x2), 1, [])), continue; end
        end

        v = vals{s}(:, y : y + sizes(n) - 1, x : x + sizes(n) - 1);
        if ~all(v(:) > unknown), continue; end

        break;

    end

    d.fVals(:, 1 : sizes(n), 1 : sizes(n), nf) = v;

    d.fSizes(nf) = sizes(n);
    d.fSPos (nf) = s;
    d.fYPos (nf) = yPos;
    d.fXPos (nf) = xPos;

end

d = fhpkg_sort(d);

return;

%***********************************************************************************************************************

function i = randi(n)

i = max(1, ceil(rand * n));

return;