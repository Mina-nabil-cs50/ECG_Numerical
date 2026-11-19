
clc;
clear;
close all;

% load the recorded sensor data

load('MAX30102_Recording.mat');

% get the ir signal

signal = double(ir_data);

% smooth the signal

filtered_signal = movmean(signal, 5);

% calculate numerical derivative using central difference

h = 1 / fs;

derivative = zeros(size(filtered_signal));

for i = 2:length(filtered_signal)-1

    derivative(i) = ...
        (filtered_signal(i+1) - filtered_signal(i-1)) / (2*h);

end

% detect pulse peaks

[peaks, peak_times] = findpeaks( ...
    filtered_signal, time, ...
    'MinPeakDistance', 0.4, ...
    'MinPeakProminence', 0.3 * std(filtered_signal));

% calculate heart rate

if length(peak_times) >= 2

    intervals = diff(peak_times);

    bpm = 60 ./ intervals;

    average_bpm = mean(bpm);

    fprintf('average heart rate: %.2f BPM\n', average_bpm);

else

    fprintf('not enough pulse peaks detected.\n');

end

% display filtered signal and detected peaks

figure;

plot(time, filtered_signal);
hold on;

plot(peak_times, peaks, 'ro');

title('max30102 pulse detection');
xlabel('time (seconds)');
ylabel('ir reading');

legend('filtered signal', 'detected peaks');
grid on;

% display numerical derivative

figure;

plot(time, derivative);

title('numerical differentiation');
xlabel('time (seconds)');
ylabel('derivative');

grid on;
