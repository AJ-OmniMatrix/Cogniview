%% step01_preprocess_image.m
% Defines preprocessImage(), the shared preprocessing step used by every
% later module: resize -> illumination normalization -> denoise -> CLAHE.
%
% DEMO: running this script directly (F5) will preprocess one sample image
% if you point sampleImgPath at a real file, and show before/after.

function outImg = preprocessImage(inImg, targetSize)
% preprocessImage  Standardize a fundus image for downstream analysis.
%   outImg = preprocessImage(inImg) applies default 512x512 target size.
%   outImg = preprocessImage(inImg, targetSize) lets you set size, e.g. [256 256].
%
%   Steps: resize -> convert to LAB -> CLAHE on L channel only (preserves
%   color) -> mild denoise -> back to RGB.

    if nargin < 2
        targetSize = [512 512];
    end

    % 1. Resize
    img = imresize(inImg, targetSize);

    % 2. Ensure RGB (some fundus images are read as indexed/grayscale)
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end

    % 3. Convert to LAB colorspace, CLAHE on lightness channel only
    labImg = rgb2lab(img);
    L = labImg(:, :, 1) / 100;              % normalize to [0,1] for adapthisteq
    L_eq = adapthisteq(L, 'ClipLimit', 0.01, 'Distribution', 'rayleigh');
    labImg(:, :, 1) = L_eq * 100;
    img = lab2rgb(labImg);
    img = im2uint8(img);

    % 4. Mild denoise (edge-preserving)
    outImg = imbilatfilt(img);
end

%% Demo (only runs if you execute this file directly, not when called as a function)
if ~exist('preprocessImage_called_as_function', 'var')
    sampleImgPath = '';  % <-- set to a real fundus image path to test, e.g.
                         % fullfile('DR_Project','data','aptos','train_images','xxxx.png')
    if ~isempty(sampleImgPath) && exist(sampleImgPath, 'file')
        raw = imread(sampleImgPath);
        clean = preprocessImage(raw);
        figure;
        subplot(1,2,1); imshow(raw);  title('Original');
        subplot(1,2,2); imshow(clean); title('Preprocessed (CLAHE + denoise)');
    else
        fprintf('Set sampleImgPath at the top of this script to preview preprocessing.\n');
    end
end
