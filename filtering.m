clc;
clear;
close all;

%% 1 read the dataset
data = readtable('ecg_with_time.csv');

%% load columns 
sample = data.sample;
ecg = data.MLII;
time = data.time;

%% display dataset info

fprintf('Total samples: %d\n', length(sample));
fprintf('Sampling frequency: 360 Hz\n');
fprintf('Total duration: %.2f seconds\n', time(end));

%% extract 10 secs
duration = 10;

indices = time <= duration;

time_segment = time(indices);
ecg_segment = ecg(indices);

%% plot the raw ecg 
figure;

plot(time_segment, ecg_segment);

title('Raw ECG Signal - First 10 Seconds');
xlabel('Time (seconds)');
ylabel('ECG Amplitude (MLII)');
grid on;
 
%%
%% STAGE 2: RAW ECG SIGNAL INSPECTION

% Figure 1: Entire ECG recording
figure;

plot(time, ecg, 'b');
title('Entire Raw ECG Recording');
xlabel('Time (seconds)');
ylabel('MLII Amplitude (ADC units)');
grid on;


% Figure 2: First 10 seconds
figure;

plot(time_segment, ecg_segment, 'b');
title('Raw ECG - First 10 Seconds');
xlabel('Time (seconds)');
ylabel('MLII Amplitude (ADC units)');
grid on;


% Figure 3: First 3 seconds (zoomed)
zoom_indices = time <= 3;

figure;

plot(time(zoom_indices), ecg(zoom_indices), 'b');
title('Raw ECG - First 3 Seconds (Zoomed)');
xlabel('Time (seconds)');
ylabel('MLII Amplitude (ADC units)');
grid on;


%% Sstage 2
%%

fprintf('\n raw ecg \n');

% Location of minimum and maximum readings
[min_value, min_index] = min(ecg);
[max_value, max_index] = max(ecg);

fprintf('Minimum amplitude: %d\n', min_value);
fprintf('Minimum occurs at: %.6f seconds\n', time(min_index));

fprintf('Maximum amplitude: %d\n', max_value);
fprintf('Maximum occurs at: %.6f seconds\n', time(max_index));

% Additional statistics
fprintf('Median amplitude: %.2f\n', median(ecg));
fprintf('Mean amplitude: %.2f\n', mean(ecg));
fprintf('Amplitude range: %d\n', max(ecg) - min(ecg));

% First 3 seconds statistics
short_segment = ecg(zoom_indices);

fprintf('\nFirst 3 seconds:\n');
fprintf('Minimum: %d\n', min(short_segment));
fprintf('Maximum: %d\n', max(short_segment));
fprintf('Mean: %.2f\n', mean(short_segment));
fprintf('Standard deviation: %.2f\n', std(double(short_segment)));

%%%% STAGE 3: ECG PREPROCESSING

% Convert signal to double precision
ecg = double(ecg);

% Remove DC offset
ecg_centered = ecg - mean(ecg);

% Plot original and centered signals
figure;

subplot(2,1,1);
plot(time_segment, ecg_segment);
title('Original ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;

subplot(2,1,2);
plot(time_segment, ecg_centered(1:length(time_segment)));
title('ECG After DC Offset Removal');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;

% Display results
fprintf('\n===== DC OFFSET REMOVAL =====\n');
fprintf('Original mean: %.2f\n', mean(ecg));
fprintf('Centered mean: %.6f\n', mean(ecg_centered));
%%
%%
%%
%% The first numerical thing in the project, numerical differentiation 
%h=1/360 
% each second contains 360 samples 

%% STAGE 4: NUMERICAL DIFFERENTIATION

% interval
h = 1/360;

%first derivative
ecg_derivative = zeros(size(ecg_centered));

for i = 2:length(ecg_centered)-1
    ecg_derivative(i) = ...
        (ecg_centered(i+1) - ecg_centered(i-1)) / (2*h);
end

% forward difference for first sample
ecg_derivative(1) = ...
    (ecg_centered(2) - ecg_centered(1)) / h;

% backward difference for last sample
ecg_derivative(end) = ...
    (ecg_centered(end) - ecg_centered(end-1)) / h;

% plot first 3 seconds
zoom_indices = time <= 3;

figure;

subplot(2,1,1);
plot(time(zoom_indices), ecg_centered(zoom_indices));
title('Centered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
plot(time(zoom_indices), ecg_derivative(zoom_indices));
title('First Derivative of ECG');
xlabel('Time (seconds)');
ylabel('Rate of Change (ADC units/second)');
grid on;

% display derivative statistics
fprintf('\n===== NUMERICAL DIFFERENTIATION =====\n');
fprintf('Maximum derivative: %.2f\n', max(ecg_derivative));
fprintf('Minimum derivative: %.2f\n', min(ecg_derivative));
fprintf('Mean absolute derivative: %.2f\n', ...
    mean(abs(ecg_derivative)));
%%
%%Filter
%% ECG FILTERING 

fs = 360;

% STEP 1: Estimate baseline using a 1-second moving average
baseline_window = 361;

baseline = movmean(ecg_centered, baseline_window);

% STEP 2: Remove estimated baseline
ecg_detrended = ecg_centered - baseline;

% STEP 3: Smooth the signal using a 5-sample moving average
smoothing_window = 5;

ecg_filtered = movmean(ecg_detrended, smoothing_window);

% STEP 4: Plot comparison

figure;

subplot(3,1,1);
plot(time_segment, ecg_centered(1:length(time_segment)));
title('Original Centered ECG');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(time_segment, ecg_detrended(1:length(time_segment)));
title('After Baseline Wander Removal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(time_segment, ecg_filtered(1:length(time_segment)));
title('After Moving Average Smoothing');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

% STEP 5: Display statistics

fprintf('\n===== ECG FILTERING =====\n');

fprintf('Original standard deviation: %.2f\n', ...
    std(ecg_centered));

fprintf('After baseline removal: %.2f\n', ...
    std(ecg_detrended));

fprintf('After smoothing: %.2f\n', ...
    std(ecg_filtered));


%%
%%

