
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL CURVE FITTING =====\n');

% Select a short ECG segment
start_time = 2;
end_time = 4;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

t = t(:);
y = y(:);

% Normalize time for numerical stability
x = (t - mean(t)) / (max(t) - min(t));

n = length(x);

fprintf('Number of ECG samples: %d\n', n);
fprintf('Segment duration: %.2f seconds\n', end_time-start_time);

%% 2. Initialize Curve Fitting

% Polynomial degrees
degrees = [1 2 3];

% Store coefficients and fitted values
coefficients = cell(3,1);
fitted_values = zeros(n,3);
errors = zeros(n,3);

%% 3. Initialize Visualizations

% Figure 19: Original ECG and fitted curves
figure(19);
clf;

plot(t, y, 'k', 'LineWidth', 1.2);
hold on;

linear_plot = plot(NaN, NaN, 'r', 'LineWidth', 1.5);
quadratic_plot = plot(NaN, NaN, 'g', 'LineWidth', 1.5);
cubic_plot = plot(NaN, NaN, 'b', 'LineWidth', 1.5);

title('ECG Curve Fitting Comparison');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');

legend('Original ECG', 'Linear Fit', ...
       'Quadratic Fit', 'Cubic Fit');

grid on;


% Figure 20: Fitting errors
figure(20);
clf;

linear_error_plot = plot(NaN, NaN, 'r');
hold on;

quadratic_error_plot = plot(NaN, NaN, 'g');

cubic_error_plot = plot(NaN, NaN, 'b');

title('Curve Fitting Absolute Errors');
xlabel('Time (seconds)');
ylabel('Absolute Error (ADC units)');

legend('Linear', 'Quadratic', 'Cubic');
grid on;


% Figure 21: Iteration table
figure(21);
clf;

uicontrol('Style', 'text', ...
    'String', { ...
    'ECG CURVE FITTING - ITERATION RESULTS', ...
    'Iteration: Number of ECG samples processed.', ...
    'Time (s): Time of the current ECG sample.', ...
    'Actual: Measured ECG amplitude.', ...
    'Linear Fit: Estimated amplitude using a first-degree polynomial.', ...
    'Quadratic Fit: Estimated amplitude using a second-degree polynomial.', ...
    'Cubic Fit: Estimated amplitude using a third-degree polynomial.', ...
    'Errors: Absolute difference between measured and fitted amplitudes.'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.82 0.96 0.17], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

results_table = uitable( ...
    'Data', zeros(0,8), ...
    'ColumnName', { ...
    'Iteration', 'Time (s)', 'Actual', ...
    'Linear Fit', 'Quadratic Fit', 'Cubic Fit', ...
    'Linear Error', 'Quadratic Error'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.78]);

drawnow;

%% 4. Perform Least Squares Curve Fitting

% Construct polynomial design matrices
A1 = [ones(n,1), x];

A2 = [ones(n,1), x, x.^2];

A3 = [ones(n,1), x, x.^2, x.^3];

% Calculate least-squares coefficients
coefficients{1} = A1 \ y;
coefficients{2} = A2 \ y;
coefficients{3} = A3 \ y;

fprintf('\n===== LEAST SQUARES COEFFICIENTS =====\n');

fprintf('\nLinear coefficients:\n');
disp(coefficients{1});

fprintf('Quadratic coefficients:\n');
disp(coefficients{2});

fprintf('Cubic coefficients:\n');
disp(coefficients{3});

%% 5. Calculate Fitted Values Iteratively

playback_clock = tic;

fprintf('\n===== CURVE FITTING ITERATIONS =====\n');

fprintf('%-10s %-12s %-12s %-12s %-12s\n', ...
    'Iteration', 'Actual', 'Linear', 'Quadratic', 'Cubic');

for i = 1:n

    % Evaluate linear polynomial
    fitted_values(i,1) = ...
        polyval(flipud(coefficients{1}), x(i));

    % Evaluate quadratic polynomial
    fitted_values(i,2) = ...
        polyval(flipud(coefficients{2}), x(i));

    % Evaluate cubic polynomial
    fitted_values(i,3) = ...
        polyval(flipud(coefficients{3}), x(i));

    % Calculate absolute errors
    errors(i,:) = abs( ...
        y(i) - fitted_values(i,:));


    %% Update Figure 19

    set(linear_plot, ...
        'XData', t(1:i), ...
        'YData', fitted_values(1:i,1));

    set(quadratic_plot, ...
        'XData', t(1:i), ...
        'YData', fitted_values(1:i,2));

    set(cubic_plot, ...
        'XData', t(1:i), ...
        'YData', fitted_values(1:i,3));


    %% Update Figure 20

    set(linear_error_plot, ...
        'XData', t(1:i), ...
        'YData', errors(1:i,1));

    set(quadratic_error_plot, ...
        'XData', t(1:i), ...
        'YData', errors(1:i,2));

    set(cubic_error_plot, ...
        'XData', t(1:i), ...
        'YData', errors(1:i,3));


    %% Update Figure 21 Every 5 Samples

    if mod(i,5) == 0 || i == n

        table_data = [ ...
            (1:i)', ...
            t(1:i), ...
            y(1:i), ...
            fitted_values(1:i,:), ...
            errors(1:i,1:2)];

        set(results_table, 'Data', table_data);

        fprintf('%-10d %-12.3f %-12.3f %-12.3f %-12.3f\n', ...
            i, y(i), ...
            fitted_values(i,1), ...
            fitted_values(i,2), ...
            fitted_values(i,3));

    end

    drawnow limitrate;

    % Maintain approximately real-time playback
    remaining_time = t(i)-t(1)-toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end

%% 6. Calculate Final Fitting Accuracy

SSE = sum(errors.^2,1);

MSE = mean(errors.^2,1);

RMSE = sqrt(MSE);

MAE = mean(errors,1);

fprintf('\n===== FINAL CURVE FITTING RESULTS =====\n');

fprintf('\nLinear Least Squares:\n');
fprintf('SSE: %.6f\n', SSE(1));
fprintf('MSE: %.6f\n', MSE(1));
fprintf('RMSE: %.6f\n', RMSE(1));
fprintf('MAE: %.6f\n', MAE(1));

fprintf('\nQuadratic Least Squares:\n');
fprintf('SSE: %.6f\n', SSE(2));
fprintf('MSE: %.6f\n', MSE(2));
fprintf('RMSE: %.6f\n', RMSE(2));
fprintf('MAE: %.6f\n', MAE(2));

fprintf('\nCubic Least Squares:\n');
fprintf('SSE: %.6f\n', SSE(3));
fprintf('MSE: %.6f\n', MSE(3));
fprintf('RMSE: %.6f\n', RMSE(3));
fprintf('MAE: %.6f\n', MAE(3));

%% 7. Display Error Comparison

figure(22);
clf;

bar([MAE; RMSE]');

set(gca, 'XTickLabel', ...
    {'Linear', 'Quadratic', 'Cubic'});

ylabel('Error (ADC units)');

legend('MAE', 'RMSE');

title('Curve Fitting Accuracy Comparison');

grid on;

fprintf('\nCurve fitting completed.\n');

