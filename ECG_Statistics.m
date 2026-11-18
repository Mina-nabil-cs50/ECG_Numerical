
clc;
clear;
close all;

%% 1. Load ECG Data

load('ECG_Processed_Data.mat');

fprintf('\n===== ECG NUMERICAL STATISTICS =====\n');

% Select first 10 seconds
start_time = 0;
end_time = 10;

indices = find(time >= start_time & time <= end_time);

t = time(indices);
y = ecg_filtered(indices);

t = t(:);
y = y(:);

n = length(y);

fprintf('Number of samples: %d\n', n);
fprintf('Sampling frequency: %.0f Hz\n', fs);
fprintf('Segment duration: %.2f seconds\n', end_time-start_time);

%% 2. Initialize Statistical Variables

% Running statistics
running_mean = zeros(n,1);
running_variance = zeros(n,1);
running_std = zeros(n,1);
running_rms = zeros(n,1);

running_min = zeros(n,1);
running_max = zeros(n,1);

% Running sums for numerical calculations
sum_values = 0;
sum_squares = 0;

current_min = inf;
current_max = -inf;

%% 3. Initialize Figures

% Figure 23: ECG signal and running mean
figure(23);
clf;

subplot(2,1,1);

plot(t,y,'k');
hold on;

mean_plot = plot(NaN,NaN,'r','LineWidth',1.5);

title('ECG Signal and Running Mean');
xlabel('Time (seconds)');
ylabel('Amplitude (ADC units)');

legend('ECG Signal','Running Mean');
grid on;


% Figure 24: Running variance and standard deviation
figure(24);
clf;

subplot(2,1,1);

variance_plot = plot(NaN,NaN,'b','LineWidth',1.5);

title('Running Variance');
xlabel('Time (seconds)');
ylabel('Variance');

grid on;

subplot(2,1,2);

std_plot = plot(NaN,NaN,'r','LineWidth',1.5);

title('Running Standard Deviation');
xlabel('Time (seconds)');
ylabel('Standard Deviation');

grid on;


% Figure 25: Running RMS
figure(25);
clf;

rms_plot = plot(NaN,NaN,'g','LineWidth',1.5);

title('Running Root Mean Square');
xlabel('Time (seconds)');
ylabel('RMS (ADC units)');

grid on;


% Figure 26: Statistical iteration table
figure(26);
clf;

uicontrol('Style','text', ...
    'String',{ ...
    'ECG STATISTICS - ITERATION RESULTS', ...
    'Iteration: Number of samples processed.', ...
    'Time: Time corresponding to the latest processed sample.', ...
    'Mean: Average amplitude of all processed samples.', ...
    'Variance: Average squared deviation from the running mean.', ...
    'Standard Deviation: Square root of the variance.', ...
    'RMS: Square root of the average squared amplitude.', ...
    'Minimum and Maximum: Lowest and highest processed amplitudes.'}, ...
    'Units','normalized', ...
    'Position',[0.02 0.82 0.96 0.17], ...
    'HorizontalAlignment','left', ...
    'FontSize',10);

results_table = uitable( ...
    'Data',zeros(0,7), ...
    'ColumnName',{ ...
    'Iteration', ...
    'Time (s)', ...
    'Mean', ...
    'Variance', ...
    'Std Dev', ...
    'RMS', ...
    'Minimum'}, ...
    'Units','normalized', ...
    'Position',[0.02 0.02 0.96 0.78]);

drawnow;

%% 4. Calculate Statistics Iteratively

fprintf('\n===== STATISTICAL ITERATIONS =====\n');

fprintf('%-10s %-12s %-12s %-12s\n', ...
    'Iteration','Mean','Std Dev','RMS');

playback_clock = tic;

for i = 1:n

    % Update sums
    sum_values = sum_values + y(i);
    sum_squares = sum_squares + y(i)^2;

    % Update minimum and maximum
    current_min = min(current_min,y(i));
    current_max = max(current_max,y(i));

    % Calculate running mean
    running_mean(i) = sum_values/i;

    % Calculate running variance
    if i > 1
        running_variance(i) = ...
            sum((y(1:i)-running_mean(i)).^2)/i;
    else
        running_variance(i) = 0;
    end

    % Calculate standard deviation
    running_std(i) = sqrt(running_variance(i));

    % Calculate RMS
    running_rms(i) = sqrt(sum_squares/i);

    % Store running minimum and maximum
    running_min(i) = current_min;
    running_max(i) = current_max;


    %% Update Figure 23

    set(mean_plot, ...
        'XData',t(1:i), ...
        'YData',running_mean(1:i));


    %% Update Figure 24

    set(variance_plot, ...
        'XData',t(1:i), ...
        'YData',running_variance(1:i));

    set(std_plot, ...
        'XData',t(1:i), ...
        'YData',running_std(1:i));


    %% Update Figure 25

    set(rms_plot, ...
        'XData',t(1:i), ...
        'YData',running_rms(1:i));


    %% Update Table Every 10 Samples

    if mod(i,10) == 0 || i == n

        table_data = [ ...
            (1:i)', ...
            t(1:i), ...
            running_mean(1:i), ...
            running_variance(1:i), ...
            running_std(1:i), ...
            running_rms(1:i), ...
            running_min(1:i)];

        set(results_table,'Data',table_data);

        fprintf('%-10d %-12.3f %-12.3f %-12.3f\n', ...
            i, ...
            running_mean(i), ...
            running_std(i), ...
            running_rms(i));

    end

    drawnow limitrate;

    % Maintain approximately real-time playback
    remaining_time = t(i)-t(1)-toc(playback_clock);

    if remaining_time > 0
        pause(remaining_time);
    end

end

%% 5. Calculate Final Statistics

final_mean = mean(y);
final_median = median(y);
final_variance = var(y,1);
final_std = std(y,1);
final_rms = sqrt(mean(y.^2));

final_min = min(y);
final_max = max(y);

peak_to_peak = final_max-final_min;

%% 6. Display Final Results

fprintf('\n===== FINAL ECG STATISTICS =====\n');

fprintf('Mean: %.6f\n',final_mean);
fprintf('Median: %.6f\n',final_median);
fprintf('Variance: %.6f\n',final_variance);
fprintf('Standard Deviation: %.6f\n',final_std);
fprintf('RMS: %.6f\n',final_rms);
fprintf('Minimum: %.6f\n',final_min);
fprintf('Maximum: %.6f\n',final_max);
fprintf('Peak-to-Peak Amplitude: %.6f\n',peak_to_peak);

%% 7. Display Final Statistical Summary

figure(27);
clf;

values = [ ...
    final_mean, ...
    final_median, ...
    final_variance, ...
    final_std, ...
    final_rms, ...
    final_min, ...
    final_max, ...
    peak_to_peak];

bar(values);

set(gca,'XTick',1:8);

set(gca,'XTickLabel',{ ...
    'Mean','Median','Variance','Std Dev', ...
    'RMS','Minimum','Maximum','Peak-to-Peak'});

xtickangle(30);

ylabel('Value');

title('Final ECG Statistical Summary');

grid on;

fprintf('\nStatistical analysis completed.\n');
