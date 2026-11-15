
clc;
clear;

%% 1. load processed ecg data

load('ECG_Processed_Data.mat');

fprintf('\n===== LIVE ECG MONITOR =====\n');


%% 2. initialize detection settings

chunk_size = 18;
window_seconds = 5;

minimum_distance = round(0.25 * fs);

% Use the first 2 seconds for initial threshold calibration
calibration_samples = 2 * fs;

threshold = 0.5 * max(ecg_filtered(1:calibration_samples));

r_peaks = [];
r_peak_times = [];
recent_rr = [];

current_bpm = NaN;


%% 3. initialize live graph

figure(4);

ecg_plot = plot(NaN, NaN, 'b');
hold on;

peak_plot = plot(NaN, NaN, 'ro', ...
    'MarkerFaceColor', 'r');

title('Live ECG Monitor');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');

legend('Filtered ECG', 'Detected R-peaks');
grid on;


%% 4. real-time ECG playback and R-peak detection

playback_clock = tic;

fprintf('\nStarting ECG playback and R-peak detection...\n');
fprintf('Initial threshold: %.2f\n', threshold);

for last_index = chunk_size:chunk_size:length(ecg_filtered)

    first_new_index = max(2, last_index - chunk_size);

    % Detect R-peaks after the initial calibration period

    for i = max(first_new_index, calibration_samples):last_index-1

        if ecg_filtered(i) > ecg_filtered(i-1) && ...
           ecg_filtered(i) >= ecg_filtered(i+1) && ...
           ecg_filtered(i) > threshold

            if isempty(r_peaks) || ...
               i - r_peaks(end) >= minimum_distance

                r_peaks(end+1) = i;
                r_peak_times(end+1) = time(i);

                % Calculate RR interval

                if length(r_peak_times) >= 2

                    new_rr = r_peak_times(end) - ...
                             r_peak_times(end-1);

                    recent_rr(end+1) = new_rr;

                    if length(recent_rr) > 5
                        recent_rr = recent_rr(end-4:end);
                    end

                    % Calculate current BPM

                    current_bpm = 60 / median(recent_rr);

                    fprintf('Time: %.2f s | RR: %.3f s | BPM: %.2f\n', ...
                        time(i), new_rr, current_bpm);

                end
            end
        end
    end


    %% update live graph

    x_start = max(0, time(last_index) - window_seconds);

    start_index = max(1, last_index - round(window_seconds * fs));

    set(ecg_plot, ...
        'XData', time(start_index:last_index), ...
        'YData', ecg_filtered(start_index:last_index));

    visible_mask = r_peak_times >= x_start;

    visible_peaks = r_peaks(visible_mask);

    set(peak_plot, ...
        'XData', r_peak_times(visible_mask), ...
        'YData', ecg_filtered(visible_peaks));

    xlim([x_start, max(window_seconds, time(last_index))]);

    if isnan(current_bpm)
        title('Live ECG Monitor | Calculating BPM...');
    else
        title(sprintf('Live ECG Monitor | BPM: %.1f', current_bpm));
    end

    drawnow limitrate;


    %% maintain real-time playback speed

    remaining_time = time(last_index) - toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end


%% 5. final results

fprintf('\n===== PLAYBACK FINISHED =====\n');

fprintf('Total detected R-peaks: %d\n', length(r_peaks));

if ~isnan(current_bpm)
    fprintf('Final calculated BPM: %.2f\n', current_bpm);
else
    fprintf('Not enough R-peaks to calculate BPM.\n');
end
