%% step05_train_dr_grading.m
% Trains the main 5-class DR severity model (Grade 0-4) using APTOS 2019,
% via transfer learning on ResNet-18. Saves models/dr_grading_net.mat
%
% APTOS ships as a flat image folder + a CSV of {id_code, diagnosis}.
% This script first reorganizes images into per-class subfolders (which
% imageDatastore can read directly with folder names as labels), then
% trains, then evaluates with a confusion matrix + sensitivity/specificity
% for the referable-DR (Grade >= 2) clinical endpoint.

projectRoot  = fullfile(pwd, 'DR_Project');
aptosDir     = fullfile(projectRoot, 'data', 'aptos');
rawImgDir    = fullfile(aptosDir, 'train_images');   % adjust if your unzip differs
labelCsv     = fullfile(aptosDir, 'train.csv');
organizedDir = fullfile(projectRoot, 'preprocessed', 'aptos_by_class');

assert(exist(rawImgDir, 'dir') == 7, 'Set rawImgDir to your APTOS train_images folder.');
assert(exist(labelCsv, 'file') == 2, 'Set labelCsv to your APTOS train.csv path.');

%% 1. Reorganize into class subfolders (0,1,2,3,4) if not already done
if ~exist(organizedDir, 'dir')
    fprintf('Organizing APTOS images into class folders (one-time step)...\n');
    labels = readtable(labelCsv);
    for g = 0:4
        mkdir(fullfile(organizedDir, num2str(g)));
    end
    for i = 1:height(labels)
        srcFile = fullfile(rawImgDir, [labels.id_code{i} '.png']);
        if ~exist(srcFile, 'file')
            srcFile = fullfile(rawImgDir, [labels.id_code{i} '.jpg']);
        end
        if exist(srcFile, 'file')
            dstFile = fullfile(organizedDir, num2str(labels.diagnosis(i)), [labels.id_code{i} '.png']);
            copyfile(srcFile, dstFile);
        end
    end
end

%% 2. Build datastore with train/val split
imds = imageDatastore(organizedDir, 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
[imdsTrain, imdsVal] = splitEachLabel(imds, 0.85, 'randomized');

inputSize = [224 224 3];
augmenter = imageDataAugmenter( ...
    'RandRotation', [-15 15], ...
    'RandXReflection', true, ...
    'RandXTranslation', [-10 10], ...
    'RandYTranslation', [-10 10]);

augTrain = augmentedImageDatastore(inputSize, imdsTrain, 'DataAugmentation', augmenter);
augVal   = augmentedImageDatastore(inputSize, imdsVal);

%% 3. Transfer learning on ResNet-18
baseNet = resnet18;
lgraph  = layerGraph(baseNet);

numClasses = numel(categories(imdsTrain.Labels));
newFC = fullyConnectedLayer(numClasses, 'Name', 'new_fc', ...
    'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10);
newClassLayer = classificationLayer('Name', 'new_classoutput');

lgraph = replaceLayer(lgraph, 'fc1000', newFC);
lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', newClassLayer);

options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-4, ...
    'MaxEpochs', 15, ...
    'MiniBatchSize', 32, ...
    'ValidationData', augVal, ...
    'ValidationFrequency', 30, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto');   % uses GPU automatically if available

fprintf('Training DR grading model (main training step, allow time)...\n');
net = trainNetwork(augTrain, lgraph, options);

%% 4. Evaluate: 5-class + binary referable-DR (Grade >= 2)
predLabels = classify(net, augVal);
trueLabels = imdsVal.Labels;

figure;
cm = confusionchart(trueLabels, predLabels);
cm.Title = '5-Class DR Grading Confusion Matrix';

trueBinary = double(string(trueLabels)) >= 2;   % 1 = referable
predBinary = double(string(predLabels)) >= 2;

TP = sum(trueBinary & predBinary);
TN = sum(~trueBinary & ~predBinary);
FP = sum(~trueBinary & predBinary);
FN = sum(trueBinary & ~predBinary);

sensitivity = TP / (TP + FN);
specificity = TN / (TN + FP);
fprintf('\nReferable DR (Grade >= 2) performance:\n');
fprintf('  Sensitivity: %.1f%%  (target >90%%)\n', sensitivity * 100);
fprintf('  Specificity: %.1f%%  (target >85%%)\n', specificity * 100);

%% 5. Save
modelsDir = fullfile(projectRoot, 'models');
if ~exist(modelsDir, 'dir'); mkdir(modelsDir); end
save(fullfile(modelsDir, 'dr_grading_net.mat'), 'net', 'inputSize');
fprintf('Saved: %s\n', fullfile(modelsDir, 'dr_grading_net.mat'));
