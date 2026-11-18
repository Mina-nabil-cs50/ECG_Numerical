
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL ROOT FINDING =====\n');

% Select ECG segment
start_time = 2;
end_time = 10;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

t = t(:);
y = y(:);

% Define a continuous, piecewise-linear ECG function
f = @(x) interp1(t, y, x, 'linear');

%% 2. Find a Sign-Change Interval

% Find the first interval where the ECG crosses zero
crossing_index = find(y(1:end-1).*y(2:end) < 0, 1);

if isempty(crossing_index)
    error('No zero crossing found in the selected ECG segment.');
end

a = t(crossing_index);
b = t(crossing_index+1);

fprintf('Selected zero-crossing interval:\n');
fprintf('Lower bound: %.8f seconds\n', a);
fprintf('Upper bound: %.8f seconds\n', b);
fprintf('ECG at lower bound: %.6f\n', f(a));
fprintf('ECG at upper bound: %.6f\n', f(b));

%% 3. Initialize Settings

tolerance = 1e-8;
max_iterations = 50;

%% 4. Initialize Visualizations

% Figure 16: ECG and estimated roots
figure(16);
clf;

plot(t, y, 'b', 'LineWidth', 1.2);
hold on;

yline(0, 'k--');

root_plot = plot(NaN, NaN, 'ro', ...
    'MarkerFaceColor', 'r', ...
    'MarkerSize', 7);

title('ECG Zero Crossing - Root Finding');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');
legend('ECG Signal', 'Zero Baseline', 'Estimated Roots');
grid on;

% Figure 17: Convergence comparison
figure(17);
clf;

bisection_plot = plot(NaN, NaN, 'b-o');
hold on;

false_position_plot = plot(NaN, NaN, 'r-o');

newton_plot = plot(NaN, NaN, 'g-o');

secant_plot = plot(NaN, NaN, 'm-o');

title('Root-Finding Method Convergence');
xlabel('Iteration');
ylabel('Estimated Root (seconds)');

legend('Bisection', 'False Position', ...
       'Newton-Raphson', 'Secant');

grid on;

% Figure 18: Iteration table
figure(18);
clf;

uicontrol('Style', 'text', ...
    'String', { ...
    'ECG ROOT FINDING - ITERATION RESULTS', ...
    'Iteration: Number of calculations performed.', ...
    'Bisection: Root estimate from the midpoint of the interval.', ...
    'False Position: Root estimate using a straight-line intersection.', ...
    'Newton-Raphson: Root estimate using the function and its derivative.', ...
    'Secant: Root estimate using two previous estimates.', ...
    'Function Value: ECG amplitude at the estimated root.', ...
    'Error: Absolute difference between consecutive root estimates.'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.78 0.96 0.21], ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

results_table = uitable( ...
    'Data', zeros(0,10), ...
    'ColumnName', { ...
    'Iteration', ...
    'Bisection', ...
    'False Position', ...
    'Newton', ...
    'Secant', ...
    'Bisection f(x)', ...
    'False Position f(x)', ...
    'Newton f(x)', ...
    'Secant f(x)', ...
    'Bisection Error'}, ...
    'Units', 'normalized', ...
    'Position', [0.02 0.02 0.96 0.74]);

drawnow;

%% 5. Initialize Root-Finding Variables

% Bisection
bis_a = a;
bis_b = b;
bis_previous = NaN;

% False Position
fp_a = a;
fp_b = b;
fp_previous = NaN;

% Newton-Raphson
newton_x = (a+b)/2;

% Secant
secant_x0 = a;
secant_x1 = b;

% Store iteration history
bis_history = [];
fp_history = [];
newton_history = [];
secant_history = [];

% Store table results
table_history = [];

%% 6. Perform Root-Finding Iterations

fprintf('\n===== ROOT-FINDING ITERATIONS =====\n');

fprintf(['Iteration | Bisection | False Position | ' ...
         'Newton | Secant\n']);

fprintf('%s\n', repmat('-',1,85));

for k = 1:max_iterations

    %% A. Bisection Method

    bis_current = (bis_a + bis_b)/2;
    bis_value = f(bis_current);

    if f(bis_a)*bis_value < 0
        bis_b = bis_current;
    else
        bis_a = bis_current;
    end

    if isnan(bis_previous)
        bis_error = NaN;
    else
        bis_error = abs(bis_current-bis_previous);
    end

    bis_previous = bis_current;


    %% B. False Position Method

    fa = f(fp_a);
    fb = f(fp_b);

    fp_current = fp_b - ...
        fb*(fp_b-fp_a)/(fb-fa);

    fp_value = f(fp_current);

    if fa*fp_value < 0
        fp_b = fp_current;
    else
        fp_a = fp_current;
    end

    fp_error = NaN;

    if k > 1
        fp_error = abs(fp_current-fp_previous);
    end

    fp_previous = fp_current;


    %% C. Newton-Raphson Method

    newton_current = newton_x;

    % Numerical derivative of the ECG function
    delta = h/10;

    derivative_value = ...
        (f(newton_x+delta)-f(newton_x-delta))/(2*delta);

    if abs(derivative_value) < 1e-12
        warning('Newton-Raphson stopped: derivative too small.');
        break;
    end

    newton_next = newton_x - ...
        f(newton_x)/derivative_value;

    % Keep Newton estimate inside the selected interval
    if newton_next < a || newton_next > b
        warning('Newton-Raphson stopped: estimate left the interval.');
        break;
    end

    newton_error = abs(newton_next-newton_x);

    newton_x = newton_next;
    newton_current = newton_x;

    newton_value = f(newton_current);


    %% D. Secant Method

    secant_f0 = f(secant_x0);
    secant_f1 = f(secant_x1);

    denominator = secant_f1-secant_f0;

    if abs(denominator) < 1e-12
        warning('Secant method stopped: denominator too small.');
        break;
    end

    secant_next = secant_x1 - ...
        secant_f1*(secant_x1-secant_x0)/denominator;

    secant_error = abs(secant_next-secant_x1);

    secant_x0 = secant_x1;
    secant_x1 = secant_next;

    secant_current = secant_next;
    secant_value = f(secant_current);


    %% E. Store Results

    bis_history(end+1) = bis_current;
    fp_history(end+1) = fp_current;
    newton_history(end+1) = newton_current;
    secant_history(end+1) = secant_current;

    table_history(end+1,:) = [ ...
        k, ...
        bis_current, ...
        fp_current, ...
        newton_current, ...
        secant_current, ...
        bis_value, ...
        fp_value, ...
        newton_value, ...
        secant_value, ...
        bis_error];


    %% F. Update Figure 16

    set(root_plot, ...
        'XData', [bis_current fp_current ...
                  newton_current secant_current], ...
        'YData', [bis_value fp_value ...
                  newton_value secant_value]);


    %% G. Update Figure 17

    set(bisection_plot, ...
        'XData', 1:length(bis_history), ...
        'YData', bis_history);

    set(false_position_plot, ...
        'XData', 1:length(fp_history), ...
        'YData', fp_history);

    set(newton_plot, ...
        'XData', 1:length(newton_history), ...
        'YData', newton_history);

    set(secant_plot, ...
        'XData', 1:length(secant_history), ...
        'YData', secant_history);


    %% H. Update Figure 18

    set(results_table, 'Data', table_history);

    fprintf('%9d | %.8f | %.8f | %.8f | %.8f\n', ...
        k, bis_current, fp_current, ...
        newton_current, secant_current);

    drawnow;


    %% I. Check Convergence

    bis_converged = abs(bis_value) < tolerance;
    fp_converged = abs(fp_value) < tolerance;
    newton_converged = abs(newton_value) < tolerance;
    secant_converged = abs(secant_value) < tolerance;

    if bis_converged && fp_converged && ...
       newton_converged && secant_converged
        break;
    end

end

%% 7. Final Results

fprintf('\n===== FINAL ROOT-FINDING RESULTS =====\n');

fprintf('Bisection Root: %.10f seconds\n', bis_current);
fprintf('Bisection Function Value: %.10f\n', f(bis_current));

fprintf('False Position Root: %.10f seconds\n', fp_current);
fprintf('False Position Function Value: %.10f\n', f(fp_current));

fprintf('Newton-Raphson Root: %.10f seconds\n', newton_current);
fprintf('Newton Function Value: %.10f\n', f(newton_current));

fprintf('Secant Root: %.10f seconds\n', secant_current);
fprintf('Secant Function Value: %.10f\n', f(secant_current));

fprintf('\nTotal iterations performed: %d\n', ...
    length(bis_history));

fprintf('\nRoot-finding demonstration completed.\n');
