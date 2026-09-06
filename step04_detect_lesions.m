%% step04_detect_lesions.m
% Defines detectLesions(): finds candidate microaneurysms, hemorrhages,
% and exudates using classical morphological image processing. This is a
% deliberately lightweight starting point — good enough to demonstrate the
% pipeline end-to-end. Swap in a CNN/U-Net trained on IDRiD's pixel-level
% lesion masks (same recipe as step03) once you need higher accuracy.

function lesions = detectLesions(img)
% detectLesions  Detect DR lesion candidates in a preprocessed fundus image.
%   lesions is a struct with fields:
%     .microaneurysms, .hemorrhages  -> binary masks (small/round dark spots)
%     .exudates                       -> binary mask (bright yellow-white spots)
%     .counts                         -> struct with pixel/blob counts per type
%     .overlay                        -> RGB image with lesions marked

    if size(img, 3) == 3
        gray = rgb2gray(img);
        green = img(:, :, 2);   % green channel has best vessel/lesion contrast
    else
        gray = img;
        green = img;
    end
    green = im2double(green);

    % --- Dark lesions (microaneurysms, hemorrhages): top-hat on inverted green channel ---
    invGreen = imcomplement(green);
    se = strel('disk', 8);
    darkTopHat = imtophat(invGreen, se);
    darkMask = darkTopHat > graythresh(darkTopHat) * 1.2;
    darkMask = bwareaopen(darkMask, 3);   % remove single-pixel noise

    % Split dark lesions by blob size: MAs are small & round, hemorrhages larger/irregular
    stats = regionprops(darkMask, 'Area', 'Eccentricity', 'PixelIdxList');
    maMask  = false(size(darkMask));
    hemMask = false(size(darkMask));
    for i = 1:numel(stats)
        if stats(i).Area <= 40 && stats(i).Eccentricity < 0.85
            maMask(stats(i).PixelIdxList) = true;
        elseif stats(i).Area > 40
            hemMask(stats(i).PixelIdxList) = true;
        end
    end

    % --- Bright lesions (exudates): top-hat on green channel directly ---
    brightTopHat = imtophat(green, se);
    exudateMask = brightTopHat > graythresh(brightTopHat) * 1.3;
    exudateMask = bwareaopen(exudateMask, 5);

    % --- Overlay for visualization / report ---
    overlay = im2uint8(repmat(gray, 1, 1, 3));
    overlay = drawMaskOverlay(overlay, maMask,  [255 0   0]);   % red   = MAs
    overlay = drawMaskOverlay(overlay, hemMask, [255 128 0]);   % orange = hemorrhages
    overlay = drawMaskOverlay(overlay, exudateMask, [255 255 0]); % yellow = exudates

    lesions.microaneurysms = maMask;
    lesions.hemorrhages    = hemMask;
    lesions.exudates       = exudateMask;
    lesions.counts.microaneurysms = sum(bwconncomp(maMask).NumObjects);
    lesions.counts.hemorrhages    = sum(bwconncomp(hemMask).NumObjects);
    lesions.counts.exudates       = sum(bwconncomp(exudateMask).NumObjects);
    lesions.overlay = overlay;
end

function outImg = drawMaskOverlay(img, mask, color)
    outImg = img;
    for c = 1:3
        channel = outImg(:, :, c);
        channel(mask) = color(c);
        outImg(:, :, c) = channel;
    end
end

%% Demo
if ~exist('detectLesions_called_as_function', 'var')
    sampleImgPath = '';  % <-- set a real preprocessed fundus image path to test
    if ~isempty(sampleImgPath) && exist(sampleImgPath, 'file')
        img = imread(sampleImgPath);
        lesions = detectLesions(img);
        figure; imshow(lesions.overlay);
        title(sprintf('MAs: %d | Hemorrhages: %d | Exudates: %d', ...
            lesions.counts.microaneurysms, lesions.counts.hemorrhages, lesions.counts.exudates));
    else
        fprintf('Set sampleImgPath at the top of this script to preview lesion detection.\n');
    end
end
