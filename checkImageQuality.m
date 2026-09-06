function result = checkImageQuality(img)

    % Convert to grayscale
    if size(img, 3) == 3
        gray = rgb2gray(img);
    else
        gray = img;
    end

    gray = im2double(gray);

    % ---------------------------------------------------------
    % 1. Detect retinal field
    % ---------------------------------------------------------
    fovMask = gray > 0.05;

    fovMask = bwareaopen(fovMask, 500);
    fovMask = bwareafilt(fovMask, 1);
    fovMask = imfill(fovMask, 'holes');

    fovRatio = nnz(fovMask) / numel(fovMask);

    % ---------------------------------------------------------
    % 2. Focus / sharpness inside retinal field
    % ---------------------------------------------------------
    lapKernel = fspecial('laplacian', 0.2);
    lapImg = imfilter(gray, lapKernel);

    retinalLap = lapImg(fovMask);
    focusScore = var(retinalLap);

    % ---------------------------------------------------------
    % 3. Brightness inside retinal field
    % ---------------------------------------------------------
    retinalGray = gray(fovMask);

    meanBrightness = mean(retinalGray);
    stdBrightness = std(retinalGray);

    % ---------------------------------------------------------
    % 4. Quality decision
    % ---------------------------------------------------------
    reasons = {};

    % Provisional threshold based on our APTOS pilot test
    if focusScore < 0.00012
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

    % ---------------------------------------------------------
    % 5. Return result
    % ---------------------------------------------------------
    result.isAcceptable = isempty(reasons);
    result.focusScore = focusScore;
    result.meanBrightness = meanBrightness;
    result.stdBrightness = stdBrightness;
    result.fovRatio = fovRatio;
    result.reason = strjoin(reasons, ', ');

end