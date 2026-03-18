%% Figure 5. a-e
% tTNS vs Normal 개체별 데이터 비교 수행.
% 효과의 비교를 위하여 개체에서 얻은 치료 효과는 평균값을 낸다.

%% Micturition에 대한 tTNS의 효과를 검증하기 위함
close all; clc; clear;
% cd C:\Users\Mingeun\Desktop\Bladder
cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB'
addpath('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\Codes\function');
date_list = [0721 0722 0723 0806 0812 0819]; % tTNS 데이터 현재 5개 확보
% date_list = [0723]; % TNS 데이턴데 확인해보니 TNS 데이터가 몇개 없다.

fs = 100;

date_idx = 1;
exp_idx = 1;
for date = date_list
    pathname = strcat('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\25', num2str(date, '%04d'),'_test');
    cd(pathname);

    if date == 0721
        exp_list = [2,4];
    elseif date == 0722
        exp_list = [3,4];
    elseif date == 0723
        exp_list = [1,2];
    elseif date == 0728
        exp_list = [2,3];
    elseif date == 0806
        exp_list = [2,3];
    elseif date == 0812
        exp_list = [3,4];
    elseif date == 0819
        exp_list = [2,3];
    %%%%% 이하 invasive stim %%%%%
    elseif date == 0714
        exp_list = [1, 2];
    end
    
    trial_idx = 1;
    for exp_num = exp_list
        bladder_file = strcat('25', num2str(date, '%04d'),'_OAB_',num2str(exp_num),'.mat');
        load(bladder_file);

        if date == 0722 && exp_num == 4
            b1 = b2(120000:545000,:);
        elseif date == 0819 && exp_num == 2
            b1 = b2(140000:320000,:);
        elseif date == 0806 && exp_num == 3
            b1 = b1(1:480000,:);
        end
        gap = 120;
        
        % information
        raw_pressure = double(b1(:,2));
        timestamp = double(b1(:,1));
        sampling_rate = 100;

        if date == 0806
            fc_slope = 0.04;
            [b, a] = butter(2, fc_slope/(fs/2));
        else
            fc_slope = 2;
            [b, a] = butter(3, fc_slope/(fs/2));
        end
        filtered_p_slope = filtfilt(b, a, raw_pressure);
        filtered_p_slope = downsample(filtered_p_slope,100,1);  % 1 Hz
        baseline = movmean(filtered_p_slope,2000);
        filtered_p_slope_offset = filtered_p_slope - baseline + min(filtered_p_slope);


        %%%%%%%%%%%%%% 1. Threshold pressure, Interval 계산을 위한 slope 상승점 찾기 %%%%%%%%%%%%%
        if date == 0806
            slope_thresh = 0.3;
        else
            slope_thresh = 0.35;
        end
        
        cluster_time = 5;  % seconds
        min_group_length = 2;  % seconds
        [slope_idx, slope_vals] = detect_slope_increase(filtered_p_slope-min(filtered_p_slope), 1, slope_thresh, cluster_time, min_group_length);  % fs=1Hz after downsample
        
        
        % figure(); set(gcf, 'Units','centimeters','Position',[5 5 24 12]);
        % subplot(2,1,1)
        % plot(filtered_p_slope_offset);
        % for i = 1:length(slope_offset_idx)
        %     xline(slope_offset_idx(i), 'k--', ...
        %         'Label', num2str(i), ...
        %         'LabelOrientation', 'horizontal', ...
        %         'LabelVerticalAlignment', 'bottom');
        % end

        % p_slope용
        if exp_num == 2 && date == 0721
            slope_list = [1:10];
        elseif exp_num == 4 && date == 0721
            slope_list = [1:11];
        elseif exp_num == 3 && date == 0722
            slope_list = [1 2 4 5 6 7 8];
        elseif exp_num == 4  && date == 0722
            slope_list = [1 3 4:13];
        elseif exp_num == 1 && date == 0723
            slope_list = [17:29 31 33];
        elseif exp_num == 2 && date == 0723
            slope_list = [28:33 35 37:42];
        elseif exp_num == 2 && date == 0806
            slope_list = [1 2 4 5 7 8 9 11 13];
        elseif exp_num == 3 && date == 0806
            slope_list = [6 7 10 11 13 15 17 19];
        elseif exp_num == 3 && date == 0812
            slope_list = [7:18 20];
        elseif exp_num == 4 && date == 0812
            slope_list = [7:15];
        elseif exp_num == 2 && date == 0819
            slope_list = [1 3 4 5 6];
        elseif exp_num == 3 && date == 0819
            slope_list = [2 3 5 6];
        elseif exp_num == 1 && date == 0714
            slope_list = [1 3 4 5 7 8 9 10 12 13 15 16 17 19 21:24];
        end
        slope_idx_filt = slope_idx(slope_list);
        slope_offset_vals = filtered_p_slope_offset(slope_idx_filt)-min(filtered_p_slope_offset(slope_idx_filt));
        % slope_vals_filt = slope_vals(slope_list)+min(filtered_p_slope);
        
        figure(); set(gcf, 'Units','centimeters','Position',[5 5 24 12]);
        plot(filtered_p_slope,'r','LineWidth',1.2);
        % subplot(2,1,1)
        % plot(filtered_p_slope-min(filtered_p_slope),'r','LineWidth',1.2);
        % for i = 1:length(slope_idx_filt)
        %     xline(slope_idx_filt(i), 'k--', ...
        %         'Label', num2str(i), ...
        %         'LabelOrientation', 'horizontal', ...
        %         'LabelVerticalAlignment', 'bottom');
        % end

        thres_pressure{date_idx, trial_idx} = slope_offset_vals;

        for i = 1:length(slope_idx_filt)-1
           diff(i) = slope_idx_filt(i+1)-slope_idx_filt(i);
        end
        
        diff_data{date_idx, trial_idx} = diff;

        %%%%%%%%%%%%%%%%  2. locs filtered data 기반으로 배뇨 Interval 계산 (peak 탐지 기반) %%%%%%%%%%%%%%
        % filtering
        fs = sampling_rate;
        fc_locs = 0.02;
        % fc_locs = 0.2;
        [b, a] = butter(3, fc_locs/(fs/2));
        filtered_p_locs = filtfilt(b, a, raw_pressure);
        filtered_p_locs = downsample(filtered_p_locs,100,1);  % 1 Hz

        [pks, locs] = findpeaks(filtered_p_locs, 'MinPeakHeight', min(filtered_p_locs)+(max(filtered_p_locs)-min(filtered_p_locs))*0.2, 'MinPeakDistance', 50);

        subplot(2,1,2)
        plot(filtered_p_locs);
        hold on;
        for i = 1:length(locs)
            xline(locs(i), 'k--', ...
                'Label', num2str(i), ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'bottom');
        end

        if exp_num == 2 && date == 0721
            include_list = [2,4,6,7,9,10,11,12,13,15];
        elseif exp_num == 4 && date == 0721
            include_list = [2,4,6,7,8,9,10,12,13,14,15];
        elseif exp_num == 3 && date == 0722
            include_list = [1:5 7 8];
        elseif exp_num == 4 && date == 0722
            include_list = [1:8 10 12 14 15];
        elseif exp_num == 1 && date == 0723
            include_list = [14:28];
        elseif exp_num == 2 && date == 0723
            include_list = [11 13 14:24];
        elseif exp_num == 2 && date == 0806
            include_list = [2 3 4 5 7 8 10 12 14];
        elseif exp_num == 3 && date == 0806
            include_list = [10 11 15 16 18 20 22 25];
        elseif exp_num == 3 && date == 0812
            include_list = [7:19];
        elseif exp_num == 4 && date == 0812
            include_list = [8:16];
        elseif exp_num == 2 && date == 0819
            include_list = [1:5];
        elseif exp_num == 3 && date == 0819
            include_list = [2 8 14 18];
        elseif exp_num == 1 && date == 0714
            include_list = [1:18];
        elseif exp_num == 2 && date == 0714
            include_list = [1:8];
        end
        locs_filt = locs(include_list);
    
        subplot(2,1,2)
        plot(filtered_p_locs);
        hold on;
        for i = 1:length(locs_filt)
            xline(locs_filt(i), 'k--', ...
                'Label', num2str(i), ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'bottom');
        end
        % 
        %%%%%%%%%%%%%%%%  3. Slope filtered data에서 Micturtion pressure 계산 %%%%%%%%%%%%%%
        % peak 주변 일부 데이터를 획득한 다음, peak를 탐색한다.
        clear pks_filt
        for i = 1:length(locs_filt)
            set(gcf, 'Units','centimeters','Position',[5 5 6 4]);
            mic_snip = filtered_p_slope(locs_filt(i)-30:locs_filt(i)+30)-min(filtered_p_slope(locs_filt(i)-30:locs_filt(i)+30));
            [pks, locs] = findpeaks(mic_snip, 'MinPeakHeight', max(mic_snip*0.5), 'MinPeakDistance', 55);
            if length(pks) > 1
                pks = pks(1);
            end
            pks_filt(i) = pks;
            % pks_filt(i) = pks-min(filtered_p_slope);
        end
        
        mic_peak{date_idx, trial_idx} = pks_filt;
        
        trial_idx = trial_idx + 1;

        % subplot(2,1,1);
        % plot(filtered_p_slope )
    end
    date_idx = date_idx+1;
end

%% 신호처리
% === 초기화 ===
Normal = struct();
TNS = struct();

% === 평균, 표준편차, 중앙값 계산 ===
for i = 1:size(diff_data,1)
    % --- interval (data) ---
    d1 = diff_data{i, 1};
    d2 = diff_data{i, 2};
    Normal.data.mean(i,1)   = mean(d1);
    TNS.data.mean(i,1)      = mean(d2);
    Normal.data.std(i,1)    = std(d1);
    TNS.data.std(i,1)       = std(d2);
    Normal.data.median(i,1) = median(d1);
    TNS.data.median(i,1)    = median(d2);

    % --- thres_pressure ---
    t1 = thres_pressure{i, 1};
    t2 = thres_pressure{i, 2};
    Normal.thres.mean(i,1)   = mean(t1);
    TNS.thres.mean(i,1)      = mean(t2);
    Normal.thres.std(i,1)    = std(t1);
    TNS.thres.std(i,1)       = std(t2);
    Normal.thres.median(i,1) = median(t1);
    TNS.thres.median(i,1)    = median(t2);

    % --- mic_peak ---
    m1 = mic_peak{i, 1};
    m2 = mic_peak{i, 2};
    Normal.mic.mean(i,1)   = mean(m1);
    TNS.mic.mean(i,1)      = mean(m2);
    Normal.mic.std(i,1)    = std(m1);
    TNS.mic.std(i,1)       = std(m2);
    Normal.mic.median(i,1) = median(m1);
    TNS.mic.median(i,1)    = median(m2);
end

% === 정규화 및 p-value 계산 ===
% for i = 1:size(diff_data,1)
%     TNS.data.norm(i,1)  = TNS.data.mean(i)  / Normal.data.mean(i)  * 100;
%     TNS.thres.norm(i,1) = TNS.thres.mean(i) - Normal.thres.mean(i);
%     TNS.mic.norm(i,1)   = TNS.mic.mean(i)   - Normal.mic.mean(i);
% end

% Median 기반 정규화
for i = 1:size(diff_data,1)
    TNS.data.norm(i,1)  = TNS.data.median(i)  / Normal.data.median(i)  * 100;
    TNS.thres.norm(i,1) = TNS.thres.median(i) - Normal.thres.median(i);
    TNS.mic.norm(i,1)   = TNS.mic.median(i)   - Normal.mic.median(i);
end

% p-value (TNS 정규화된 값 vs baseline 100%)
TNS.data.p_value  = signrank(TNS.data.norm,  ones(size(diff_data,1),1));
TNS.thres.p_value = signrank(TNS.thres.mean, Normal.thres.mean);
TNS.mic.p_value   = signrank(TNS.mic.mean,   Normal.mic.mean);

% 동일한 p-value를 Normal에도 기입 (비교 목적)
Normal.data.p_value  = TNS.data.p_value;
Normal.thres.p_value = TNS.thres.p_value;
Normal.mic.p_value   = TNS.mic.p_value;

% === 결과 출력 (Median [Q1, Q3] + p-value) ===
Q1 = quantile(TNS.data.norm, 0.25);
Q2 = median(TNS.data.norm);
Q3 = quantile(TNS.data.norm, 0.75);
fprintf('Interval, Median [Q1, Q3] = %.4f [%.4f, %.4f], P value = %.4f\n', Q2, Q1, Q3, TNS.data.p_value);

Q1 = quantile(Normal.thres.mean, 0.25);
Q2 = median(Normal.thres.mean);
Q3 = quantile(Normal.thres.mean, 0.75);
fprintf('Normal Thres. P, Median [Q1, Q3] = %.4f [%.4f, %.4f], P value = %.4f\n', Q2, Q1, Q3, TNS.thres.p_value);

Q1 = quantile(TNS.thres.mean, 0.25);
Q2 = median(TNS.thres.mean);
Q3 = quantile(TNS.thres.mean, 0.75);
fprintf('TNS Thres. P, Median [Q1, Q3] = %.4f [%.4f, %.4f], P value = %.4f\n', Q2, Q1, Q3, TNS.thres.p_value);

Q1 = quantile(Normal.mic.mean, 0.25);
Q2 = median(Normal.mic.mean);
Q3 = quantile(Normal.mic.mean, 0.75);
fprintf('Normal Mic. P,   Median [Q1, Q3] = %.4f [%.4f, %.4f], P value = %.4f\n', Q2, Q1, Q3, TNS.mic.p_value);

Q1 = quantile(TNS.mic.mean, 0.25);
Q2 = median(TNS.mic.mean);
Q3 = quantile(TNS.mic.mean, 0.75);
fprintf('TNS Mic. P,   Median [Q1, Q3] = %.4f [%.4f, %.4f], P value = %.4f\n', Q2, Q1, Q3, TNS.mic.p_value);


%% Figure 3-C: 자극 전 후 Representative data plotting
path = strcat('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\250723_test');
cd(path)

close all;

% 첫 번째 데이터
% load('250721_OAB_2.mat');
load('250723_OAB_1.mat');
fs = 100;
fc_locs = 2;
[b, a] = butter(2, fc_locs/(fs/2));
filtered_p1 = filtfilt(b, a, b1(:,2));
filtered_p1 = downsample(filtered_p1,100,1);  % 1 Hz

% 두 번째 데이터
% load('250721_OAB_4.mat');
load('250723_OAB_2.mat');
[b, a] = butter(2, fc_locs/(fs/2));
filtered_p2 = filtfilt(b, a, b1(:,2));
filtered_p2 = downsample(filtered_p2,100,1);  % 1 Hz

baseline = filtfilt(b, a, b1(:,2));
baseline = downsample(baseline,100,1);  
baseline = movmean(baseline,2000);
aligned_p2 = filtered_p2 - baseline + min(filtered_p1+3);

% y축 스케일 통합 (두 데이터 전체 범위 기준 ±5%)
all_data = [filtered_p1; aligned_p2];
yr = range(all_data);
ymin = min(all_data) - 0.05*yr;
ymax = max(all_data) + 0.05*yr;

% Figure 1
figure(2001); hold on;
set(gcf, 'Units','centimeters','Position',[5 5 8 3]);
plot(filtered_p1, 'r');
xlim([0 1800]);
set(gca,'XTick',[0 1800],'XTickLabel',{'0','1800'});
xlabel('Time (s)');
ylabel('IBP (mmHg)');
ylim([ymin ymax]);
box off; grid off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize',7);

% Figure 2 (출력 구간: 1400~3200, x축 라벨: 0과 1600)
figure(2002); hold on;
set(gcf, 'Units','centimeters','Position',[9 13 8 3]);

% 1400~3200 구간만 출력
start_idx = 1350;
end_idx   = 3150;
plot(aligned_p2(start_idx:end_idx), 'r');

% x축 범위: 데이터 길이는 (end_idx - start_idx + 1) = 1601
xlim([0 1600]);
set(gca,'XTick',[0 1600], 'XTickLabel',{'0','1600'});

xlabel('Time (s)');
ylabel('IBP (mmHg)');
ylim([ymin ymax]);
box off; grid off;

set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize',7);


%% Figure 3-D-1: Normalized Interval (TNS only)
figure(3001); hold on;
set(gcf, 'Units','centimeters','Position',[5 5 2.5 4]);

% 데이터 준비: TNS interval 정규화 값
data_interval_norm = TNS.data.norm(:);

% boxplot (단일 그룹)
boxplot(data_interval_norm, 'Colors','k','Widths',0.3,'Symbol','');
ylabel('Norm. inter-micturition interval (%)');
set(gca,'XTickLabel',{'TNS norm'});

% 2) --- 범용적으로 모든 선 객체를 찾아 실선으로 변경 ---
% Axes 내 모든 line 객체를 가져와 스타일 통일
allLines = findobj(gca, 'Type', 'line');
if ~isempty(allLines)
    set(allLines, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
end

% 모든 박스 객체 찾기 (역순으로 반환됨)
hBox = findobj(gca, 'Tag', 'Box');

% 원하는 색상 목록 (RGB)
colors = [
    0 0 0;   % 파랑
    1 0 0;   % 빨강
    0 0 0;   % 검정
];

% 각 박스에 색상 지정 (테두리만 색상 적용)
for j = 1:length(hBox)
    patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), 'w', ... % 내부 흰색
        'FaceAlpha', 0, ...
        'EdgeColor', colors(mod(j-1, size(colors,1)) + 1, :), ... % 테두리 색상
        'LineWidth', 0.8, ...
        'LineStyle', '-');
end

% --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게

% 산점도 (중앙 x=1에 위치)
num_points = size(data_interval_norm,1);
x_jittered = 1 + (rand(num_points,1)-0.5)*0.1;
scatter(x_jittered, data_interval_norm, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',1);

% 중앙 배치용 xlim 조정
xlim([0.5 1.5]);
yline(100,':')
box off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);
ylim([70 220])

% 1. Wilcoxon signed-rank test 수행
% data_interval_norm의 중앙값이 1인지 검정
[p, h, stats] = signrank(data_interval_norm);

% 결과 출력
fprintf('Wilcoxon signed-rank test 결과:\n');
fprintf('p-value: %.4f\n', p);
if h == 1
    fprintf('결과: 귀무가설 기각 (중앙값이 1과 유의미하게 다름)\n');
else
    fprintf('결과: 귀무가설 채택 (중앙값이 1과 유의미한 차이가 없음)\n');
end

%% Figure 3-D-2: Threshold (Normal vs TNS)
figure(3002); hold on;
set(gcf, 'Units','centimeters','Position',[9 5 3 4]);

data_thres = [Normal.thres.mean(:), TNS.thres.mean(:)];
group_labels = {'Normal','Post-tTNS'};

boxplot(data_thres,'Labels',group_labels,...
    'Colors','k','Widths',0.5,'Symbol','');

% 2) --- 범용적으로 모든 선 객체를 찾아 실선으로 변경 ---
% Axes 내 모든 line 객체를 가져와 스타일 통일
allLines = findobj(gca, 'Type', 'line');
if ~isempty(allLines)
    set(allLines, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
end

% 모든 박스 객체 찾기 (역순으로 반환됨)
hBox = findobj(gca, 'Tag', 'Box');

% 원하는 색상 목록 (RGB)
colors = [
    1 0 0;   % 파랑
    0 0 0;   % 빨강
    0 0 0;   % 검정
];

% 각 박스에 색상 지정 (테두리만 색상 적용)
for j = 1:length(hBox)
    patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), 'w', ... % 내부 흰색
        'FaceAlpha', 0, ...
        'EdgeColor', colors(mod(j-1, size(colors,1)) + 1, :), ... % 테두리 색상
        'LineWidth', 0.8, ...
        'LineStyle', '-');
end

% --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게

num_points = size(data_thres,1);
jitter_amplitude = 0.1;
for j = 1:2
    x_jittered = j + (rand(num_points,1)-0.5)*jitter_amplitude;
    scatter(x_jittered, data_thres(:,j), 8,...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
end

ylabel('Thres. pressure (mmHg)');

% 중앙 배치용 xlim (두 그룹이면 [0.5 2.5]로 잡으면 중앙에 고정)
xlim([0.5 2.5]);


box off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);
% ylim([10 32])

% --- X축 group label 폰트 크기만 5로 변경 ---
ax = gca;
ax.XAxis.FontSize = 5;

%% Figure 3-D-3: Micturition Peak Pressure (Normal vs TNS)
figure(3003); hold on;
set(gcf, 'Units','centimeters','Position',[13 5 3 4]);

data_mic = [Normal.mic.mean(:), TNS.mic.mean(:)];
group_labels = {'Normal','Post-tTNS'};

boxplot(data_mic,'Labels',group_labels,...
    'Colors','k','Widths',0.5,'Symbol',''); % 기본 outlier 표시 제거

% --- 모든 선 객체 실선으로 변경 ---
allLines = findobj(gca, 'Type', 'line');
if ~isempty(allLines)
    set(allLines, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
end

% --- 박스 테두리 색상 지정 (내부 흰색) ---
hBox = findobj(gca, 'Tag', 'Box');
colors = [
    1 0 0;   % 빨강
    0 0 0;   % 파랑
];
for j = 1:length(hBox)
    patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), 'w', ...
        'FaceAlpha', 0, ...
        'EdgeColor', colors(mod(j-1, size(colors,1)) + 1, :), ...
        'LineWidth', 0.8, ...
        'LineStyle', '-');
end

% --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);

num_points = size(data_mic,1);
jitter_amplitude = 0.05; % jitter 정도

for j = 1:2
    % IQR 기준 계산
    Q1 = prctile(data_mic(:,j),25);
    Q3 = prctile(data_mic(:,j),75);
    IQRv = Q3 - Q1;
    
    % inlier / outlier 인덱스
    inlierIdx = (data_mic(:,j) >= (Q1 - 1.5*IQRv)) & (data_mic(:,j) <= (Q3 + 1.5*IQRv));
    outlierIdx = ~inlierIdx;
    
    % --- Inlier scatter plot ---
    x_jittered_in = j + (rand(sum(inlierIdx),1)-0.5)*jitter_amplitude;
    scatter(x_jittered_in, data_mic(inlierIdx,j), 8,...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
    
    % --- Outlier scatter plot (붉은 +) ---
    x_jittered_out = j + (rand(sum(outlierIdx),1)-0.5)*jitter_amplitude;
    scatter(x_jittered_out, data_mic(outlierIdx,j), 20, 'r', '+', 'LineWidth',1);
end

ylabel('Micturition pressure (mmHg)');
xlim([0.5 2.5]);
ylim([8 30]);

box off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

% --- X축 group label 폰트 크기만 5로 변경 ---
ax = gca;
ax.XAxis.FontSize = 5;


%% Supplementary data: Individual data
for i = 1:6
    % 데이터 불러오기
    norm = diff_data{i,1};
    TNS  = diff_data{i,2};   % TNS 데이터는 두 번째 열에 있다고 가정
    
    % Figure 생성
    fig = figure(i);
    clf(fig);
    set(fig, 'Units', 'centimeters', 'Position', [5+(i-1)*5 5 3 5]);
    
    % 데이터 묶기
    data = [norm(:); TNS(:)];
    group = [repmat({'Normal'}, length(norm), 1);
             repmat({'Post-tTNS'}, length(TNS), 1)];
    
    % 박스플롯 그리기
    boxplot(data, group, ...
        'Colors', [0 0 0], ...
        'Symbol', 'k+', ...
        'BoxStyle', 'outline', ...
        'Widths', 0.6);
    hold on;
    
    % x 위치
    x_positions = [1, 2, 3];
    jitterAmount = 0.05;

    % 2) --- 범용적으로 모든 선 객체를 찾아 실선으로 변경 ---
    % Axes 내 모든 line 객체를 가져와 스타일 통일
    allLines = findobj(gca, 'Type', 'line');
    if ~isempty(allLines)
        set(allLines, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
    end
    
    % 모든 박스 객체 찾기 (역순으로 반환됨)
    hBox = findobj(gca, 'Tag', 'Box');
    
    % 원하는 색상 목록 (RGB)
     colors = [0 0 1; 1 0 0; 0 0 0];
    
    % 각 박스에 색상 지정
    for j = 1:length(hBox)
        patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), colors(mod(j-1,size(colors,1))+1,:), ...
            'FaceAlpha', 0, 'EdgeColor', colors(mod(j-1, size(colors,1)) + 1, :), 'LineStyle', '-');
    end
    
    % 4) --- Median 선 색상 강조 ---
    hMedian = findobj(gca, 'Tag', 'Median');
    set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게

    % 개별 데이터 점 추가 (scatter)
    % Normal = x=1 위치, TNS = x=2 위치
    scatter(ones(size(norm)) + (rand(size(norm))-0.5)*0.15, norm, 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
    scatter(2*ones(size(TNS)) + (rand(size(TNS))-0.5)*0.15, TNS, 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
    
    % 그래프 꾸미기
    % title(sprintf('Subject %d', i));
    ylabel('Micturition interval (s)');
    set(gca, 'Box', 'off', 'FontSize', 7, 'LineWidth', 1);
    hold off;
end
