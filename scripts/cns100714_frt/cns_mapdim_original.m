function m = cns_mapdim(m, z, dimID, method, varargin)

% CNS_MAPDIM
%    Click <a href="matlab: cns_help('cns_mapdim')">here</a> for help.

%***********************************************************************************************************************

% Copyright (C) 2009 by Jim Mutch (www.jimmutch.com).
%
% This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
% License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
% warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with this program.  If not, see
% <http://www.gnu.org/licenses/>.

%***********************************************************************************************************************
fprintf('%s\n', method);
[d2, name] = cns_finddim(m, z, dimID, true);

switch method
case 'copy'            , m = MapCopy           (m, z, name, d2, varargin{:});
case 'pixels'          , m = MapPixels         (m, z, name, d2, varargin{:});
case 'scaledpixels'    , m = MapScaledPixels   (m, z, name, d2, varargin{:});
case 'scaledpixels-old', m = MapScaledPixelsOld(m, z, name, d2, varargin{:});
case 'int'             , m = MapInt            (m, z, name, d2, varargin{:});
case 'int-old'         , m = MapIntOld         (m, z, name, d2, varargin{:});
case 'int-td'          , m = MapIntTD          (m, z, name, d2, varargin{:});
case 'win'             , m = MapWin            (m, z, name, d2, varargin{:});
case 'temp1'           , m = MapTemp1          (m, z, name, d2, varargin{:});
case 'temp2'           , m = MapTemp2          (m, z, name, d2, varargin{:});
otherwise              , error('invalid method');
end

return;

%***********************************************************************************************************************

function m = MapCopy(m, z, name, d2, pz)

d1 = cns_finddim(m, pz, name, true);

m.layers{z}.size{d2}          = m.layers{pz}.size{d1};
m.layers{z}.([name '_start']) = m.layers{pz}.([name '_start']);
m.layers{z}.([name '_space']) = m.layers{pz}.([name '_space']);

return;

%***********************************************************************************************************************

function m = MapPixels(m, z, name, d2, imSize)

if (imSize < 1) || (mod(imSize, 1) ~= 0)
    error('imSize must be a positive integer');
end

m.layers{z}.size{d2}          = imSize;
m.layers{z}.([name '_start']) = 0.5 / imSize;
m.layers{z}.([name '_space']) = 1 / imSize;

return;

%***********************************************************************************************************************

function m = MapScaledPixels(m, z, name, d2, baseSize, factor)

if (baseSize < 1) || (mod(baseSize, 1) ~= 0)
    error('baseSize must be a positive integer');
end
if factor < 1
    error('factor must be at least 1');
end

nSpace = factor / baseSize;

if mod(baseSize, 2) == 1
    %nSize = 2 * floor((1 - nSpace) / (2 * nSpace)) + 1;
    nSize = 2 * floor((baseSize - factor) / (2 * factor)) + 1;
else
    % nSize = 2 * floor(1 / (2 * nSpace));
    % was replaced to below code by Yunjun Nam.
    % PRECISION problem.
    % when baseSize=422, nSize become 420.
    % 1 / (2 * factor / baseSize)
    %  = baseSize / (2*factor)
      nSize = 2*floor( baseSize/(2*factor) );
end

if nSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nStart = 0.5 - nSpace * (nSize - 1) / 2;
end

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;

%***********************************************************************************************************************

function m = MapScaledPixelsOld(m, z, name, d2, baseSize, factor)

% This is the way FHLib laid out pixels.

if (baseSize < 1) || (mod(baseSize, 1) ~= 0)
    error('baseSize must be a positive integer');
end
if factor < 1
    error('factor must be at least 1');
end

nSize = round(baseSize / factor);

if nSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nStart = 0.5 / nSize;
end

nSpace = factor / baseSize;

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;

%***********************************************************************************************************************

function m = MapInt(m, z, name, d2, pz, rfSize, rfStep, parity)

% rfSize = unit width in previous layer units.
% rfStep = unit step size in previous layer units.
% parity = 0 if you prefer an even-sized output, 1 if odd, [] if you don't care.

if nargin < 8, parity = []; end

d1 = cns_finddim(m, pz, name, true);

if rfSize >= cns_intmax

    m.layers{z}.size{d2}          = 1;
    m.layers{z}.([name '_start']) = 0.5;
    m.layers{z}.([name '_space']) = 1;

    return;

end

if (rfSize < 1) || (mod(rfSize, 1) ~= 0)
    error('rfSize must be a positive integer');
end
if (rfStep < 1) || (mod(rfStep, 1) ~= 0)
    error('rfStep must be a positive integer');
end
if ~isempty(parity) && ~any(parity == [0 1])
    error('parity must be 0, 1, or empty');
end

pSize  = m.layers{pz}.size{d1};
pStart = m.layers{pz}.([name '_start']);
pSpace = m.layers{pz}.([name '_space']);

nSpace = pSpace * rfStep;

nSize1 = 2 * floor((pSize - rfSize         ) / (2 * rfStep)) + 1;
nSize0 = 2 * floor((pSize - rfSize - rfStep) / (2 * rfStep)) + 2;

if mod(pSize, 2) == mod(rfSize, 2)

    if mod(rfStep, 2) == 0

        % We can place a unit in the center, or not.

        if isequal(parity, 1) || (isempty(parity) && (nSize1 >= nSize0))
            nSize = nSize1;
        else
            nSize = nSize0;
        end

    else

        % We must place a unit in the center.  The result will have an odd number of units.

        nSize = nSize1;

    end

else

    % We cannot place a unit in the center, so the result will have an even number of units, and we must place a unit
    % on either side of the center, at the same distance from the center.  This is only possible if rfStep is odd.
    % This really requires a diagram to see.  There are two cases to consider: pSize odd, rfSize even and vice-versa.

    if mod(rfStep, 2) == 0
        error('when the result layer has an even number of units, rfStep must be odd');
    end

    nSize = nSize0;

end

if nSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nStart = pStart + (pSpace * (pSize - 1) - nSpace * (nSize - 1)) / 2;
end

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;

%***********************************************************************************************************************

function m = MapIntOld(m, z, name, d2, pz, rfSize, rfStep)

% This is the way FHLib laid out cells, tiling from the top left corner.

% rfSize = unit width in previous layer units.
% rfStep = unit step size in previous layer units.

d1 = cns_finddim(m, pz, name, true);

if rfSize >= cns_intmax

    m.layers{z}.size{d2}          = 1;
    m.layers{z}.([name '_start']) = 0.5;
    m.layers{z}.([name '_space']) = 1;

    return;

end

if (rfSize < 1) || (mod(rfSize, 1) ~= 0)
    error('rfSize must be a positive integer');
end
if (rfStep < 1) || (mod(rfStep, 1) ~= 0)
    error('rfStep must be a positive integer');
end

pSize  = m.layers{pz}.size{d1};
pStart = m.layers{pz}.([name '_start']);
pSpace = m.layers{pz}.([name '_space']);

nSize = floor((pSize - rfSize) / rfStep) + 1;

if nSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nStart = pStart + pSpace * (rfSize - 1) / 2;
end

nSpace = pSpace * rfStep;

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;

%***********************************************************************************************************************

function m = MapIntTD(m, z, name, d2, pz, rfSize, rfStep)

d1 = cns_finddim(m, pz, name, true);

if (rfSize < 1) || (mod(rfSize, 1) ~= 0)
    error('rfSize must be a positive integer');
end
if (rfStep < 1) || (mod(rfStep, 1) ~= 0)
    error('rfStep must be a positive integer');
end

pSize  = m.layers{pz}.size{d1};
pStart = m.layers{pz}.([name '_start']);
pSpace = m.layers{pz}.([name '_space']);

nSpace = pSpace / rfStep;

if pSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nSize  = rfSize + (pSize - 1) * rfStep;
    nStart = pStart - 0.5 * (rfSize - 1) * nSpace;
end

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;

%***********************************************************************************************************************

function m = MapWin(m, z, name, d2, pz, rfSize, rfStep, rfMargin)

% rfSize   = window width in previous layer units (can be fractional).
% rfStep   = window step size in previous layer units (can be fractional).
% rfMargin = size of margin in previous layer units (can be fractional and/or negative).

if rfSize >= cns_intmax

    m.layers{z}.size{d2}          = 1;
    m.layers{z}.([name '_start']) = 0.5;
    m.layers{z}.([name '_space']) = 1;

    return;

end

if rfSize <= 0
    error('rfSize must be positive');
end
if rfStep <= 0
    error('rfStep must be positive');
end

pSpace = m.layers{pz}.([name '_space']);

rfSize   = rfSize   * pSpace;
rfStep   = rfStep   * pSpace;
rfMargin = rfMargin * pSpace;

nSize = 1 + 2 * floor((1 - rfSize - 2 * rfMargin) / (2 * rfStep));

if nSize < 1
    nSize  = 0;
    nStart = 0.5;
else
    nStart = 0.5 - rfStep * (nSize - 1) / 2;
end

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = rfStep;

return;

%***********************************************************************************************************************

function m = MapTemp1(m, z, name, d2, numFrames)

if (numFrames < 1) || (mod(numFrames, 1) ~= 0)
    error('numFrames must be a positive integer');
end

m.layers{z}.size{d2}          = numFrames;
m.layers{z}.([name '_start']) = -numFrames;
m.layers{z}.([name '_space']) = 1;

return;

%***********************************************************************************************************************

function m = MapTemp2(m, z, name, d2, pz, rfSize, rfStep, nSize)

% rfSize = unit width in previous layer units.
% rfStep = unit step size in previous layer units.
% nSize  = number of output units.

d1 = cns_finddim(m, pz, name, true);

if (rfSize < 1) || (mod(rfSize, 1) ~= 0)
    error('rfSize must be a positive integer');
end
if (rfStep < 1) || (mod(rfStep, 1) ~= 0)
    error('rfStep must be a positive integer');
end
if (nSize < 1) || (mod(nSize, 1) ~= 0)
    error('nSize must be a positive integer');
end

pSize  = m.layers{pz}.size{d1};
pStart = m.layers{pz}.([name '_start']);
pSpace = m.layers{pz}.([name '_space']);

if pSize < rfSize
    error('previous layer size is smaller than rfSize');
end

nSpace = pSpace * rfStep;

pNext = pStart + pSpace * pSize;
nNext = pNext + pSpace * (rfSize - 1) / 2;
nStart = nNext - nSpace * nSize;

m.layers{z}.size{d2}          = nSize;
m.layers{z}.([name '_start']) = nStart;
m.layers{z}.([name '_space']) = nSpace;

return;