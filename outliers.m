Q1 = prctile(ecg, 25);
Q3 = prctile(ecg, 75);
IQR_value = Q3 - Q1;

lower_limit = Q1 - 1.5 * IQR_value;
upper_limit = Q3 + 1.5 * IQR_value;

outlier_indices = ecg < lower_limit | ecg > upper_limit;

fprintf('Q1: %.2f\n', Q1);
fprintf('Q3: %.2f\n', Q3);
fprintf('IQR: %.2f\n', IQR_value);
fprintf('Lower limit: %.2f\n', lower_limit);
fprintf('Upper limit: %.2f\n', upper_limit);
fprintf('Number of outliers: %d\n', sum(outlier_indices));
fprintf('Percentage of outliers: %.4f%%\n', ...
    100 * sum(outlier_indices) / length(ecg));