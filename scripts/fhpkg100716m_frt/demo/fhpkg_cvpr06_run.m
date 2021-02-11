% A demo script that instantiates one of the [Mutch & Lowe 2006] models, learns
% a feature dictionary, and computes feature vectors.

%***********************************************************************************************************************
% Define the model.
%***********************************************************************************************************************

% Choose model parameters.

q = struct;
q.bufSize   = [400 600];
q.baseSize  = [140 140];
q.numScales = 9;
p = fhpkg_cvpr06_base_params(q);
% p = fhpkg_cvpr06_full_params(q);

% A "library" contains the feature dictionary for each group, if any.  In [Mutch & Lowe 2006] only S2 will have a
% feature dictionary, but it does not yet exist.

lib = struct;

%***********************************************************************************************************************
% Learn a feature dictionary for layer S2.
%***********************************************************************************************************************

% Build the full CNS network model.  Note that layers above C1 will have zero cells because the S2 dictionary is empty.
m = fhpkg_model(p, lib);

% Create an empty dictionary for S2.
d = fhpkg_empty(m, p.c1, p.groups{p.s2}.fSizes);

% Initialize the model on the GPU.
cns('init', m, 'gpu');
% cns('init', m, 'cpu'); % use this instead if you don't have a GPU

for i = 1 : 1

    % Note: in a real situation we would loop over many training images.

    % Read training image and load it into the GPU.
    im = imread(fullfile(fileparts(mfilename('fullpath')), 'image_0010.jpg'));
    fhpkg_loadimage(m, im);

    % Compute the feature hierarchy for the image.
    cns('run');

    % Sample some S2 features (patches of C1 units).  Note we're sampling 2000 from a single image; in a real
    % situation we'd sample only a few from each training image.
    di = fhpkg_sample(m, p.c1, p.groups{p.s2}.fSizes, 2000);

    % Append the features from this image to the dictionary.
    d = fhpkg_combine(d, di);

end

% Release GPU resources.
cns('done');

% Sort features by size.  This increases the speed of models that use the dictionary.
d = fhpkg_sort(d);

% Convert the features to "sparse" features.
d = fhpkg_sparsify(d);

% Store the new dictionary in the library.
lib.groups{p.s2} = d;

%***********************************************************************************************************************
% Compute feature vectors for images.
%***********************************************************************************************************************

% Build the full CNS network model.  This time there will be cells above C1 because there is an S2 dictionary.
m = fhpkg_model(p, lib);

% Initialize the model on the GPU.
cns('init', m, 'gpu');
% cns('init', m, 'cpu'); % use this instead if you don't have a GPU

for i = 1 : 1

    % Note: in a real situation we would loop over many images.

    % Read image and load it into the GPU.
    im = imread(fullfile(fileparts(mfilename('fullpath')), 'image_0002.jpg'));
    fhpkg_loadimage(m, im);

    tic;

    % Compute the feature hierarchy for the image.
    cns('run');

    % Retrieve the contents of the C2 layer.
    c2 = cns('get', m.groups{p.c2}.zs, 'val');

    toc;

end

% Release GPU resources.
cns('done');