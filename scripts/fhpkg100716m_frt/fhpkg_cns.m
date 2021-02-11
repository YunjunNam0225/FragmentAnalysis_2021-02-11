function varargout = fhpkg_cns(method, varargin)

% Defines some package-level methods.

%***********************************************************************************************************************

[varargout{1 : nargout}] = feval(['method_' method], varargin{:});

return;

%***********************************************************************************************************************

function p = method_props

p.methods = {'new', 'add', 'init'};

return;

%***********************************************************************************************************************

function d = method_fields

d = struct;

return;

%***********************************************************************************************************************

function m = method_new(m)

% Create an empty network model (with no groups or layers).  Called automatically by fhpkg_model.

m.groups = {};
m.layers = {};

m.quiet = true;

return;

%***********************************************************************************************************************

function [m, g] = method_add(m, p, d)

% Add a new group of layers, defined by parameters P and dictionary D, to a network model.  The new group can depend
% only on groups already defined (i.e. there is a feedforward constraint).  Called automatically by fhpkg_model.  In
% turn, calls the "addgroup" method for the particular cell type.
%
%    P.name - the name of the group.
%
%    P.type - the cell type of the group.
%
%    P.pg - number of the previous group, from which this group is to be computed.
%
% Additional parameters in P, and the format of D, depend on the cell type.

g = numel(m.groups) + 1;

m.groups{g}.name = p.name;

if ~isfield(p, 'parity')
    p.parity = 1;
end

n = numel(m.layers) + 1;
m = cns_type('addgroup', m, p.type, p, d, g);
zs = n : numel(m.layers);

for i = 1 : numel(zs)
    z = zs(i);
    if (m.layers{z}.size{2} == 0) || (m.layers{z}.size{3} == 0)
        error('g=%u ("%s"), scale=%u: y or x size is zero', g, p.name, i);
    end
end

m.groups{g}.zs = zs;

if numel(zs) == 1
    m.layers{zs}.name = p.name;
else
    for i = 1 : numel(zs)
        m.layers{zs(i)}.name = sprintf('%s_%u', p.name, i);
    end
end

return;

%***********************************************************************************************************************

function m = method_init(m)

% Perform final initialization for a network model just before it is instantiated on the GPU.  Called automatically by
% cns('init').  In turn, calls the "initgroup" method for the particular cell type.

% Establish the order in which layers will be computed.
m = cns_setstepnos(m, 'field', 'pzs');

% Turns off double-buffering.
m.independent = true;

for g = 1 : numel(m.groups)
    m = cns_type('initgroup', m, -g);
end

return;
