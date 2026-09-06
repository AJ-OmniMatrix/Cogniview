%% step02_check_image_quality.m
% Defines checkImageQuality(): a lightweight, rule-based gate that flags
% ungradeable images (blurry / too dark or bright / poor field-of-view)
% before they enter the rest of the pipeline. Replace the thresholds with
% a trained classifier later if you have quality-labeled data.

function result = checkImageQuality(img)
% checkImageQuality  Assess fundus image quality.
%   result is a struct with fields:
%     .isAcceptable (logical)
%     .focusScore   (higher = sharper; Laplacian variance)
%     .meanBrightness, .stdBrightness
%     .fovRatio     (fraction of frame covered by the retinal disc)
%     .reason       (string explaining any failure)

    if size(img, 3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end
    gray = im2double(gray);

    % --- Focus: variance of Laplacian (blur detector) ---
    lapKernel = fspecial('laplacian', 0.2);
    lapImg = imfilter(gray, lapKernel);
    focusScore = var(lapImg(:));

    % --- Illumination ---
    meanBrightness = mean(gray(:));
    stdBrightness  = std(gray(:));

    % --- Field of view: rough retinal-disc mask via Otsu threshold ---
    mask = imbinarize(gray, 'adaptive', 'Sensitivity', 0.4);
    mask = bwareafilt(mask, 1);   % keep largest connected region
    fovRatio = sum(mask(:)) / numel(mask);

    % --- Decision thresholds (tune on your own labeled quality samples) ---
    reasons = {};
    if focusScore < 0.0008
        reasons{end+1} = 'too blurry';
    end
    if meanBrightness < 0.15
        reasons{end+1} = 'too dark';
    elseif meanBrightness > 0.85
        reasons{end+1} = 'overexposed';
    end
    if fovRatio < 0.35
        reasons{end+1} = 'insufficient field of view';
    end

    result.isAcceptable   = isempty(reasons);
    result.focusScore     = focusScore;
    result.meanBrightness = meanBrightness;
    result.stdBrightness  = stdBrightness;
    result.fovRatio       = fovRatio;
    result.reason         = strjoin(reasons, ', ');
end

%% Demo
if ~exist('checkImageQuality_called_as_function', 'var')
    sampleImgPath = '';  % <-- set a real image path to test
    if ~isempty(sampleImgPath) && exist(sampleImgPath, 'file')
        img = imread(sampleImgPath);
        q = checkImageQuality(img);
        disp(q);
        if q.isAcceptable
            fprintf('Result: ACCEPTABLE\n');
        else
            fprintf('Result: UNGRADEABLE (%s)\n', q.reason);
        end
    else
        fprintf('Set sampleImgPath at the top of this script to test quality checking.\n');
    end
end
