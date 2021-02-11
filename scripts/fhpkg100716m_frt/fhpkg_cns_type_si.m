function varargout = fhpkg_cns_type_si(method, varargin)

% Defines the "scaled image" cell type.  An "si" group computes an image pyramid from a raw image by resizing.
%
% Note that if the raw image does not have the same aspect ratio as the scaled image, the resulting scaled image will
% be centered and padded.  The value used for padding is cns_fltmin.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.methods = {'addgroup'};

p.blockYSize = 16;
p.blockXSize = 16;

return;

%***********************************************************************************************************************

function d = method_fields

% Note: fhpkg_loadimage automatically sets both these fields for you when you load a new input image.

d.py_count = {'gp', 'private', 'int', 'dflt', cns_intmax}; % Actual height of the raw image in pixels.
d.px_count = {'gp', 'private', 'int', 'dflt', cns_intmax}; % Actual width of the raw image in pixels.

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add scaled image group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level
% "add" method.  D is ignored.  Additional parameters are:
%
%    P.baseSize - a two element vector specifying the (y, x) size of the finest scale (i.e. the base of the image
%    pyramid) in pixels.
%
%    P.numScales - the desired number of scales (i.e., layers) in the image pyramid.
%
%    P.scaleFactor - the scale factor between scales.  A number greater than 1; a common value is (2 ^ 1/4).

pgzs = m.groups{p.pg}.zs;

if ~strcmp(m.layers{pgzs(1)}.type, 'ri')
    error('g=%u: previous group must be a raw image', g);
end

zs = numel(m.layers) + (1 : p.numScales);

for i = 1 : numel(zs)

    z = zs(i);

    m.layers{z}.type    = p.type;
    m.layers{z}.groupNo = g;
    m.layers{z}.pzs     = pgzs;

    m.layers{z}.size{1} = 1;
    m = cns_mapdim(m, z, 2, 'scaledpixels', p.baseSize(1), p.scaleFactor ^ (i - 1));
    m = cns_mapdim(m, z, 3, 'scaledpixels', p.baseSize(2), p.scaleFactor ^ (i - 1));

end

return;