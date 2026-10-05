%% Figure 2
% load data
clear;
clc;
script_dir = fileparts(mfilename('fullpath'));
data_dir = fullfile(script_dir, 'data');
load(fullfile(data_dir, 'power_rt2_db_rest.mat'));
for num = 1:15
    powerfast(:,:,num,:)=power{num,1};
    powerslow(:,:,num,:)=power{num,2};
end
for elec = 1:61
    for timepoints = 1:100
        %[h(timepoints), p(timepoints),~] = ttest(squeeze(mean(powerfast(:,elec,2:3,timepoints),3)),squeeze(mean(powerslow(:,elec,2:3,timepoints),3)));
       p(timepoints) = signrank(squeeze(mean(powerfast(:,elec,2:3,timepoints),3)),squeeze(mean(powerslow(:,elec,2:3,timepoints),3)));
    end
    corrected_p = mafdr(p, 'BHFDR', true); 
    p_values(elec, :) = corrected_p;
    for timepoints = 1:100
        if  p_values(elec, timepoints) < 0.05
            h_values(elec,timepoints) = 1;
        else
            h_values(elec,timepoints) = 0;
        end
    end
end

% Figure 2A
data_avg1 = squeeze(mean(mean(powerfast(:,:,:,:),1),2));  % 条件1的平均数据
data_avg2 = squeeze(mean(mean(powerslow(:,:,:,:),1),2));  % 条件2的平均数据
data_avg_diff = data_avg1-data_avg2;

% fast
figure;
imagesc(-1:0.02:1, 2:2:30, data_avg1);  
axis xy
clim([-0.25 0.25]);  
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('fast: Time-Frequency Plot');

% slow
figure
imagesc(-1:0.02:1, 2:2:30, data_avg2); 
axis xy
clim([-0.25 0.25]); 
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('slow: Time-Frequency Plot');

% fast-slow
figure
imagesc(-1:0.02:1, 2:2:30, data_avg_diff); 
axis xy
clim([-0.25 0.25]); 
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('difference: Time-Frequency Plot');

% Figure 2B
eeg_file = fullfile(data_dir, '1.set');
if ~exist(eeg_file, 'file')
    error('Figure 2B/2C require the EEGLAB file: %s', eeg_file);
end
if exist('pop_loadset', 'file') ~= 2 || exist('topoplot', 'file') ~= 2
    error('Figure 2B/2C require EEGLAB on the MATLAB path (pop_loadset and topoplot).');
end
eeg = pop_loadset(eeg_file);
for timepoints = 65:5:85 % 0.3-0.7
    figure
    topoplot(h_values(:,timepoints), eeg.chanlocs, 'electrodes', 'on');
    colorbar; 
end

% Figure 2C
for timepoints = 15:5:25
    figure
    topoplot(h_values(:,timepoints), eeg.chanlocs, 'electrodes', 'on');
    colorbar; 
end

% Figure 2D
elec = 15;
time = linspace(-1, 1, 100);

data_avg1 = squeeze(mean(mean(powerfast(:,elec,2:3,:),1),3));
data_avg2 = squeeze(mean(mean(powerslow(:,elec,2:3,:),1),3));

figure
plot(time, data_avg1, time, data_avg2);
hold on
set(gca, 'TickDir', 'out');

% the significant line
yl = ylim;
yr = diff(yl);
y_sig = yl(2) + 0.08 * yr;
ylim([yl(1), yl(2) + 0.16 * yr]);

edges = [time(1), (time(1:end-1) + time(2:end))/2, time(end)];
sig = h_values(elec,:) == 1;

changes = diff([false, sig, false]);
starts = find(changes == 1);
stops  = find(changes == -1) - 1;

for k = 1:numel(starts)
    plot([edges(starts(k)), edges(stops(k)+1)], ...
         [y_sig, y_sig], 'k-', 'LineWidth', 3, ...
         'HandleVisibility', 'off');
end

xlim([time(1), time(end)]);
xlabel('Time (s)');
ylabel('Power');
legend('Fast', 'Slow', 'Location', 'best');
title('Electrode 15');
hold off

