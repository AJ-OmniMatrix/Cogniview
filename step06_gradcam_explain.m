%% step06_gradcam_explain.m
% Defines explainPrediction(): runs the trained DR grading network on one
% image and produces a Grad-CAM attention map + the predicted class and
% confidence, using MATLAB's built-in gradCAM function
% (Deep Learning Toolbox, R2021b+).

function explanation = explainPrediction(net, img, inputSize)
% explainPrediction  Predict DR grade + generate Grad-CAM explainability.
%   net       - trained DAGNetwork/dlnetwork from step05
%   img       - preprocessed RGB fundus image (any size; will be resized)
%   inputSize - e.g. [224 224 3], matching what the network was trained on
%
%   Returns a struct with:
%     .predictedLabel, .confidence
%     .allScores        (per-class probabilities)
%     .camMap            (Grad-CAM heatmap, same size as resized image)
%     .overlayImg        (heatmap blended onto the original image)

    resized = imresize(img, inputSize(1:2));

    [label, scores] = classify(net, resized);
    confidence = max(scores) * 100;

    % Grad-CAM w.r.t. the predicted class
    cam = gradCAM(net, resized, label);

    % Blend heatmap onto original image for visualization
    camNorm = rescale(cam);
    heatmapRGB = ind2rgb(im2uint8(camNorm), jet(256));
    overlayImg = im2uint8(0.6 * im2double(resized) + 0.4 * heatmapRGB);

    explanation.predictedLabel = label;
    explanation.confidence     = confidence;
    explanation.allScores      = scores;
    explanation.camMap         = cam;
    explanation.overlayImg     = overlayImg;
end

%% Demo
if ~exist('explainPrediction_called_as_function', 'var')
    projectRoot = fullfile(pwd, 'DR_Project');
    modelPath   = fullfile(projectRoot, 'models', 'dr_grading_net.mat');
    sampleImgPath = '';  % <-- set a real fundus image path to test

    if exist(modelPath, 'file') && ~isempty(sampleImgPath) && exist(sampleImgPath, 'file')
        loaded = load(modelPath, 'net', 'inputSize');
        img = imread(sampleImgPath);
        exp = explainPrediction(loaded.net, img, loaded.inputSize);

        figure;
        subplot(1,2,1); imshow(img); title('Original');
        subplot(1,2,2); imshow(exp.overlayImg);
        title(sprintf('Grad-CAM | Grade %s (%.1f%% confidence)', ...
            string(exp.predictedLabel), exp.confidence));
    else
        fprintf('Train the model in step05 first, and set sampleImgPath above.\n');
    end
end
