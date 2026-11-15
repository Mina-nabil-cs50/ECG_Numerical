
clc;
clear;
close all;

%% 1. load the ecg dataset

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

display_samples = 10 * fs;


%% 2. complete raw ecg signal - static figure

figure(1);
plot(time(1:display_samples), ecg(1:display_samples), 'b');
title('Complete Raw ECG Recording');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;


%% 3. remove dc offset

ecg_centered = ecg - mean(ecg);

fprintf('\n===== DC OFFSET REMOVAL =====\n');
fprintf('Original mean: %.2f\n', mean(ecg));
fprintf('Centered mean: %.6f\n', mean(ecg_centered));


%% 4. numerical differentiation - static figure

ecg_derivative = zeros(size(ecg_centered));

for i = 2:length(ecg_centered)-1
    ecg_derivative(i) = ...
        (ecg_centered(i+1) - ecg_centered(i-1)) / (2*h);
end

ecg_derivative(1) = ...
    (ecg_centered(2) - ecg_centered(1)) / h;

ecg_derivative(end) = ...
    (ecg_centered(end) - ecg_centered(end-1)) / h;

fprintf('\n===== NUMERICAL DIFFERENTIATION =====\n');
fprintf('Maximum derivative: %.2f\n', max(ecg_derivative));
fprintf('Minimum derivative: %.2f\n', min(ecg_derivative));
fprintf('Mean absolute derivative: %.2f\n', ...
    mean(abs(ecg_derivative)));

figure(2);

subplot(2,1,1);
plot(time(1:display_samples), ecg_centered(1:display_samples));
title('Complete Centered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(time(1:display_samples), ecg_derivative(1:display_samples));
title('Complete First Derivative of ECG');
xlabel('Time (seconds)');
ylabel('Rate of Change (ADC units/second)');
grid on;


%% 5. remove baseline wander

baseline_window = 361;

baseline = movmean(ecg_centered, baseline_window);

ecg_detrended = ecg_centered - baseline;


%% 6. smooth the ecg signal

smoothing_window = 5;

ecg_filtered = movmean(ecg_detrended, smoothing_window);


%% 7. complete preprocessing comparison - static figure

figure(3);

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


%% 8. preprocessing statistics

fprintf('\n===== PREPROCESSING RESULTS =====\n');

fprintf('Original standard deviation: %.2f\n', std(ecg));
fprintf('Centered standard deviation: %.2f\n', std(ecg_centered));
fprintf('After baseline removal: %.2f\n', std(ecg_detrended));
fprintf('After smoothing: %.2f\n', std(ecg_filtered));

%%
save('ECG_Processed_Data.mat', ...
    'ecg_filtered', 'time', 'fs', 'h');