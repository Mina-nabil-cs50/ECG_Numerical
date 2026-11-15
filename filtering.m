
clc;
clear;
close all;

%% 1. load the ecg dataset

% Read the csv file
data = readtable('ecg_with_time.csv');

% Extract dataset columns
sample = data.sample;
ecg = double(data.MLII);
time = data.time;

% Define sampling frequency and sampling interval
fs = 360;
h = 1/fs;

% Display dataset information
fprintf('\n===== DATASET INFORMATION =====\n');
fprintf('Total samples: %d\n', length(ecg));
fprintf('Sampling frequency: %d Hz\n', fs);
fprintf('Total duration: %.2f seconds\n', time(end));


%% 2. inspect the raw ecg signal

% Extract the first 10 seconds
indices = time <= 10;

time_segment = time(indices);
ecg_segment = ecg(indices);

% Plot the first 10 seconds
figure;
plot(time_segment, ecg_segment);
title('Raw ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;


%% 3. remove dc offset

% Calculate the mean amplitude and subtract it from every sample
% This moves the signal average towards zero without changing its shape

ecg_centered = ecg - mean(ecg);

fprintf('\n===== DC OFFSET REMOVAL =====\n');
fprintf('Original mean: %.2f\n', mean(ecg));
fprintf('Centered mean: %.6f\n', mean(ecg_centered));


%% 4. numerical differentiation
% Rising ECG waveform → positive derivative.
% Falling ECG waveform → negative derivative.
% Local peaks and valleys → derivative approximately zero.

% Calculate the first derivative using the central difference method
% This measures the rate of change of the ECG amplitude

ecg_derivative = zeros(size(ecg_centered));

% Central difference for interior samples
for i = 2:length(ecg_centered)-1
    ecg_derivative(i) = ...
        (ecg_centered(i+1) - ecg_centered(i-1)) / (2*h);
end

% Forward difference for the first sample
ecg_derivative(1) = ...
    (ecg_centered(2) - ecg_centered(1)) / h;

% Backward difference for the last sample
ecg_derivative(end) = ...
    (ecg_centered(end) - ecg_centered(end-1)) / h;

fprintf('\n===== NUMERICAL DIFFERENTIATION =====\n');
fprintf('Maximum derivative: %.2f\n', max(ecg_derivative));
fprintf('Minimum derivative: %.2f\n', min(ecg_derivative));
fprintf('Mean absolute derivative: %.2f\n', ...
    mean(abs(ecg_derivative)));

% Plot the first 3 seconds of the signal and its derivative
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


%% 5. remove baseline wander

% Estimate the slowly changing baseline using a 361-sample moving average
% The window is approximately one second long

baseline_window = 361;
baseline = movmean(ecg_centered, baseline_window);

% Subtract the estimated baseline from the signal
ecg_detrended = ecg_centered - baseline;


%% 6. smooth the ecg signal

% Apply a 5-sample moving average to reduce rapid fluctuations
% This helps smooth the signal while preserving heartbeat features

smoothing_window = 5;
ecg_filtered = movmean(ecg_detrended, smoothing_window);


%% 7. compare filtering results

% Plot the different preprocessing stages over the first 10 seconds

figure;

subplot(3,1,1);
plot(time_segment, ecg_centered(indices));
title('Centered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(time_segment, ecg_detrended(indices));
title('After Baseline Wander Removal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

subplot(3,1,3);
plot(time_segment, ecg_filtered(indices));
title('Final Filtered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;


%% 8. compare preprocessing results

% Standard deviation measures the spread of signal amplitudes
% Compare how each preprocessing operation changes the signal

fprintf('\n PREPROCESSING RESULTS \n');
fprintf('Original standard deviation: %.2f\n', std(ecg));
fprintf('Centered standard deviation: %.2f\n', std(ecg_centered));
fprintf('After baseline removal: %.2f\n', std(ecg_detrended));
fprintf('After smoothing: %.2f\n', std(ecg_filtered));
%%
%%From here we will use ecg_filtered to continue working

%% 9. real-time r peak detection and heart rate

% use the already filtered ecg signal
% process it in chronological order

chunk_size = 18;
window_seconds = 5;

% minimum distance between consecutive r peaks
minimum_distance = round(0.25 * fs);

% detection threshold
threshold = 0.5 * max(ecg_filtered);

% variables for storing detected peaks
r_peaks = [];
r_peak_times = [];

% store the most recent rr intervals
recent_rr = [];

% create the live ecg graph
figure;

ecg_plot = plot(NaN, NaN, 'b');
hold on;

peak_plot = plot(NaN, NaN, 'ro', ...
    'MarkerFaceColor', 'r');

title('Live ECG and R-Peak Detection');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
legend('Filtered ECG', 'Detected R peaks');
grid on;

playback_clock = tic;

fprintf('\n===== LIVE HEART RATE MONITOR =====\n');

% process the filtered signal in chronological order
for last_index = 3:chunk_size:length(ecg_filtered)

    % current samples available
    current_time = time(1:last_index);
    current_ecg = ecg_filtered(1:last_index);

    % inspect new samples for local maxima
    first_new_index = max(2, last_index - chunk_size);

    for i = first_new_index:last_index-1

        if ecg_filtered(i) > ecg_filtered(i-1) && ...
           ecg_filtered(i) >= ecg_filtered(i+1) && ...
           ecg_filtered(i) > threshold

            % check minimum distance between peaks
            if isempty(r_peaks) || ...
               i - r_peaks(end) >= minimum_distance

                r_peaks(end+1) = i;
                r_peak_times(end+1) = time(i);

                % calculate the latest rr interval
                if length(r_peak_times) >= 2

                    new_rr = r_peak_times(end) - ...
                             r_peak_times(end-1);

                    recent_rr(end+1) = new_rr;

                    % keep only the latest five intervals
                    if length(recent_rr) > 5
                        recent_rr = recent_rr(end-4:end);
                    end

                    % calculate current heart rate
                    current_bpm = 60 / median(recent_rr);

                    fprintf('Time: %.2f s | BPM: %.2f\n', ...
                        time(i), current_bpm);

                end

            end

        end

    end

    % update the graph
    set(ecg_plot, ...
        'XData', current_time, ...
        'YData', current_ecg);

    set(peak_plot, ...
        'XData', r_peak_times, ...
        'YData', ecg_filtered(r_peaks));

    % show the latest five seconds
    current_position = time(last_index);
    x_start = max(0, current_position - window_seconds);

    xlim([x_start, max(window_seconds, current_position)]);

    drawnow limitrate;

    % synchronize playback with recording time
    remaining_time = time(last_index) - toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end
