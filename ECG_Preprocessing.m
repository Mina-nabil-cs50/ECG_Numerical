
% Here we load the ECG dataset and prepare it in variables
% so we can use them in the calculations.
%
% sample = index of each sample
% ecg = actual recorded ECG value (MLII)
% time = time of each sample
%
% h = 1/360 seconds
% This means each sample is separated by 1/360 of a second.
% then we remove the baseline wander, that means when we have the ecg in
% like a wave we correct it in a way whhich it makes it centered 
%then we smoothed the ecg ssignal bc it has some noise 

clc;
clear;
close all;


%% 1. Load the ECG dataset

data = readtable('ecg_with_time.csv');

sample = data.sample;
ecg = double(data.MLII);
time = data.time;

fs = 360;
h = 1/fs;

fprintf('\n===== DATASET INFORMATION =====\n');
fprintf('Total samples: %d\n', length(ecg));
fprintf('Sampling frequency: %d Hz\n', fs);
fprintf('Total duration: %.2f seconds\n', time(end));

display_samples = min(10 * fs, length(ecg));


%% 2. Display the raw ECG signal

figure(1);

plot(time(1:display_samples), ecg(1:display_samples), 'b');
title('Complete Raw ECG Recording');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;


%% 3. Remove DC offset

% Shift the signal so that its mean is approximately zero.

ecg_centered = ecg - mean(ecg);

fprintf('\n===== DC OFFSET REMOVAL =====\n');
fprintf('Original mean: %.2f\n', mean(ecg));
fprintf('Centered mean: %.6f\n', mean(ecg_centered));


%% 4. Remove baseline wander

% Estimate the baseline using a moving average.
% Subtract it to remove slow changes in the baseline.

baseline_window = 361;

baseline = movmean(ecg_centered, baseline_window);

ecg_detrended = ecg_centered - baseline;


%% 5. Smooth the ECG signal

% Reduce small fluctuations and noise using a moving average.

smoothing_window = 5;

ecg_filtered = movmean(ecg_detrended, smoothing_window);


%% 6. Complete preprocessing comparison

figure(2);

subplot(3,1,1);
plot(time(1:display_samples), ecg_centered(1:display_samples));
title('Complete Centered ECG');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(time(1:display_samples), ecg_detrended(1:display_samples));
title('Complete ECG After Baseline Wander Removal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(time(1:display_samples), ecg_filtered(1:display_samples));
title('Complete Filtered ECG');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;


%% 7. Preprocessing statistics

fprintf('\n===== PREPROCESSING RESULTS =====\n');

fprintf('Original standard deviation: %.2f\n', std(ecg));
fprintf('Centered standard deviation: %.2f\n', std(ecg_centered));
fprintf('After baseline removal: %.2f\n', std(ecg_detrended));
fprintf('After smoothing: %.2f\n', std(ecg_filtered));


%% 8. Save the processed ECG data

save('ECG_Processed_Data.mat', ...
    'ecg_filtered', 'time', 'fs', 'h');

fprintf('\nProcessed ECG data saved successfully.\n');
