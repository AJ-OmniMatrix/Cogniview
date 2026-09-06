%% step03_train_vessel_segmentation.m
% Trains a U-Net to segment retinal vessels using the DRIVE dataset.
% Saves the trained network to models/vessel_net.mat
%
% Expects DRIVE unzipped under DR_Project/data/drive/ with subfolders
% containing the original images and the manual vessel-mask images.
% Adjust imgDir / maskDir below to match however you unzipped DRIVE.

projectRoot = fullfile(pwd, 'DR_Project');
imgDir  = fullfile(projectRoot, 'data', 'drive', 'training', 'images');
maskDir = fullfile(projectRoot, 'data', 'drive', 'training', '1st_manual');

assert(exist(imgDir, 'dir') == 7, ...
    'Set imgDir to your DRIVE training images folder.');
assert(exist(maskDir, 'dir') == 7, ...
    'Set maskDir to your DRIVE training manual-mask folder.');

imds = imageDatastore(imgDir);

classNames = ["vessel", "background"];
pixelLabelIDs = [1, 0];
pxds = pixelLabelDatastore(maskDir, classNames, pixelLabelIDs);

% --- Resize everything to a common size for the network ---
inputSize = [256 256 3];

imds.ReadFcn  = @(f) imresize(im2uint8(preprocessImageSimple(imread(f))), inputSize(1:2));
pxds.ReadFcn  = @(f) imresize(imread(f), inputSize(1:2), 'nearest');

trainDS = combine(imds, pxds);

% --- Build a small U-Net ---
numClasses = numel(classNames);
lgraph = unetLayers(inputSize, numClasses, 'EncoderDepth', 3);

options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'MaxEpochs', 30, ...
    'MiniBatchSize', 8, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'VerboseFrequency', 5);

fprintf('Training vessel segmentation U-Net (this can take a while)...\n');
net = trainNetwork(trainDS, lgraph, options);

modelsDir = fullfile(projectRoot, 'models');
if ~exist(modelsDir, 'dir'); mkdir(modelsDir); end
save(fullfile(modelsDir, 'vessel_net.mat'), 'net', 'inputSize', 'classNames');
fprintf('Saved: %s\n', fullfile(modelsDir, 'vessel_net.mat'));

%% Local helper (kept simple/fast for datastore ReadFcn use — full CLAHE
% pipeline from step01 can be substituted in once you're past the first
% working pass).
function out = preprocessImageSimple(img)
    if size(img,3) == 1
        img = repmat(img, 1, 1, 3);
    end
    out = img;
end
