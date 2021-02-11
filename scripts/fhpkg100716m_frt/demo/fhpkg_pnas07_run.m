% A demo script that instantiates the [Serre et al. 2007] model, learns feature
% dictionaries for each level, and computes feature vectors.  Differs from
% fhpkg_cvpr06_run only in that it learns multiple feature dictionaries; see
% that function for detailed comments.
%
% See also: fhpkg_cvpr06_run.

%***********************************************************************************************************************

q = struct;
q.bufSize   = [512 512];
q.baseSize  = [256 256];
q.numScales = 10;
p = fhpkg_pnas07_params(q);

lib = struct;

%***********************************************************************************************************************

for g = [p.s2b p.s2 p.s3]

    m = fhpkg_model(p, lib);
    d = fhpkg_empty(m, p.groups{g}.pg, p.groups{g}.fSizes);
    cns('init', m, 'gpu');
    for i = 1 : 1
        im = imread(fullfile(fileparts(mfilename('fullpath')), 'image_0010.jpg'));
        fhpkg_loadimage(m, im);
        cns('run');
        di = fhpkg_sample(m, p.groups{g}.pg, p.groups{g}.fSizes, 2000);
        d = fhpkg_combine(d, di);
    end
    cns('done');
    d = fhpkg_sort(d);
    d = fhpkg_sparsify(d);
    lib.groups{g} = d;

end

%***********************************************************************************************************************

m = fhpkg_model(p, lib);
cns('init', m, 'gpu');
for i = 1 : 1
    im = imread(fullfile(fileparts(mfilename('fullpath')), 'image_0002.jpg'));
    fhpkg_loadimage(m, im);
    tic;
    cns('run');
    c2b = cns('get', m.groups{p.c2b}.zs, 'val');
    c3  = cns('get', m.groups{p.c3 }.zs, 'val');
    toc;
end
cns('done');