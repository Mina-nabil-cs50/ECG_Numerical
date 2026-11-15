
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL INTERPOLATION =====\n');

% Select a short ECG segment
start_time = 2;
end_time = 2.2;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

t = t(:);
y = y(:);

% Select every fourth sample as known data
known_indices = 1:4:length(t);

% Ensure the final sample is included
if known_indices(end) ~= length(t)
    known_indices(end+1) = length(t);
end

known_t = t(known_indices);
known_y = y(known_indices);

% Points to estimate
missing_indices = setdiff(1:length(t), known_indices);

test_t = t(missing_indices);
actual_y = y(missing_indices);

fprintf('Original samples: %d\n', length(t));
fprintf('Known samples: %d\n', length(known_t));
fprintf('Estimated samples: %d\n', length(test_t));

%% 2. Initialize Interpolation Results

linear_y = zeros(size(test_t));
lagrange_y = zeros(size(test_t));
newton_y = zeros(size(test_t));

%% 3. Initialize Visualizations

% Figure 12: ECG interpolation comparison
figure(12);
clf;

plot(t, y, 'k-', 'LineWidth', 1.2);
hold on;

plot(known_t, known_y, 'bo', ...
    'MarkerFaceColor', 'b');

linear_plot = plot(NaN, NaN, 'r.');
lagrange_plot = plot(NaN, NaN, 'g.');
newton_plot = plot(NaN, NaN, 'm.');

title('ECG Signal - Numerical Interpolation');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');

legend('Original ECG', 'Known Samples', ...
       'Linear', 'Lagrange', 'Newton');

grid on;


% Figure 13: Interpolation error
figure(13);
clf;

linear_error_plot = plot(NaN, NaN, 'r');
hold on;

lagrange_error_plot = plot(NaN, NaN, 'g');

newton_error_plot = plot(NaN, NaN, 'm');

title('Interpolation Absolute Error');
xlabel('Time (seconds)');
ylabel('Absolute Error (ADC units)');

legend('Linear', 'Lagrange', 'Newton');
grid on;


% Figure 14: Iteration table
figure(14);
clf;

uicontrol('Style', 'text', ...
    'String', { ...
    'ECG NUMERICAL INTERPOLATION - ITERATION RESULTS', ...
    'Iteration: Number of missing points estimated.', ...
    'Time (s): Time location of the estimated ECG sample.', ...
    'Actual: Original ECG amplitude at that location.', ...
    'Linear: Amplitude estimated using linear interpolation.', ...
    'Lagrange: Amplitude estimated using Lagrange interpolation.', ...
    'Newton: Amplitude estimated using Newton interpolation.', ...
    'Errors: Absolute difference between estimated and original amplitudes.'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.82 0.96 0.17], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

results_table = uitable( ...
    'Data', zeros(0,8), ...
    'ColumnName', { ...
    'Iteration', 'Time (s)', 'Actual', ...
    'Linear', 'Lagrange', 'Newton', ...
    'Linear Error', 'Lagrange Error'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.78]);

drawnow;

%% 4. Calculate Interpolation Iterations

% Newton divided-difference coefficients
m = length(known_t);

divided = known_y;

for j = 2:m
    for i = m:-1:j
        divided(i) = ...
            (divided(i) - divided(i-1)) / ...
            (known_t(i) - known_t(i-j+1));
    end
end

fprintf('\n===== NEWTON DIVIDED DIFFERENCES =====\n');

for i = 1:m
    fprintf('Coefficient %d: %.8f\n', i, divided(i));
end

fprintf('\n===== INTERPOLATION ITERATIONS =====\n');

for k = 1:length(test_t)

    x = test_t(k);

    %% Linear Interpolation

    left_index = find(known_t < x, 1, 'last');
    right_index = find(known_t > x, 1, 'first');

    if isempty(left_index)
        left_index = 1;
    end

    if isempty(right_index)
        right_index = m;
    end

    x0 = known_t(left_index);
    x1 = known_t(right_index);

    y0 = known_y(left_index);
    y1 = known_y(right_index);

    linear_y(k) = y0 + ...
        ((x-x0)/(x1-x0))*(y1-y0);


    %% Lagrange Interpolation

    lagrange_value = 0;

    for i = 1:m

        basis = 1;

        for j = 1:m
            if i ~= j
                basis = basis * ...
                    (x-known_t(j))/(known_t(i)-known_t(j));
            end
        end

        lagrange_value = lagrange_value + ...
            known_y(i)*basis;

    end

    lagrange_y(k) = lagrange_value;


    %% Newton Interpolation

    newton_value = divided(m);

    for i = m-1:-1:1
        newton_value = ...
            divided(i) + (x-known_t(i))*newton_value;
    end

    newton_y(k) = newton_value;


    %% Update Results

    % Update interpolation graph
    set(linear_plot, ...
        'XData', test_t(1:k), ...
        'YData', linear_y(1:k));

    set(lagrange_plot, ...
        'XData', test_t(1:k), ...
        'YData', lagrange_y(1:k));

    set(newton_plot, ...
        'XData', test_t(1:k), ...
        'YData', newton_y(1:k));


    % Calculate absolute errors
    linear_error = abs(linear_y(k)-actual_y(k));
    lagrange_error = abs(lagrange_y(k)-actual_y(k));
    newton_error = abs(newton_y(k)-actual_y(k));

    set(linear_error_plot, ...
        'XData', test_t(1:k), ...
        'YData', abs(linear_y(1:k)-actual_y(1:k)));

    set(lagrange_error_plot, ...
        'XData', test_t(1:k), ...
        'YData', abs(lagrange_y(1:k)-actual_y(1:k)));

    set(newton_error_plot, ...
        'XData', test_t(1:k), ...
        'YData', abs(newton_y(1:k)-actual_y(1:k)));


    % Update iteration table
    if mod(k,5) == 0 || k == length(test_t)

        table_data = [ ...
            (1:k)', ...
            test_t(1:k), ...
            actual_y(1:k), ...
            linear_y(1:k), ...
            lagrange_y(1:k), ...
            newton_y(1:k), ...
            abs(linear_y(1:k)-actual_y(1:k)), ...
            abs(lagrange_y(1:k)-actual_y(1:k))];

        set(results_table, 'Data', table_data);

        fprintf('Iteration %d | Time %.6f | Actual %.4f | Linear %.4f | Lagrange %.4f | Newton %.4f\n', ...
            k, x, actual_y(k), linear_y(k), ...
            lagrange_y(k), newton_y(k));

    end

    drawnow;

end

%% 5. Final Interpolation Results

linear_mae = mean(abs(linear_y-actual_y));
lagrange_mae = mean(abs(lagrange_y-actual_y));
newton_mae = mean(abs(newton_y-actual_y));

fprintf('\n===== FINAL INTERPOLATION RESULTS =====\n');

fprintf('Linear Mean Absolute Error: %.8f\n', linear_mae);
fprintf('Lagrange Mean Absolute Error: %.8f\n', lagrange_mae);
fprintf('Newton Mean Absolute Error: %.8f\n', newton_mae);

%% 6. Display Final Error Comparison

figure(15);
clf;

bar([linear_mae, lagrange_mae, newton_mae]);

set(gca, 'XTickLabel', ...
    {'Linear', 'Lagrange', 'Newton'});

ylabel('Mean Absolute Error (ADC units)');
title('Interpolation Method Accuracy');

grid on;

fprintf('\nInterpolation completed.\n');
