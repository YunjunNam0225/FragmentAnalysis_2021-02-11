function d = fhpkg_sparsify(d)

% D = fhpkg_sparsify(D) converts a dictionary of "dense" features to "sparse"
% features as described in Section 2.3 of [Mutch & Lowe 2006].
%
% See also: fhpkg_sample.

%***********************************************************************************************************************

d = Sparsify (d);
d = SparseMap(d);

return;

%***********************************************************************************************************************

function d = Sparsify(d)

% TODO: add additional methods.

fValsOld = single(d.fVals);

d.fVals = repmat(single(cns_fltmin), size(fValsOld));

for nf = 1 : numel(d.fSizes)
    for j = 1 : d.fSizes(nf)
        for i = 1 : d.fSizes(nf)
            [v, f] = max(fValsOld(:, i, j, nf));
            d.fVals(f, i, j, nf) = v;
        end
    end
end

return;

%***********************************************************************************************************************

function d = SparseMap(d)

dVals  = single(d.fVals);
fSizes = d.fSizes;

unknown = single(cns_fltmin);

pCounts = zeros(1, numel(fSizes));
for nf = 1 : numel(fSizes)
    pCounts(nf) = sum(reshape(dVals(:, 1 : fSizes(nf), 1 : fSizes(nf), nf), 1, []) > unknown);
end
pCountMax = max(pCounts);

sVals = repmat(unknown         , [   pCountMax, numel(fSizes)]);
sMap  = repmat(single([0 1 1]'), [1, pCountMax, numel(fSizes)]);

for nf = 1 : numel(fSizes)
    p = 1;
    for f = 1 : size(dVals, 1)
        for j = 1 : fSizes(nf)
            for i = 1 : fSizes(nf)
                v = dVals(f, i, j, nf);
                if v > unknown
                    sVals(   p, nf) = v;
                    sMap (1, p, nf) = f;
                    sMap (2, p, nf) = i;
                    sMap (3, p, nf) = j;
                    p = p + 1;
                end
            end
        end
    end
end

d.fVals = sVals;
d.fMap  = sMap;

return;