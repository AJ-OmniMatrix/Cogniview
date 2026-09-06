%% step07_run_inference_pipeline.m
% THE INTEGRATION SCRIPT — runs one fundus image through the full pipeline:
%   Quality Check -> Preprocessing -> Vessel Segmentation -> Lesion Detection
%   -> DR Grading -> Grad-CAM Explainability -> Report
%
% This mirrors the flow diagram in the problem brief. Set imagePath below
% to any fundus image (from APTOS test set, or Messidor-2 for external
% validation once the model is frozen), then run the whole script (F5).

projectRoot = fullfile(pwd, 'DR_Project');
imagePath   = '';   % <-- SET THIS: path to one fundus image you want screened

assert(~isempty(imagePath) && exist(imagePath, 'file') == 2, ...
    'Set imagePath at the top of this script to a real fundus image file.');

tic;

%% Load trained models
vesselModelPath = fullfile(projectRoot, 'models', 'vessel_net.mat');
gradingModelPath = fullfile(projectRoot, 'models', 'dr_grading_net.mat');

hasVesselModel  = exist(vesselModelPath, 'file') == 2;
hasGradingModel = exist(gradingModelPath, 'file') == 2;
assert(hasGradingModel, 'Train the DR grading model first (step05).');

gradingModel = load(gradingModelPath, 'net', 'inputSize');
if hasVesselModel
    vesselModel = load(vesselModelPath, 'net', 'inputSize', 'classNames');
end

%% 1. Load image
rawImg = imread(imagePath);

%% 2. Quality check
quality = checkImageQuality(rawImg);
if ~quality.isAcceptable
    fprintf('IMAGE REJECTED — ungradeable (%s). Recapture required.\n', quality.reason);
    return;
end
fprintf('Quality check passed.\n');

%% 3. Preprocessing
cleanImg = preprocessImage(rawImg);

%% 4. Vessel segmentation (optional structural context for the report)
if hasVesselModel
    vesselInput = imresize(cleanImg, vesselModel.inputSize(1:2));
    vesselPred = semanticseg(vesselInput, vesselModel.net);
    vesselMask = vesselPred == 'vessel';
else
    vesselMask = [];
    fprintf('(Vessel model not found — skipping vessel overlay. Run step03 to enable.)\n');
end

%% 5. Lesion detection
lesions = detectLesions(cleanImg);

%% 6. DR grading + 7. Grad-CAM explainability
explanation = explainPrediction(gradingModel.net, cleanImg, gradingModel.inputSize);

%% 8. Generate report
report = generateReport(imagePath, quality, lesions, explanation, vesselMask);

elapsedSec = toc;
fprintf('\nPipeline completed in %.2f seconds.\n', elapsedSec);
fprintf('(Use this per-image time as the AI-processing-stage input to the Simulink workflow model.)\n');

%% Save report
reportsDir = fullfile(projectRoot, 'reports');
if ~exist(reportsDir, 'dir'); mkdir(reportsDir); end
[~, baseName] = fileparts(imagePath);
save(fullfile(reportsDir, [baseName '_report.mat']), 'report');
fprintf('Report saved to: %s\n', fullfile(reportsDir, [baseName '_report.mat']));
