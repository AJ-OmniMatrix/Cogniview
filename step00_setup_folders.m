%% step00_setup_folders.m
% Creates the DR_Project folder tree used by every other script.
% Run this once, then copy/unzip each downloaded dataset into data/<name>/.

projectRoot = fullfile(pwd, 'DR_Project');

folders = {
    fullfile(projectRoot, 'data', 'aptos')
    fullfile(projectRoot, 'data', 'idrid')
    fullfile(projectRoot, 'data', 'drive')
    fullfile(projectRoot, 'data', 'messidor2')
    fullfile(projectRoot, 'preprocessed')
    fullfile(projectRoot, 'models')
    fullfile(projectRoot, 'reports')
    fullfile(projectRoot, 'results')
};

for i = 1:numel(folders)
    if ~exist(folders{i}, 'dir')
        mkdir(folders{i});
        fprintf('Created: %s\n', folders{i});
    else
        fprintf('Already exists: %s\n', folders{i});
    end
end

fprintf('\nProject root: %s\n', projectRoot);
fprintf('Next: copy your downloaded datasets into the matching data/<name>/ folder.\n');
fprintf('  data/aptos      <- APTOS train_images/ + train.csv\n');
fprintf('  data/idrid      <- IDRiD Disease Grading + Segmentation folders\n');
fprintf('  data/drive      <- DRIVE training/ and test/ folders\n');
fprintf('  data/messidor2  <- Messidor-2 images + label CSV\n');
