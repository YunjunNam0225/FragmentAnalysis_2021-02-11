function varargout = cns_trans(mode, varargin)

% Internal CNS function.

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

switch mode
case 'parse'   , [varargout{1 : nargout}] = Parse   (varargin{:});
case 'undef'   , [varargout{1 : nargout}] = Undef   (varargin{:});
case 'create'  , [varargout{1 : nargout}] = Create  (varargin{:});
case 'scalar'  , [varargout{1 : nargout}] = Scalar  (varargin{:});
case 'siz2p'   , [varargout{1 : nargout}] = Siz2P   (varargin{:});
case 'recreate', [varargout{1 : nargout}] = Recreate(varargin{:});
case 'add'     , [varargout{1 : nargout}] = Add     (varargin{:});
case 'sizeis'  , [varargout{1 : nargout}] = SizeIs  (varargin{:});
case 'disp'    , [varargout{1 : nargout}] = Disp    (varargin{:});
case 'pack'    , [varargout{1 : nargout}] = Pack    (varargin{:});
case 'unpack'  , [varargout{1 : nargout}] = Unpack  (varargin{:});
case 'e2yx'    , [varargout{1 : nargout}] = E2YX    (varargin{:});
case 'yx2e'    , [varargout{1 : nargout}] = YX2E    (varargin{:});
otherwise      , error('invalid mode');
end

return;

%***********************************************************************************************************************

function d = Parse(d, u)

if ~isfield(u, 'dims') && isfield(u, 'dparts')
    error('dparts cannot be specified without dims');
end

if isfield(u, 'dims')
    dims = u.dims(:)';
    if ~iscell(dims) || isempty(dims) || ~all(cellfun(@isnumeric, dims))
        error('dims must be a cell array of numeric vectors');
    end
    for i = 1 : numel(dims)
        if isempty(dims{i}) || (size(dims{i}, 1) ~= 1)
            error('dims must contain scalars or nonempty row vectors');
        end
    end
    if ~any([dims{:}] == 1)
        error('dims must contain the number 1 at least once');
    end
    if any(([dims{:}] ~= 1) & ([dims{:}] ~= 2))
        error('dims may only contain the numbers 1 and 2');
    end
else
    dims = {1 2};
end

if isfield(u, 'dparts')
    dparts = u.dparts(:)';
    if ~iscell(dparts) || ~all(cellfun(@isnumeric, dparts))
        error('dparts must be a cell array of numeric vectors');
    end
    if numel(dparts) ~= numel(dims)
        error('dparts must have the same number of elements (%u) as dims', numel(dims));
    end
    for i = 1 : numel(dims)
        if ~isequal(size(dparts{i}), size(dims{i}))
            error('each element of dparts must be the same size as the corresponding element of dims');
        end
    end
    tdims  = [dims{:}  ];
    tparts = [dparts{:}];
    for i = 1 : max(tdims)
        if ~isequal(sort(tparts(tdims == i)), 1 : sum(tdims == i))
            error('parts for dimension %u must uniquely cover the range 1 to %u', i, sum(tdims == i));
        end
    end
else
    dparts = {};
    for i = 1 : numel(dims)
        for j = 1 : numel(dims{i})
            dparts{i}(1, j) = sum([dims{1 : i - 1}, dims{i}(1 : j - 1)] == dims{i}(j)) + 1;
        end
    end
end

if isfield(u, 'dnames')
    dnames = u.dnames(:)';
    if ~iscellstr(dnames)
        error('dnames must be a cell array of strings');
    end
    if numel(dnames) ~= numel(dims)
        error('dnames must have the same number of elements (%u) as dims', numel(dims));
    end
    if any(isstrprop([dnames{:}], 'digit'))
        error('dnames cannot contain digits');
    end
    tnames = dnames(~strcmp(dnames, ''));
    if numel(unique(tnames)) ~= numel(tnames)
        error('dnames must be unique');
    end
elseif isequal(dims, {1 2})
    dnames = {'y' 'x'};
else
    dnames = repmat({''}, 1, numel(dims));
end

if isfield(u, 'dmap')
    dmap = u.dmap(:)';
    if ~islogical(dmap)
        error('dmap must be a logical vector');
    end
    if numel(dmap) ~= numel(dims)
        error('dmap must have the same number of elements (%u) as dims', numel(dims));
    end
    if any(dmap & cellfun(@isempty, dnames))
        error('dmap cannot be true if dnames is null');
    end
    if any(dmap & ~cellfun(@isscalar, dims))
        error('mapped dimensions cannot have multiple parts');
    end
else
    dmap = false(1, numel(dims));
end

d.dims   = dims;
d.dparts = dparts;
d.dnames = dnames;
d.dmap   = dmap;

return;

%***********************************************************************************************************************

function d = Undef(d)

d.dims   = {};
d.dparts = {};
d.dnames = {};
d.dmap   = [];

return;

%***********************************************************************************************************************

function t = Create(d, sizes, align)

if (nargin < 3) || isempty(align), align = 1; end

sizes = sizes(:)';
if ~iscell(sizes) || ~all(cellfun(@isnumeric, sizes))
    error('size must be a cell array of numeric vectors');
end
if numel(sizes) ~= numel(d.dims)
    error('size must have %u elements', numel(d.dims));
end
for i = 1 : numel(d.dims)
    if isequal(size(sizes{i}), size(d.dims{i}))
    elseif isscalar(sizes{i})
        sizes{i} = cns_splitdim(sizes{i}, numel(d.dims{i}));
    else
        error('size{%u} must be 1x%u or scalar', i, numel(d.dims{i}));
    end
end

counts = [sizes{:}];
if any(counts < 0) || any(mod(counts, 1) ~= 0)
    error('invalid size');
end

[rows, order] = sortrows([[d.dims{:}]', [d.dparts{:}]']);
order = order';

t.siz1 = cellfun(@prod, sizes);
t.siz2 = counts;

t.siz1s = t.siz1; if numel(t.siz1s) == 1, t.siz1s(2) = 1; end
t.siz2s = t.siz2; if numel(t.siz2s) == 1, t.siz2s(2) = 1; end
t.perm  = order ; if numel(t.perm ) == 1, t.perm (2) = 2; end

t.iperm = nan(1, numel(t.perm));
t.iperm(t.perm) = 1 : numel(t.perm);

t.ndim1 = sum(rows(:, 1) == 1);

t.siz3 = t.siz2s(t.perm);

t.siz3a = t.siz3;
if align ~= 1

    % We always either keep the first part of dimension 1 aligned, or don't do any alignment.  In the latter case we
    % still have to pad the final result (see siz4b below).

    yCount0 = t.siz3(1);
    ySize0  = ceil(yCount0 / align) * align;

    % Align dimension 1 if most positions will still be valid.

    % NOTE: tests so far seem to indicate that it's always better to pack the threads.
    % if yCount0 / ySize0 >= 0.75, t.siz3a(1) = ySize0; end

end

t.siz4a = [prod(t.siz3a(1 : t.ndim1)), prod(t.siz3a(t.ndim1 + 1 : end))];

t.siz4b = t.siz4a;
if align ~= 1
    t.siz4b(1) = ceil(t.siz4a(1) / align) * align;
end

return;

%***********************************************************************************************************************

function t = Scalar(align)

if (nargin < 1) || isempty(align), align = 1; end

t.siz1  = [1 1];
t.siz2  = [1 1];
t.siz1s = [1 1];
t.siz2s = [1 1];
t.perm  = [1 2];
t.iperm = [1 2];
t.ndim1 = 1;
t.siz3  = [1 1];
t.siz3a = [1 1]; % See comments in 'create' for why we don't align here.
t.siz4a = [1 1];
t.siz4b = [align 1];

return;

%***********************************************************************************************************************

function s = Siz2P(t)

s = [t.siz2, t.siz3a(1), t.siz4b(1)];

return;

%***********************************************************************************************************************

function t = Recreate(d, siz2, align)

if (nargin < 3) || isempty(align), align = 1; end

sizes = {};
pos = 1;

for i = 1 : numel(d.dims)
    for j = 1 : numel(d.dims{i})
        sizes{i}(j) = siz2(pos);
        pos = pos + 1;
    end
end

t = Create(d, sizes, align);

return;

%***********************************************************************************************************************

function t = Add(t, count)

t.siz1  = [count, t.siz1];
t.siz2  = [count, t.siz2];
t.siz1s = t.siz1;
t.siz2s = t.siz2;
t.perm  = [t.perm + 1, 1];
t.iperm = [numel(t.iperm) + 1, t.iperm];
t.siz3  = [t.siz3, count];
t.siz3a = [t.siz3a, count];
t.siz4a = [t.siz4a, count];
t.siz4b = [t.siz4b, count];

return;

%***********************************************************************************************************************

function r = SizeIs(t, a)

d1 = numel(t.siz1);
d2 = numel(size(a));

if (d1 == 1) && (d2 == 2)

    if all(size(a) ~= 1) && any(size(a) > 0)
        r = false;
    else
        r = (numel(a) == t.siz1);
    end
    
else
    
    r = true;
    for d = 1 : max(d1, d2)
        if d <= d1, s1 = t.siz1(d) ; else s1 = 1; end
        if d <= d2, s2 = size(a, d); else s2 = 1; end
        if s1 ~= s2
            r = false;
            break;
        end
    end
    
end

return;

%***********************************************************************************************************************

function s = Disp(t, mv)

if nargin < 2, mv = false; end

if mv
    s = 'N';
else
    s = sprintf('%u', t.siz1(1));
end

if numel(t.siz1) > 1
    s = [s, sprintf('x%u', t.siz1(2 : end))];
end

return;

%***********************************************************************************************************************

function a = Pack(t, a, final)

if nargin < 3, final = false; end

a = permute(reshape(a, t.siz2s), t.perm);

a(t.siz3(1) + 1 : t.siz3a(1), :) = 0;

a = reshape(a, t.siz4a);

if final
    a(t.siz4a(1) + 1 : t.siz4b(1), :) = 0;
    a = reshape(a, t.siz4b);
end

return;

%***********************************************************************************************************************

function a = Unpack(t, a)

a = reshape(a(1 : t.siz4a(1), :), t.siz3a);

a = reshape(permute(reshape(a(1 : t.siz3(1), :), t.siz3), t.iperm), t.siz1s);

return;

%***********************************************************************************************************************

function [y, x] = E2YX(t, e)

[c2{1 : numel(t.siz2s)}] = ind2sub(t.siz2s, e);

[y, x] = ind2sub(t.siz4a, sub2ind(t.siz3a, c2{t.perm}));

return;

%***********************************************************************************************************************

function e = YX2E(t, y, x)

[c3{1 : numel(t.siz3a)}] = ind2sub(t.siz3a, sub2ind(t.siz4a, y, x));

e = sub2ind(t.siz2s, c3{t.iperm});

return;