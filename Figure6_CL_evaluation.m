%% experiment data
clear; close all; clc;
date_list = [0929, 1003, 1015, 1016, 1021, 1109];
% date_list = [1109];
date_idx = 1;

for date = date_list
    %%
    if date == 0929
        stim_start = 2450;
        OAB_start = 1723;
        stim_duration = 1200+300;
        skip_thres = 100;
        OAB_standard = 200;
    elseif date == 0930
        OAB_start = 1512;
        stim_start = 2090;    
        stim_duration = 1200+300;
        skip_thres = 50;
        OAB_standard = 200;
    elseif date == 1003
        stim_start = 3016;
        OAB_start = 2003;
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
        OAB_start = 2850;
        stim_duration = 1200+1000;
        OAB_standard = 230;
        skip_thres = 120;
    elseif date == 1021
        stim_start = 3285;
        OAB_start = 2524;
        stim_duration = 1200+1200;
        OAB_standard = 210;
        skip_thres = 115;
    elseif date == 1109
        OAB_start = 2905;
        stim_start = 4310;
        stim_duration = 1200+1200;
        OAB_standard = 200;
        skip_thres = 90;
    end

    %% Load bladder data
    cd '\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\CL_DATA'
    file_name = strcat('25', num2str(date, '%04d'),'_CL_success.mat');
    load(file_name);
    
    Bladder.raw{date_idx} = double(b1(:,2)); 
    % clear b1 m000
    
    % Bladder filtering
    if date == 1016
        fc_slope = 0.007; % 0.2
    else
        fc_slope = 0.01; % 0.2
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
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(1:end);
    elseif date == 1021
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(2001:end);
    end

    fig2 = figure(date_idx); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 15 10 2.2]);
    plot(Bladder.filt_down{date_idx},'r','LineWidth', 1.2)
    
    ylabel('IBP (mmHg)')
    xlabel('Time (s)')
    axis tight;
    % ylim([30 90])
    
    set(findall(gcf,'-property','FontName'),'FontName','Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize',7);
    
    BP = movmean(Bladder.filt_down{date_idx}, 5);

    % Normal
    [pks, locs_normal] = findpeaks(BP(1:OAB_start),'MinPeakDistance', skip_thres);
    if date == 1016
        locs_normal = [39 339 902 1324 1568 2004 2689];
    elseif date == 1109
        locs_normal = [180 387 730 990 1233 1482];
    end
    
    % Before stim
    [pks, locs_OAB] = findpeaks(BP(OAB_start:stim_start),'MinPeakDistance', skip_thres);
    % xline(locs_OAB +OAB_start,'r:');

    if date == 1016
        locs_OAB = [2907, 3029, 3193, 3278];
    elseif date == 0930
        locs_OAB = [1630, 1802, 1930, 2113];
    elseif date == 1109
        locs_OAB = [2953 3150 3262 3446 3568 3779 3986 4123 4235];
    end

    % After stim
    [pks, locs_TNS] = findpeaks(BP(stim_start+stim_duration:end),'MinPeakDistance', skip_thres);
    % xline(locs_TNS+stim_start+stim_duration,'k:');
    if date == 1109
        locs_TNS = [5876 6093 6298 6484 6643 6827 7124];
    end

    Normal{date_idx} = diff(locs_normal);
    OAB{date_idx} = diff(locs_OAB);
    TNS{date_idx} = diff(locs_TNS);
    
    Normal_norm{date_idx} = diff(locs_normal)/OAB_standard;
    OAB_norm{date_idx} = diff(locs_OAB)/OAB_standard;
    TNS_norm{date_idx} = diff(locs_TNS)/OAB_standard;
    
    id_time(date_idx) = stim_start-OAB_start;
    box off;

    if date == 1015
        ylim([40, 110])
    elseif date == 1016
        ylim([20, 100])
    end

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
    elseif date == 1015
        Pupil.filt_down{date_idx} = Pupil.filt_down{date_idx}(1:7950);
    elseif date == 1016
        Pupil.filt_down{date_idx} = Pupil.filt_down{date_idx}(1:end);
    elseif date == 1021
        Pupil.filt_down{date_idx} = Pupil.filt_down{date_idx}(2000:end);
    end
    
    plot_pupil = movmean(Pupil.filt_down{date_idx}, 6);

    fig2 = figure(date_idx+100); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 9 10 2.2]);
    plot(plot_pupil, 'b', 'linewidth', 1.2);
    axis tight
    ylim([0, 600])

    
    % ylabel('Pupil size (Pixel)')
    xlabel('Time (s)')
    set(findall(gcf,'-property','FontName'),'FontName','Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize', 7);

    % xline(stim_start, 'r--', 'linewidth', 1.2)
    
    if date == 0929
        ylim([0, 700])
    elseif date == 0930
        ylim([0, 3000])  
    elseif date == 1003  
        ylim([0, 3500])
    elseif date == 1015
        ylim([0, 7000])
    elseif date == 1016
        ylim([0, 9000])
    elseif date == 1021
        ylim([0, 9000])
    end
    
    date_idx = date_idx+1;
    box off;
end 
 
%% Individual date representation
% for i = 1:length(date_list)
%     group = [repmat({'Norm.'}, length(Normal{i}), 1);
%              repmat({'OAB'},   length(OAB{i}), 1);
%              repmat({'tTNS'},  length(TNS{i}), 1)];
% 
%     % 데이터 합치기
%     data_all = [Normal{i}(:); OAB{i}(:); TNS{i}(:)];
% 
%     % 박스플롯 (outlier 빨간 + 표시)
%     fig2 = figure(i+200); clf(fig2);
%     set(fig2, 'Units','centimeters','Position',[5+(i-1)*5 6 4 6]); 
%     boxplot(data_all, group, 'Symbol', 'r+', 'Widths', 0.6);
%     hold on;
% 
%     % x 위치
%     x_positions = [1, 2, 3];
%     jitterAmount = 0.05;
% 
%     % 2) --- 범용적으로 모든 선 객체를 찾아 실선으로 변경 ---
%     % Axes 내 모든 line 객체를 가져와 스타일 통일
%     allLines = findobj(gca, 'Type', 'line');
%     if ~isempty(allLines)
%         set(allLines, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
%     end
% 
%     % 모든 박스 객체 찾기 (역순으로 반환됨)
%     hBox = findobj(gca, 'Tag', 'Box');
% 
%     % 원하는 색상 목록 (RGB)
%      colors = [0 0 1; 1 0 0; 0 0 0];
% 
%     % 각 박스에 색상 지정
%     for j = 1:length(hBox)
%         patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), colors(mod(j-1,size(colors,1))+1,:), ...
%             'FaceAlpha', 0, 'EdgeColor', colors(mod(j-1, size(colors,1)) + 1, :), 'LineStyle', '-');
%     end
% 
%     % 4) --- Median 선 색상 강조 ---
%     hMedian = findobj(gca, 'Tag', 'Median');
%     set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게
% 
%     % --- 그룹별 IQR 계산 및 outlier 제외 후 scatter ---
%     % 1) Normal
%     Q1 = prctile(Normal{i}, 25);
%     Q3 = prctile(Normal{i}, 75);
%     IQRv = Q3 - Q1;
%     inliers = Normal{i}(Normal{i} >= (Q1 - 1.5*IQRv) & Normal{i} <= (Q3 + 1.5*IQRv));
%     x_norm = x_positions(1) + (rand(size(inliers)) - 0.5) * 2 * jitterAmount;
%     scatter(x_norm, inliers, 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
% 
%     % 2) OAB
%     Q1 = prctile(OAB{i}, 25);
%     Q3 = prctile(OAB{i}, 75);
%     IQRv = Q3 - Q1;
%     inliers = OAB{i}(OAB{i} >= (Q1 - 1.5*IQRv) & OAB{i} <= (Q3 + 1.5*IQRv));
%     x_oab = x_positions(2) + (rand(size(inliers)) - 0.5) * 2 * jitterAmount;
%     scatter(x_oab, inliers, 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
% 
%     % 3) TNS
%     Q1 = prctile(TNS{i}, 25);
%     Q3 = prctile(TNS{i}, 75);
%     IQRv = Q3 - Q1;
%     inliers = TNS{i}(TNS{i} >= (Q1 - 1.5*IQRv) & TNS{i} <= (Q3 + 1.5*IQRv));
%     x_tns = x_positions(3) + (rand(size(inliers)) - 0.5) * 2 * jitterAmount;
%     scatter(x_tns, inliers, 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
% 
%     % --- 그래프 옵션 ---
%     ylabel('Interval (s)');
%     set(gca, 'FontSize', 8);
%     yline(200, 'k:')
%     box off;
% 
%     % --- 중간값 출력 ---
%     med1 = median(Normal{i});
%     med2 = median(OAB{i});
%     med3 = median(TNS{i});
%     disp(['Normal median: ', num2str(med1)]);
%     disp(['OAB median: ', num2str(med2)]);
%     disp(['TNS median: ', num2str(med3)]);
%     disp(['Id Time: ', num2str(id_time(i))]);
%     disp(' ')
% end

%% id_time 변수에 대한 Boxplot + Scatter Plot (Figure 6-d) 
fig_id = figure(99); clf(fig_id);
set(fig_id, 'Units', 'centimeters', 'Position', [5 5 3 5]);

for i = 1:length(date_list)
    % 데이터 합치기
    oab(i,1)  = median(OAB{i});
end

id_time_edit = id_time;

% 1) Boxplot 그리기 (박스 폭 설정)
boxWidth = 0.3;  % 기본값은 약 0.5~0.6 정도
boxplot(id_time_edit, 'Widths', boxWidth);
hold on;

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
     1 1 1;   % 연한 파랑
    0.9 0.8 1.0;   % 연한 보라
    0.9 1.0 0.8;   % 연한 연두
];

% 각 박스에 색상 지정
for j = 1:length(hBox)
    patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), colors(mod(j-1,size(colors,1))+1,:), ...
        'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineStyle', '-');
end

% 4) --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게

% 2) Scatter plot (jitter 적용)
nPoints = numel(id_time);
x_center = 1;              % boxplot의 그룹 x좌표 (id_time은 단일 그룹)
jitterAmount = 0.05;        % 점 좌우 퍼짐 정도
x_jitter = x_center + (rand(nPoints,1)-0.5)*2*jitterAmount;

scatter(x_jitter, id_time_edit, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 3) 옵션 꾸미기
xlim([0.5 1.5]);
xticks(1);
xticklabels({'CL-tTNS'});
ylabel('OAB detection time (s)');
set(gca, 'FontSize', 7);

hold off;
box off;
ylim([300, 1800])

median(id_time_edit)
Q1 = quantile(id_time_edit, 0.25)
Q3 = quantile(id_time_edit, 0.75)

%% Normalized id_time 변수에 대한 Boxplot + Scatter Plot (Figure 6-d) 
fig_id = figure(99); clf(fig_id);
set(fig_id, 'Units', 'centimeters', 'Position', [5 5 3 5]);

for i = 1:length(date_list)
    % 데이터 합치기
    oab(i,1)  = median(OAB{i});
    norm_id_time(i) = (id_time(i)-0)/oab(i)';
end

% 1) Boxplot 그리기 (박스 폭 설정)
boxWidth = 0.3;  % 기본값은 약 0.5~0.6 정도
boxplot(norm_id_time, 'Widths', boxWidth);
hold on;

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
     1 1 1;   % 연한 파랑
    0.9 0.8 1.0;   % 연한 보라
    0.9 1.0 0.8;   % 연한 연두
];

% 각 박스에 색상 지정
for j = 1:length(hBox)
    patch(get(hBox(j), 'XData'), get(hBox(j), 'YData'), colors(mod(j-1,size(colors,1))+1,:), ...
        'FaceAlpha', 0.5, 'EdgeColor', 'k', 'LineStyle', '-');
end

% 4) --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게

% 3) Scatter plot (jitter 적용)
nPoints = numel(norm_id_time);
x_center = 1;              % boxplot의 그룹 x좌표 (id_time은 단일 그룹)
jitterAmount = 0.05;        % 점 좌우 퍼짐 정도
x_jitter = x_center + (rand(nPoints,1)-0.5)*2*jitterAmount;

scatter(x_jitter, norm_id_time, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 3) 옵션 꾸미기
xlim([0.5 1.5]);
xticks(1);
xticklabels({'CL-tTNS'});
ylabel('Norm. OAB detect. time (fold)');
set(gca, 'FontSize', 7 );

hold off;
box off;

median(norm_id_time)
Q1 = quantile(norm_id_time, 0.25)
Q3 = quantile(norm_id_time, 0.75)


%% data summary (Figure 6-c)
total = struct;
for i = 1:length(date_list)
    % 데이터 합치기
    total.norm(i,1) = median(Normal{i});
    total.oab(i,1)  = median(OAB{i});
    total.tns(i,1)  = median(TNS{i});
end

% --- 박스플롯 + 산점도(jittered scatter) 출력 코드 ---
figure; clf;
set(gcf, 'Units', 'centimeters', 'Position', [5 6 4.5 5]);

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
    0 0 1;   % 파랑
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

% 옵션 꾸미기
ylabel('Inter-micturition interval (s)');
set(gca, 'FontSize', 7, 'Box', 'off');
yline(200, 'k:', 'LineWidth', 0.6);
box off;


% --- 3조건 데이터 행렬 구성 (각 행 = 같은 날짜) ---
data_mat = [ ...
    total.norm(:), ...
    total.oab(:), ...
    total.tns(:) ...
];

% NaN 포함된 행 제거
validIdx = all(~isnan(data_mat), 2);
data_mat = data_mat(validIdx, :);

% --- 사후 비교 쌍 정의 ---
pairNames = { ...
    'Normal vs OAB', ...
    'Normal vs CL-tTNS', ...
    'OAB vs CL-tTNS' ...
};

pairs = {
    data_mat(:,1), data_mat(:,2);
    data_mat(:,1), data_mat(:,3);
    data_mat(:,2), data_mat(:,3)
};

m = size(pairs, 1);   % 비교 횟수 (3)
p_raw = zeros(m,1);
p_sidak = zeros(m,1);

% Wilcoxon signed-rank test
for i = 1:m
    p_raw(i) = signrank(pairs{i,1}, pairs{i,2});
end

% Dunn–Šidák 보정
for i = 1:m
    p_sidak(i) = 1 - (1 - p_raw(i))^m;
end

% 결과 출력
fprintf('Post-hoc Wilcoxon signed-rank test (Dunn–Šidák corrected):\n');
for i = 1:m
    fprintf('%s: p_raw = %.4f, p_Sidak = %.4f\n', ...
        pairNames{i}, p_raw(i), p_sidak(i));
end

%% Normalized Total_data (Figure 6-d)
total = struct;
for i = 1:length(date_list)
    % 데이터 합치기
    total.norm(i,1) = median(Normal_norm{i})*100;
    total.oab(i,1)  = median(OAB_norm{i})*100;
    total.tns(i,1)  = median(TNS_norm{i})*100;
end

% --- 박스플롯 + 산점도(jittered scatter) 출력 코드 ---
figure; clf;
set(gcf, 'Units', 'centimeters', 'Position', [5 6 4.5 5]);

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
    0 0 1;   % 파랑
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
ylabel('Norm. Inter-micturition interval (%)');
set(gca, 'FontSize', 7, 'Box', 'off');
yline(200, 'k:', 'LineWidth', 0.6);
box off;
yline(100, 'k:')

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

median(total.norm)
median(total.oab)
median(total.tns)