function varargout = fhpkg_cns_type_g(method, varargin)

% Defines the "g" cell type.  This is a subtype of "c" in which the pooling range of a cell is restricted to a local
% region near the position and scale from which its particular feature was originally sampled.  This is described in
% section 2.3 of [Mutch & Lowe 2006] under the heading "limit position/scale invariance of S2 features".
%
% This is an abstract type; the particular pooling function is undefined (and left to subtypes).

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.super    = 'c';
p.abstract = true;
p.methods  = {'addgroup'};

return;

%***********************************************************************************************************************

function d = method_fields

d.sTol  = {'gp', 'private', 'int'}; % Scale tolerance per [Mutch & Lowe 2006].
d.yxTol = {'gp', 'private'};        % Position tolerance per [Mutch & Lowe 2006].

% These all come from the feature dictionary of the previous group.  They are initialized in the "addgroup" method
% below.

d.fSPos = {'ga', 'private', 'dims', {[1 2]}, 'dparts', {[1 1]}, 'dnames', {'f'}, 'ind'}; % Scale sample positions.
d.fYPos = {'ga', 'private', 'dims', {[1 2]}, 'dparts', {[1 1]}, 'dnames', {'f'}};        % Y sample positions.
d.fXPos = {'ga', 'private', 'dims', {[1 2]}, 'dparts', {[1 1]}, 'dnames', {'f'}};        % X sample positions.

return;

%***********************************************************************************************************************

function m = method_addgroup(m, p, d, g)

% Add "g" group G, defined by parameters P, to a network model.  Called from fhpkg_model via the package-level "add"
% method.  D is ignored.  Additional parameters are:
%
%    P.sTol - scale tolerance per [Mutch & Lowe 2006].
%
%    P.yxTol - position tolerance per [Mutch & Lowe 2006].
%
% For a one-shot recognition model (i.e. no localization), set the "c" parameters for global pooling.  If doing
% localization, one would typically set P.rfType = 'win'.

m = cns_super(m, p, d, g);

if ~isscalar(m.groups{g}.yCount)
    error('multiple pooling sizes not allowed with "g" filters');
end

pd   = m.groups{p.pg};
pgzs = m.groups{p.pg}.zs;

if numel(pd.fSPos) ~= m.layers{pgzs(1)}.size{1}
    error('fSPos must have one element per feature');
end
if (numel(pd.fYPos) ~= numel(pd.fSPos)) || (numel(pd.fXPos) ~= numel(pd.fSPos))
    error('fYPos and fXPos must have the same number of elements as fSPos');
end

m.groups{g}.fSPos = pd.fSPos;
m.groups{g}.fYPos = pd.fYPos;
m.groups{g}.fXPos = pd.fXPos;
m.groups{g}.sTol  = p.sTol;
m.groups{g}.yxTol = p.yxTol;

return;