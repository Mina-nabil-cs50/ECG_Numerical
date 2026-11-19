
clc;
clear;
close all;

% connect to arduino

s = serialport("COM9", 115200);
s.Timeout = 2;

pause(3);

fprintf('waiting for max30102...\n');

% wait for sensor initialization

sensor_ready = false;

while ~sensor_ready

    line = strtrim(readline(s));

    if line == "READY"

        sensor_ready = true;

    elseif line == "ERROR:MAX30102_NOT_FOUND"

        clear s;
        error('max30102 not detected.');

    end

end

fprintf('sensor connected successfully.\n');
fprintf('place your finger on the sensor.\n');

% prepare live data

timestamps = [];
ir_data = [];

fs = 50;
minimum_distance = round(0.4 * fs);

% create live plots

figure('Name', 'MAX30102 Real-Time Monitoring');

subplot(2,1,1);

signal_plot = plot(nan, nan);
hold on;

peak_plot = plot(nan, nan, 'ro', 'MarkerFaceColor', 'r');

title('live ppg signal');
xlabel('time (seconds)');
ylabel('ir reading');
legend('ir signal', 'detected peaks');
grid on;

subplot(2,1,2);

derivative_plot = plot(nan, nan);

title('numerical differentiation');
xlabel('time (seconds)');
ylabel('derivative');
grid on;

% create bpm display

bpm_text = annotation('textbox', ...
    [0.72 0.91 0.22 0.06], ...
    'String', 'BPM: waiting...', ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'EdgeColor', 'none');

fprintf('\nreal-time monitoring started.\n');
fprintf('close the figure or press ctrl+c to stop.\n');

% continuously receive and process readings

last_update = tic;

while true

    % receive sensor reading

    line = readline(s);

    values = sscanf(char(line), '%f,%f,%f');

    if numel(values) ~= 3
        continue;
    end

    % extract timestamp and ir value

    timestamps(end+1,1) = values(1);
    ir_data(end+1,1) = values(3);

    % wait until enough samples are available

    if length(ir_data) < 50
        continue;
    end

    % process the signal periodically

    if toc(last_update) < 0.5
        continue;
    end

    last_update = tic;

    % calculate time and sampling frequency

    time = (timestamps - timestamps(1)) / 1000;

    fs = 1 / mean(diff(time));
    h = 1 / fs;

    % smooth the signal

    filtered_signal = movmean(double(ir_data), 5);

    % calculate numerical derivative

    derivative = zeros(size(filtered_signal));

    derivative(2:end-1) = ...
        (filtered_signal(3:end) - filtered_signal(1:end-2)) / (2*h);

    derivative(1) = ...
        (filtered_signal(2) - filtered_signal(1)) / h;

    derivative(end) = ...
        (filtered_signal(end) - filtered_signal(end-1)) / h;

    % detect pulse peaks

    minimum_height = mean(filtered_signal) + ...
        0.3 * std(filtered_signal);

    [peaks, peak_indices] = findpeaks(filtered_signal, ...
        'MinPeakDistance', minimum_distance, ...
        'MinPeakHeight', minimum_height);

    peak_times = time(peak_indices);

    % calculate heart rate

    if length(peak_times) >= 2

        intervals = diff(peak_times);

        bpm = 60 ./ intervals;

        % use the latest detected heartbeat intervals

        recent_bpm = bpm(max(1, end-4):end);

        average_bpm = mean(recent_bpm);

        bpm_text.String = sprintf('BPM: %.1f', average_bpm);

    else

        bpm_text.String = 'BPM: detecting...';

    end

    % update live signal plot

    subplot(2,1,1);

    set(signal_plot, ...
        'XData', time, ...
        'YData', filtered_signal);

    set(peak_plot, ...
        'XData', peak_times, ...
        'YData', peaks);

    % update derivative plot

    subplot(2,1,2);

    set(derivative_plot, ...
        'XData', time, ...
        'YData', derivative);

    % keep the plots updated

    drawnow limitrate;

end
