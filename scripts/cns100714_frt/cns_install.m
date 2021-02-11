function cns_install

% CNS_INSTALL
%    Click <a href="matlab: cns_help('cns_install')">here</a> for help.

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

base = fileparts(mfilename('fullpath'));

mex('-outdir', fullfile(base, 'private'), fullfile(base, 'source', 'cns_initsynapses.cpp'));
mex('-outdir', fullfile(base, 'private'), fullfile(base, 'source', 'cns_intin.cpp'));
mex('-outdir', fullfile(base, 'private'), fullfile(base, 'source', 'cns_intout.cpp'));
mex('-outdir', fullfile(base, 'private'), fullfile(base, 'source', 'cns_limits.cpp'));

if ~exist(fullfile(base, 'util', 'private'), 'dir'), mkdir(fullfile(base, 'util', 'private')); end

mex('-outdir', fullfile(base, 'util', 'private'), fullfile(base, 'source', 'cns_spikeutil.cpp'));

rehash path;

return;