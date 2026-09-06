function outImg = preprocessImage(inImg, targetSize)

if nargin < 2
    targetSize = [512 512];
end

% 1. Resize
img = imresize(inImg, targetSize);

% 2. Ensure RGB
if size(img, 3) == 1
    img = repmat(img, 1, 1, 3);
end

% 3. LAB + CLAHE on lightness channel
labImg = rgb2lab(img);
L = labImg(:, :, 1) / 100;

L_eq = adapthisteq(L, ...
    'ClipLimit', 0.01, ...
    'Distribution', 'rayleigh');

labImg(:, :, 1) = L_eq * 100;

img = lab2rgb(labImg);
img = im2uint8(img);

% 4. Mild edge-preserving denoise
outImg = imbilatfilt(img);

end