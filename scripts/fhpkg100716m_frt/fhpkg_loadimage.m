function fhpkg_loadimage(m, im)

% fhpkg_loadimage(M, IM) loads an image into the "raw image" layer of an
% instantiated network model.
%
%    M - The network model which is currently instantiated on the GPU.
%
%    IM - Either the path of an image or an array containing an image.

%***********************************************************************************************************************

% We make the assumption that layer 1 is the raw image and layer 2 is the first scaled image.

bufSize = [m.layers{1}.size{2 : 3}];
nSpace  = [m.layers{2}.y_space, m.layers{2}.x_space];

[val, p] = cns_prepimage(im, bufSize, nSpace);

cns('set', {1, 'val', shiftdim(val, -1)}, ...
    {1, 'y_start', p.start(1)}, {1, 'y_space', p.space(1)}, {2, 'py_count', p.size(1)}, ...
    {1, 'x_start', p.start(2)}, {1, 'x_space', p.space(2)}, {2, 'px_count', p.size(2)});

return;