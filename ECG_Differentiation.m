
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL DIFFERENTIATION =====\n');

% Analyze the first 10 seconds
start_time = 0;
end_time = 10;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

% Ensure column vectors
t = t(:);
y = y(:);

h = 1/fs;
n = length(y);

fprintf('Sampling frequency: %.0f Hz\n', fs);
fprintf('Sampling interval: %.6f seconds\n', h);
fprintf('Number of samples: %d\n', n);

%% 2. Initialize Derivative Arrays

forward_derivative = zeros(n,1);
backward_derivative = zeros(n,1);
central_derivative = zeros(n,1);

%% 3. Initialize Visualizations

% Figure 8: ECG and derivative methods
figure(8);
clf;

subplot(2,1,1);

plot(t, y, 'b');
title('Filtered ECG Signal');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;

subplot(2,1,2);

forward_plot = plot(NaN, NaN, 'r');
hold on;

backward_plot = plot(NaN, NaN, 'g');

central_plot = plot(NaN, NaN, 'b');

title('Numerical Derivatives');
xlabel('Time (seconds)');
ylabel('Derivative (ADC units/second)');

legend('Forward Difference', ...
       'Backward Difference', ...
       'Central Difference');

grid on;


% Figure 9: Difference between methods
figure(9);
clf;

comparison_plot = plot(NaN, NaN, 'k', ...
    'LineWidth', 1.3);

title('Forward vs Central Difference');
xlabel('Time (seconds)');
ylabel('Absolute Difference (ADC units/second)');
grid on;


% Figure 10: Iteration table with explanations
figure(10);
clf;

% Explanations above the table
uicontrol('Style', 'text', ...
    'String', { ...
    'ECG NUMERICAL DIFFERENTIATION - ITERATION RESULTS', ...
    'Sample Index: Position of the current ECG measurement.', ...
    'Time (s): Time elapsed since the recording started.', ...
    'Forward: Uses the current and next ECG samples.', ...
    'Backward: Uses the current and previous ECG samples.', ...
    'Central: Uses the previous and next ECG samples.', ...
    'Derivative units: ADC units per second.'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.84 0.96 0.15], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

% Iteration table
results_table = uitable( ...
    'Data', zeros(0,5), ...
    'ColumnName', { ...
    'Sample Index', ...
    'Time (s)', ...
    'Forward (ADC/s)', ...
    'Backward (ADC/s)', ...
    'Central (ADC/s)'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.80]);

drawnow;

%% 4. Perform Numerical Differentiation

playback_clock = tic;

fprintf('\n');
fprintf('%-10s %-12s %-15s %-15s %-15s\n', ...
    'Sample', 'Time', 'Forward', 'Backward', 'Central');

fprintf('%s\n', repmat('-',1,75));

for i = 2:n-1

    % Forward Difference
    forward_derivative(i) = ...
        (y(i+1) - y(i)) / h;

    % Backward Difference
    backward_derivative(i) = ...
        (y(i) - y(i-1)) / h;

    % Central Difference
    central_derivative(i) = ...
        (y(i+1) - y(i-1)) / (2*h);


    %% Update Figure 8

    set(forward_plot, ...
        'XData', t(1:i), ...
        'YData', forward_derivative(1:i));

    set(backward_plot, ...
        'XData', t(1:i), ...
        'YData', backward_derivative(1:i));

    set(central_plot, ...
        'XData', t(1:i), ...
        'YData', central_derivative(1:i));


    %% Update Figure 9

    difference = abs( ...
        forward_derivative(1:i) - ...
        central_derivative(1:i));

    set(comparison_plot, ...
        'XData', t(1:i), ...
        'YData', difference);


    %% Update Figure 10 Every 10 Samples

    if mod(i,10) == 0 || i == n-1

        table_data = [ ...
            (2:i)', ...
            t(2:i), ...
            forward_derivative(2:i), ...
            backward_derivative(2:i), ...
            central_derivative(2:i)];

        set(results_table, 'Data', table_data);

        fprintf('%-10d %-12.4f %-15.3f %-15.3f %-15.3f\n', ...
            i, t(i), ...
            forward_derivative(i), ...
            backward_derivative(i), ...
            central_derivative(i));

    end

    drawnow limitrate;


    %% Maintain Approximately Real-Time Playback

    remaining_time = t(i) - t(1) - toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end

%% 5. Calculate First and Last Sample Derivatives

% Forward difference at the first sample
forward_derivative(1) = ...
    (y(2) - y(1)) / h;

% Backward difference at the last sample
backward_derivative(n) = ...
    (y(n) - y(n-1)) / h;

% Central difference at the endpoints is not available
% because there are not samples on both sides.

%% 6. Final Results

valid_indices = 2:n-1;

forward_central_difference = ...
    mean(abs(forward_derivative(valid_indices) - ...
             central_derivative(valid_indices)));

backward_central_difference = ...
    mean(abs(backward_derivative(valid_indices) - ...
             central_derivative(valid_indices)));

fprintf('\n===== DIFFERENTIATION RESULTS =====\n');

fprintf('Mean Forward-Central Difference: %.4f\n', ...
    forward_central_difference);

fprintf('Mean Backward-Central Difference: %.4f\n', ...
    backward_central_difference);

fprintf('Maximum Central Derivative: %.4f\n', ...
    max(central_derivative(valid_indices)));

fprintf('Minimum Central Derivative: %.4f\n', ...
    min(central_derivative(valid_indices)));

fprintf('\nDifferentiation completed.\n');

%% 7. Final Derivative Comparison

figure(11);
clf;

plot(t, forward_derivative, 'r');
hold on;

plot(t, backward_derivative, 'g');

plot(t, central_derivative, 'b');

title('Final Comparison of Numerical Differentiation Methods');
xlabel('Time (seconds)');
ylabel('Derivative (ADC units/second)');

legend('Forward Difference', ...
       'Backward Difference', ...
       'Central Difference');

grid on;

fprintf('===== END OF DIFFERENTIATION =====\n');
