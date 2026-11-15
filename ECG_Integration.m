
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL INTEGRATION =====\n');

% Analyze the first 10 seconds
start_time = 0;
end_time = 10;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

% Simpson's 1/3 Rule requires an even number of intervals
if mod(length(t)-1, 2) ~= 0
    t = t(1:end-1);
    y = y(1:end-1);
end

h = t(2) - t(1);
n = length(y) - 1;

fprintf('Sampling interval: %.6f seconds\n', h);
fprintf('Number of samples: %d\n', length(y));
fprintf('Number of intervals: %d\n', n);

%% 2. Initialize Numerical Methods

trapezoidal_area = 0;
simpson_area = 0;

iteration = [];
iteration_time = [];
trapezoidal_history = [];
simpson_history = [];

%% 3. Initialize Live Visualization

figure(5);

subplot(2,1,1);

ecg_plot = plot(t, y, 'b');
hold on;

area_plot = patch( ...
    [t(1) t(1) t(1)], ...
    [0 0 0], ...
    [0.2 0.7 0.9], ...
    'FaceAlpha', 0.3, ...
    'EdgeColor', 'none');

yline(0, 'k--');

title('ECG Signal - Numerical Integration');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
grid on;

legend('ECG Signal', 'Accumulated Signed Area', 'Zero Reference');

subplot(2,1,2);

result_text = text(0.05, 0.75, '', ...
    'FontSize', 11, ...
    'Units', 'normalized');

axis off;

title('Live Numerical Integration Results');

%% 4. Perform Integration Iterations

fprintf('\n');
fprintf('%-12s %-15s %-22s %-22s\n', ...
    'Iteration', 'Time (s)', 'Trapezoidal Area', 'Simpson Area');

fprintf('%s\n', repmat('-', 1, 75));

playback_clock = tic;

for i = 1:2:n

    % Current three samples
    x0 = y(i);
    x1 = y(i+1);
    x2 = y(i+2);

    % Trapezoidal Rule: two consecutive trapezoids
    trapezoid_1 = (h/2) * (x0 + x1);
    trapezoid_2 = (h/2) * (x1 + x2);

    trapezoidal_area = trapezoidal_area + ...
        trapezoid_1 + trapezoid_2;

    % Simpson's 1/3 Rule
    simpson_iteration = (h/3) * (x0 + 4*x1 + x2);

    simpson_area = simpson_area + simpson_iteration;

    % Save iteration results
    iteration(end+1) = (i+1)/2;
    iteration_time(end+1) = t(i+2);

    trapezoidal_history(end+1) = trapezoidal_area;
    simpson_history(end+1) = simpson_area;

    % Print current iteration
    fprintf('%-12d %-15.4f %-22.6f %-22.6f\n', ...
        iteration(end), ...
        iteration_time(end), ...
        trapezoidal_area, ...
        simpson_area);

    % Update shaded signed area
    current_t = t(1:i+2);
    current_y = y(1:i+2);

    set(area_plot, ...
        'XData', [current_t; flipud(current_t)], ...
        'YData', [current_y; zeros(length(current_y),1)]);

    % Update live numerical results
    set(result_text, 'String', sprintf([ ...
        'Iteration: %d\n\n' ...
        'Time: %.4f seconds\n\n' ...
        'Trapezoidal Rule:\n%.6f ADC units * seconds\n\n' ...
        'Simpson''s 1/3 Rule:\n%.6f ADC units * seconds'], ...
        iteration(end), ...
        iteration_time(end), ...
        trapezoidal_area, ...
        simpson_area));

    drawnow;

    % Maintain approximately original ECG playback speed
    remaining_time = iteration_time(end) - toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end

%% 5. Final Results

fprintf('\n===== FINAL INTEGRATION RESULTS =====\n');

fprintf('Trapezoidal Rule: %.6f ADC units * seconds\n', ...
    trapezoidal_area);

fprintf('Simpson''s 1/3 Rule: %.6f ADC units * seconds\n', ...
    simpson_area);

fprintf('Total iterations: %d\n', length(iteration));

fprintf('===== INTEGRATION COMPLETED =====\n');

%% 6. Plot Convergence of Both Methods

figure(6);

plot(iteration_time, trapezoidal_history, 'b', ...
    'LineWidth', 1.2);

hold on;

plot(iteration_time, simpson_history, 'r', ...
    'LineWidth', 1.2);

title('Numerical Integration - Accumulated Area');
xlabel('Time (seconds)');
ylabel('Accumulated Signed Area (ADC units * seconds)');

legend('Trapezoidal Rule', 'Simpson''s 1/3 Rule');
grid on;

% Figure 7: Iteration table with column explanations
figure(7);
clf;

% Explanatory text above the table
uicontrol('Style', 'text', ...
    'String', { ...
    'ECG NUMERICAL INTEGRATION - ITERATION RESULTS', ...
    'Iteration: Number of integration steps completed.', ...
    'Time (s): End time of the ECG segment processed so far.', ...
    'Trapezoidal Area: Accumulated area using the Trapezoidal Rule.', ...
    'Simpson Area: Accumulated area using Simpson''s 1/3 Rule.', ...
    'Both area values are signed and expressed in ADC units * seconds.', ...
    'Each iteration processes two intervals using three consecutive samples.'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.84 0.96 0.15], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

% Iteration table
results_table = uitable( ...
    'Data', zeros(0,4), ...
    'ColumnName', { ...
    'Iteration', ...
    'Time (s)', ...
    'Trapezoidal Area (ADC*s)', ...
    'Simpson Area (ADC*s)'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.80]);

drawnow;