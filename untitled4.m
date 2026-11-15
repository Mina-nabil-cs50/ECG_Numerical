
%% STEP 6: Verify ECG Data

fprintf('\n===== ECG DATA VERIFICATION =====\n');

% Dataset dimensions
fprintf('Number of rows: %d\n', height(data));
fprintf('Number of columns: %d\n', width(data));

% Check missing values
fprintf('Missing sample values: %d\n', sum(ismissing(data.sample)));
fprintf('Missing MLII values: %d\n', sum(ismissing(data.MLII)));
fprintf('Missing time values: %d\n', sum(ismissing(data.time)));

% Check sampling interval
fprintf('First timestamp: %.6f seconds\n', time(1));
fprintf('Last timestamp: %.6f seconds\n', time(end));

fprintf('Average sampling interval: %.8f seconds\n', mean(diff(time)));
fprintf('Calculated sampling frequency: %.4f Hz\n', 1/mean(diff(time)));

% ECG amplitude information
fprintf('\n===== ECG AMPLITUDE =====\n');

fprintf('Minimum MLII: %d\n', min(ecg));
fprintf('Maximum MLII: %d\n', max(ecg));
fprintf('Mean MLII: %.2f\n', mean(ecg));
fprintf('Standard deviation: %.2f\n', std(double(ecg)));

% First 10 seconds
fprintf('\n===== FIRST 10 SECONDS =====\n');

fprintf('Samples in segment: %d\n', length(ecg_segment));
fprintf('Minimum amplitude: %d\n', min(ecg_segment));
fprintf('Maximum amplitude: %d\n', max(ecg_segment));

% First 10 readings
disp('First 10 ECG readings:');
disp(table(sample(1:10), ecg(1:10), time(1:10), ...
    'VariableNames', {'Sample','MLII','Time'}));
