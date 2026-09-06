%% step08_generate_report.m
% Defines generateReport(): assembles the final screening report matching
% the example output format in the problem brief (severity, confidence,
% referable flag, evidence, Grad-CAM, recommendation) and displays it.

function report = generateReport(imagePath, quality, lesions, explanation, vesselMask)
% generateReport  Build + display the annotated DR screening report.

    gradeNames = ["No DR", "Mild NPDR", "Moderate NPDR", "Severe NPDR", "Proliferative DR"];
    gradeNum = double(string(explanation.predictedLabel));
    severityText = gradeNames(gradeNum + 1);
    isReferable = gradeNum >= 2;

    % --- Build evidence description from lesion counts ---
    evidenceParts = {};
    if lesions.counts.microaneurysms > 0
        evidenceParts{end+1} = sprintf('%d microaneurysm candidate(s)', lesions.counts.microaneurysms);
    end
    if lesions.counts.hemorrhages > 0
        evidenceParts{end+1} = sprintf('%d hemorrhage candidate(s)', lesions.counts.hemorrhages);
    end
    if lesions.counts.exudates > 0
        evidenceParts{end+1} = sprintf('%d exudate candidate(s)', lesions.counts.exudates);
    end
    if isempty(evidenceParts)
        evidenceText = 'No significant lesions detected';
    else
        evidenceText = strjoin(evidenceParts, '; ');
    end

    if isReferable
        recommendation = 'Ophthalmological referral recommended';
    else
        recommendation = 'Routine annual re-screening recommended';
    end

    % --- Assemble report struct ---
    report.imagePath      = imagePath;
    report.qualityCheck   = quality;
    report.predictedGrade = gradeNum;
    report.severityText   = severityText;
    report.confidence     = explanation.confidence;
    report.isReferable    = isReferable;
    report.evidenceText   = evidenceText;
    report.recommendation = recommendation;
    report.lesionCounts   = lesions.counts;

    % --- Print text summary (matches brief's example format) ---
    fprintf('\n========== DR SCREENING REPORT ==========\n');
    fprintf('Image: %s\n', imagePath);
    fprintf('Predicted severity: %s (Grade %d)\n', severityText, gradeNum);
    fprintf('Confidence: %.1f%%\n', explanation.confidence);
    fprintf('Referable DR: %s\n', string(isReferable));
    fprintf('Evidence detected: %s\n', evidenceText);
    fprintf('AI attention: Grad-CAM (see figure)\n');
    fprintf('Recommendation: %s\n', recommendation);
    fprintf('==========================================\n');

    % --- Visual panel ---
    figure('Name', 'DR Screening Report');
    subplot(2,2,1); imshow(imread(imagePath)); title('Original Image');
    subplot(2,2,2); imshow(lesions.overlay); title('Lesion Evidence');
    subplot(2,2,3); imshow(explanation.overlayImg);
    title(sprintf('Grad-CAM — %s (%.1f%%)', severityText, explanation.confidence));
    subplot(2,2,4);
    if ~isempty(vesselMask)
        imshow(vesselMask); title('Vessel Segmentation');
    else
        axis off;
        text(0.1, 0.5, sprintf('%s\nReferable: %s\n\n%s', ...
            severityText, string(isReferable), recommendation), 'FontSize', 11);
    end
end
