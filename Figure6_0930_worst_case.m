%% experiment data
clear; close all; clc;
% date_list = [0929, 1003, 1015, 1016];
date_list = [0930];
date_idx = 1;

for date = date_list
    %%
    if date == 0929
        stim_start = 2450;
        OAB_start = 1676;
        stim_duration = 1200;
        skip_thres = 100;
        OAB_standard = 200;
    elseif date == 0930
        OAB_start = 1512;
        stim_start = 2090;    
        stim_duration = 1200;
        skip_thres = 50;
        OAB_standard = 200;
    elseif date == 1003
        stim_start = 3016;
        OAB_start = 1936;
        stim_duration = 1200+500;
        skip_thres = 100;
        OAB_standard = 200;
    elseif date == 1015
        stim_start = 3629;
        OAB_start = 2019;
        stim_duration = 2250;
        skip_thres = 110;
        OAB_standard = 220;
    elseif date == 1016
        stim_start = 3316;
        OAB_start = 2752;
        stim_duration = 1200+1000;
        OAB_standard = 230;
        skip_thres = 120;
    end

    %% Load bladder data
    cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\CL_DATA'
    file_name = strcat('25', num2str(date, '%04d'),'_CL_success.mat');
    load(file_name);
    
    Bladder.raw{date_idx} = double(b1(:,2)); 
    % clear b1 m000
    
    % Bladder filtering
    if date == 1016
        fc_slope = 0.007; % 0.2
    else
        fc_slope = 0.007; % 0.2 for plotting,  0.007 for interval
    end
    % fc_slope = 0.2;
    fs = 100;
    [b, a] = butter(2, fc_slope/(fs/2));
    Bladder.filt{date_idx} = filtfilt(b, a, Bladder.raw{date_idx});
    Bladder.filt_down{date_idx} = downsample(Bladder.filt{date_idx},100,1);  % 1 Hz 
    
    if date == 0929
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(1:5000);
    elseif date == 1015
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(1:7950);
    elseif date == 1016
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(1:9000);
    end

    fig2 = figure(date_idx); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 15 14 2.5]);
    plot(Bladder.filt_down{date_idx},'r','LineWidth', 1.2)
    
    ylabel('IBP (mmHg)')
    xlabel('Time (s)')
    axis tight;
    % ylim([30 90])
    
    set(findall(gcf,'-property','FontName'),'FontName','Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize', 7);
    box off;

    BP = movmean(Bladder.filt_down{date_idx}, 5);

    % Normal
    [pks, locs_normal] = findpeaks(BP(1:OAB_start),'MinPeakDistance', skip_thres);
    if date == 1016
        locs_normal = [39 339 902 1324 1568 2004 2689];
    end
    
    % Before stim
    [pks, locs_OAB] = findpeaks(BP(OAB_start:stim_start),'MinPeakDistance', skip_thres);
    % xline(locs_OAB +OAB_start,'r:');

    if date == 1016
        locs_OAB = [2907, 3029, 3193, 3278];
    elseif date == 0930
        locs_OAB = [1630, 1802, 1930, 2113];
    end

    % After stim
    [pks, locs_TNS] = findpeaks(BP(stim_start+stim_duration:end),'MinPeakDistance', skip_thres);
    % xline(locs_TNS+stim_start+stim_duration,'k:');

    Normal{date_idx} = diff(locs_normal);
    OAB{date_idx} = diff(locs_OAB);
    TNS{date_idx} = diff(locs_TNS);
    
    Normal_norm{date_idx} = diff(locs_normal)/OAB_standard;
    OAB_norm{date_idx} = diff(locs_OAB)/OAB_standard;
    TNS_norm{date_idx} = diff(locs_TNS)/OAB_standard;
    
    id_time(date_idx) = stim_start-OAB_start;
    

    %% Load pupil data    
    date_str = num2str(date, '%04d');
    pupil_file = strcat('2025-',[date_str(1:2) '-' date_str(3:4)],'_video_success_pupil_area.csv');
    pupil = readtable(pupil_file);
    Pupil.raw{date_idx} = pupil.FilteredArea; 
    time = 1:length(Pupil.raw{date_idx});
    
    % pupil filtering
    fc_slope = 0.05; % 0.2
    fs = 10;
    [b, a] = butter(2, fc_slope/(fs/2));
    Pupil.filt{date_idx} = filtfilt(b, a, Pupil.raw{date_idx});
    Pupil.filt_down{date_idx} = downsample(Pupil.filt{date_idx},10,1);  % 1 Hz 
    
    if date == 0929
        Pupil.filt_down{date_idx} = Pupil.filt_down{date_idx}(1:5000);
    end
    
    plot_pupil = movmean(Pupil.filt_down{date_idx}, 6);

    fig2 = figure(date_idx+100); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 9 14 2.5]);
    plot(plot_pupil, 'k', 'linewidth', 1.2);
    axis tight
    ylim([0, 600])

    
    ylabel('Pupil size')
    xlabel('time (s)')
    set(findall(gcf,'-property','FontName'),['F' ...
        'ontName'],'Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize', 7);
    box off;

    % xline(stim_start, 'r--', 'linewidth', 1.2)
    
    if date == 0929
        ylim([0, 600])
    elseif date == 0930
        ylim([0, 3000])  
    elseif date == 1003  
        ylim([0, 3500])
    end
    
    date_idx = date_idx+1;
end 
 
%% Individual date representation
for i = 1:length(date_list)
    group = [repmat({'Norm.'}, length(Normal{i}), 1);
         repmat({'OAB'}, length(OAB{i}), 1);
         repmat({'tTNS'}, length(TNS{i}), 1)];
    
    % 데이터 합치기
    data_all = [Normal{i}(:); OAB{i}(:); TNS{i}(:)];
    
    % 박스플롯 그리기
    fig2 = figure(i+200); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5+(i-1)*5 7 4 6]); 
    boxplot(data_all, group); hold on;

    x_positions = [1, 2, 3];

    % jitter 설정 (좌우로 퍼지는 정도)
    jitterAmount = 0.05;
    
    % --- 데이터 그룹별로 Outlier 필터링 및 Scatter 플롯 ---
    datasets = {Normal{i}, OAB{i}, TNS{i}};
    
    for j = 1:3
        current_data = datasets{j}(:);
        
        % IQR 기반 Outlier 계산
        q1 = prctile(current_data, 25);
        q3 = prctile(current_data, 75);
        iqr_val = q3 - q1;
        
        low_bound = q1 - 1.5 * iqr_val;
        up_bound = q3 + 1.5 * iqr_val;
        
        % Outlier가 아닌 데이터만 선택
        is_inlier = (current_data >= low_bound) & (current_data <= up_bound);
        inlier_data = current_data(is_inlier);
        
        % Scatter 점 찍기 (Inlier 데이터에 대해서만 jitter 적용)
        x_jitter = x_positions(j) + (rand(size(inlier_data)) - 0.5) * 2 * jitterAmount;
        scatter(x_jitter, inlier_data, 8, ...
            'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
    end

    % 옵션 꾸미기
    ylabel('Inter-micturition interval (s)');
    % title('Interval Comparison');
    set(gca, 'FontSize', 7);
    yline(200, 'k:')
    
    % 각 그룹별 중간값 계산
    med1 = median(Normal{i});
    med2 = median(OAB{i});
    med3 = median(TNS{i});
    
    % 출력
    disp(['Normal median: ', num2str(med1)]);
    disp(['OAB Before median: ', num2str(med2)]);
    disp(['TNS median: ', num2str(med3)]);
    disp(['Id Time: ', num2str(id_time(i))]);
    disp(' ')

    box off;
end

%% id_time 변수에 대한 Boxplot + Scatter Plot
fig_id = figure(99); clf(fig_id);
set(fig_id, 'Units', 'centimeters', 'Position', [5 5 3 4]);

% 1) Boxplot 그리기 (박스 폭 설정)
boxWidth = 0.3;  % 기본값은 약 0.5~0.6 정도
boxplot(id_time, 'Widths', boxWidth);
hold on;

% 2) Scatter plot (jitter 적용)
nPoints = numel(id_time);
x_center = 1;              % boxplot의 그룹 x좌표 (id_time은 단일 그룹)
jitterAmount = 0.05;        % 점 좌우 퍼짐 정도
x_jitter = x_center + (rand(nPoints,1)-0.5)*2*jitterAmount;

scatter(x_jitter, id_time, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 3) 옵션 꾸미기
xlim([0.5 1.5]);
xticks(1);
xticklabels({'CL-tTNS'});
ylabel('OAB Detection time (s)');
set(gca, 'FontSize', 8);

hold off;
box off;
ylim([400, 2000])

%% data summary
total = struct;
for i = 1:length(date_list)
    % 데이터 합치기
    total.norm(i,1) = median(Normal{i});
    total.oab(i,1)  = median(OAB{i});
    total.tns(i,1)  = median(TNS{i});
end

% --- 박스플롯 + 산점도(jittered scatter) 출력 코드 ---
figure; clf;
set(gcf, 'Units', 'centimeters', 'Position', [5 6 5 4]);

% 그룹 이름
groupNames = {'Norm.', 'OAB', 'CL-tTNS'};

% 박스플롯용 데이터 구성
data_all = [total.norm(:); total.oab(:); total.tns(:)];
group = [ ...
    repmat({'Normal'}, length(total.norm), 1);
    repmat({'OAB'},    length(total.oab), 1);
    repmat({'TNS'},    length(total.tns), 1)];

% 박스플롯 그리기
boxplot(data_all, group, 'Labels', groupNames, ...
    'Symbol', '', 'Widths', 0.6);
hold on;

% x 위치 설정
x_positions = [1, 2, 3];

% jitter 설정 (좌우로 퍼지는 정도)
jitterAmount = 0.05;

% 각 그룹별로 점 찍기
x_norm = x_positions(1) + (rand(size(total.norm)) - 0.5) * 2 * jitterAmount;
scatter(x_norm, total.norm, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

x_oab = x_positions(2) + (rand(size(total.oab)) - 0.5) * 2 * jitterAmount;
scatter(x_oab, total.oab, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

x_tns = x_positions(3) + (rand(size(total.tns)) - 0.5) * 2 * jitterAmount;
scatter(x_tns, total.tns, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

% 옵션 꾸미기
ylabel('Mic. Interval (s)');
set(gca, 'FontSize', 8, 'Box', 'off');
yline(200, 'k:', 'LineWidth', 0.6);
box off;

% 두 그룹 데이터 (같은 길이여야 함)
x = total.oab(:);
y = total.tns(:);

% NaN 제거 (혹시 모를 결측값 대비)
validIdx = ~(isnan(x) | isnan(y));
x = x(validIdx);
y = y(validIdx);

% Wilcoxon signed-rank test
[p, h, stats] = signrank(x, y);

% 결과 출력
fprintf('Wilcoxon signed-rank test:\n');
fprintf('p-value = %.4f\n', p);
fprintf('Test decision (h) = %d\n', h);
fprintf('Signed-rank statistic = %.4f\n', stats.signedrank);


%% Normalized Total_data

total = struct;
for i = 1:length(date_list)
    % 데이터 합치기
    total.norm(i,1) = median(Normal_norm{i});
    total.oab(i,1)  = median(OAB_norm{i});
    total.tns(i,1)  = median(TNS_norm{i});
end

% --- 박스플롯 + 산점도(jittered scatter) 출력 코드 ---
figure; clf;
set(gcf, 'Units', 'centimeters', 'Position', [5 6 5 6]);

% 그룹 이름
groupNames = {'Norm.', 'OAB', 'CL-tTNS'};

% 박스플롯용 데이터 구성
data_all = [total.norm(:); total.oab(:); total.tns(:)];
group = [ ...
    repmat({'Normal'}, length(total.norm), 1);
    repmat({'OAB'},    length(total.oab), 1);
    repmat({'TNS'},    length(total.tns), 1)];

% 박스플롯 그리기
boxplot(data_all, group, 'Labels', groupNames, ...
    'Symbol', '', 'Widths', 0.6);
hold on;
yline(1,'k:');

% x 위치 설정
x_positions = [1, 2, 3];

% jitter 설정 (좌우로 퍼지는 정도)
jitterAmount = 0.05;

% 각 그룹별로 점 찍기
x_norm = x_positions(1) + (rand(size(total.norm)) - 0.5) * 2 * jitterAmount;
scatter(x_norm, total.norm, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

x_oab = x_positions(2) + (rand(size(total.oab)) - 0.5) * 2 * jitterAmount;
scatter(x_oab, total.oab, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

x_tns = x_positions(3) + (rand(size(total.tns)) - 0.5) * 2 * jitterAmount;
scatter(x_tns, total.tns, 10, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', ...
    'MarkerFaceAlpha', 1, 'LineWidth', 0.6);

% 옵션 꾸미기
ylabel('Norm. Mic. Interval (a.u.)');
set(gca, 'FontSize', 8, 'Box', 'off');
yline(200, 'k:', 'LineWidth', 0.6);
box off;

% 두 그룹 데이터 (같은 길이여야 함)
x = total.oab(:);
y = total.tns(:);

% NaN 제거 (혹시 모를 결측값 대비)
validIdx = ~(isnan(x) | isnan(y));
x = x(validIdx);
y = y(validIdx);

% Wilcoxon signed-rank test
[p, h, stats] = signrank(x, y);

% 결과 출력
fprintf('Wilcoxon signed-rank test:\n');
fprintf('p-value = %.4f\n', p);
fprintf('Test decision (h) = %d\n', h);
fprintf('Signed-rank statistic = %.4f\n', stats.signedrank);