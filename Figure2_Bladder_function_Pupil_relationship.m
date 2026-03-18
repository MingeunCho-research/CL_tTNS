clear; clc; close all;

% date_list = [722 929 1016 260203 260206 260209];
% date_list = [703 710 714 722 929 1016 260203 260209]; % 260206 데이터 넣으면 퀄리티 나빠짐. 데이터 다시 구간 체크할 필요
date_list = [703 710 714 722 260203 260209];
% date_list = [703 710 711 714 722 260203 260209];

X_cell = cell(length(date_list),1);   % subject-wise pupil peaks
Y_cell = cell(length(date_list),1);   % subject-wise IBP peaks

X_subject = [];
Y_subject = [];

sub_i = 1;

for date = date_list

    pupil_max_all = [];
    ibp_max_all   = [];

    % 새로운 특징(Feature) 저장을 위한 배열 초기화
    pupil_velocity_all = []; % 동공 확장 최대 속도
    ibp_onset_all      = []; % 수축 시작 시점의 방광 압력

    % ---------- (기존 path 설정 동일) ----------
    if date == 722
        exp_list = [1 3 4];
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 703
        exp_list = [1 2]; % 2 3
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 710
        exp_list = [3]; % 2 3
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 711
        exp_list = [4]; % 2 3
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 714
        exp_list = [1]; % 2 3
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 721
        exp_list = [2]; % 2 3
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_test');
        type = 1;
    elseif date == 929
        exp_list = 1;
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_CL_success');
        type = 2;
    elseif date == 1016
        exp_list = 1;
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\25',num2str(date,'%04d'),'_CL_success');
        type = 2;
    else
        exp_list = 1;
        pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\',num2str(date,'%06d'),'_baseline');
        type = 3;
    end

    cd(pathname)

    for exp_num = exp_list

        % ===== DATA LOAD / FILTER (기존 코드 그대로 사용) =====
        
         %% 1. DATA LOADING
        date_str = num2str(date,'%04d');

        % --- Bladder ---
        if type == 1
            bladder_file = strcat('25', num2str(date,'%04d'), ...
                                   '_OAB_', num2str(exp_num), '.mat');
        elseif type == 3
            bladder_file = strcat(num2str(date,'%06d'), ...
                                   '_OAB_', num2str(exp_num), '.mat');
        else
            bladder_file = strcat('25', num2str(date,'%04d'), ...
                                   '_CL_success.mat');
        end
        load(bladder_file);

        if exp_num == 4 && date == 0722
            Bladder.raw = double(b2(:,2));
        else
            Bladder.raw = double(b1(:,2));
        end

        % --- Pupil ---
        if type == 1
            pupil_file_v3 = strcat('2025-', [date_str(1:2) '-' date_str(3:4)], ...
                                   '_video_', num2str(exp_num), '_pupil_area_v3.csv');
            pupil_file_default = strcat('2025-', [date_str(1:2) '-' date_str(3:4)], ...
                                        '_video_', num2str(exp_num), '_pupil_area.csv');
        elseif type == 3
            pupil_file_v3 = strcat('2026-', [date_str(3:4) '-' date_str(5:6)], ...
                                   '_video_1_pupil_area.csv');
            pupil_file_default = 'not_available';
        else
            pupil_file_v3 = strcat('2025-', [date_str(1:2) '-' date_str(3:4)], ...
                                   '_video_CL_success_pupil_area_v3.csv');
            pupil_file_default = strcat('2025-', [date_str(1:2) '-' date_str(3:4)], ...
                                        '_video_CL_success_pupil_area.csv');
        end

        if exist(pupil_file_v3,'file') == 2
            pupil_file = pupil_file_v3;
        else
            pupil_file = pupil_file_default;
        end
        pupil = readtable(pupil_file);
        Pupil.raw = pupil.FilteredArea;

        %% 2. FILTERING
        % --- Bladder ---
        fs = 100;
        fc = 0.2;
        [b,a] = butter(2, fc/(fs/2));
        Bladder.filt = filtfilt(b,a,Bladder.raw);
        Bladder.filt_down = downsample(Bladder.filt,100,1);

        % --- Pupil ---
        fs = 10;
        fc = 0.05;
        [b,a] = butter(2, fc/(fs/2));
        Pupil.filt = filtfilt(b,a,Pupil.raw);
        Pupil.filt_down = downsample(Pupil.filt,10,1);

        %% 3. ANALYSIS RANGE
        if exp_num == 4 && date == 0722
            Bladder.filt_down = Bladder.filt_down(1280:5400);
            Pupil.filt_down   = Pupil.filt_down(1280:5400);
        elseif date == 929
            Bladder.filt_down = [ ...
                Bladder.filt_down(1:1600)-min(Bladder.filt_down(1:1600)); ...
                Bladder.filt_down(4000:4800)-min(Bladder.filt_down(4000:4800))];
            Pupil.filt_down = [ ...
                Pupil.filt_down(1:1600); ...
                Pupil.filt_down(4000:4800)-Pupil.filt_down(4000:4800)];
        elseif date == 1016
            Bladder.filt_down = Bladder.filt_down(2800:3200);
            Pupil.filt_down   = Pupil.filt_down(2800:3200);
        elseif date == 260203
            Bladder.filt_down = Bladder.filt_down(1:1800);
            Pupil.filt_down   = Pupil.filt_down(1:1800);
        elseif date == 260206
            Bladder.filt_down = Bladder.filt_down(1:4700);
            Pupil.filt_down   = Pupil.filt_down(1:4700);
        elseif date == 260209
            Bladder.filt_down = Bladder.filt_down(1:3500);
            Pupil.filt_down   = Pupil.filt_down(1:3500);
        else
            Bladder.filt_down = Bladder.filt_down;
            Pupil.filt_down   = Pupil.filt_down;
        end

        Bladder.filt_down = Bladder.filt_down - min(Bladder.filt_down);

        % -------- Peak detection --------
        [~,locs] = findpeaks(Bladder.filt_down,...
            'MinPeakHeight',0.7*max(Bladder.filt_down),...
            'MinPeakDistance',10);

        seg_len = 100;
        pre  = 59;
        post = 40;

        N_B = length(Bladder.filt_down);

        for i = 1:length(locs)

            idx = locs(i);

            IBP_segment   = zeros(seg_len,1);
            Pupil_segment = zeros(seg_len,1);

            src_start = max(1, idx-pre);
            src_end   = min(N_B, idx+post);

            dst_start = src_start - (idx-pre) + 1;
            dst_end   = dst_start + (src_end - src_start);

            IBP_segment(dst_start:dst_end)   = Bladder.filt_down(src_start:src_end);
            Pupil_segment(dst_start:dst_end) = Pupil.filt_down(src_start:src_end);

            ibp_max_all   = [ibp_max_all;   max(IBP_segment)];
            pupil_max_all = [pupil_max_all; max(Pupil_segment)];

            % --- 신규 변수 추출 ---
            % 1. 동공 확장 속도 (최대 미분값)
            % fs=10이므로 샘플 간격을 고려한 속도 계산
            pupil_vel = gradient(Pupil_segment) * 10; 
            pupil_velocity_all = [pupil_velocity_all; max(pupil_vel)];
            
            % 2. 방광 확장 시작 시점 압력 (Onset Pressure)
            % 세그먼트의 가장 앞단(src_start 지점)을 시작점으로 간주
            ibp_onset_all = [ibp_onset_all; min(IBP_segment(dst_start:dst_end))];
        end
    end

    % ===== subject별 peak 전체 저장 (cell) =====
    X_cell{sub_i} = pupil_max_all-ibp_onset_all;
    Y_cell{sub_i} = ibp_max_all;

    V_cell{sub_i} = pupil_velocity_all;
    O_cell{sub_i} = ibp_onset_all;

    % subject-level max
    X_subject = [X_subject; max(pupil_max_all)];
    Y_subject = [Y_subject; max(ibp_max_all)];

    sub_i = sub_i + 1;
end

% %% ===== 개체별 scatter + fitting (6개 subplot) =====
% figure
% 
% for i = 1:length(X_cell)
% 
%     x = X_cell{i};
%     y = Y_cell{i};
% 
%     % correlation
%     [r,p] = corr(x,y,'Type','Pearson');
% 
%     % linear fit
%     coef = polyfit(x,y,1);
%     xfit = linspace(min(x),max(x),100);
%     yfit = polyval(coef,xfit);
% 
%     subplot(2,3,i)
%     scatter(x,y,40,'filled'); hold on
%     plot(xfit,yfit,'r','LineWidth',2)
% 
%     xlabel('Pupil peak')
%     ylabel('IBP peak')
%     title(['Subject ',num2str(i), ...
%            '   r=',num2str(r,2), ...
%            '   p=',num2str(p,2)])
%     grid on
% end

%% Combined correlation after subject-wise z-score normalization

% cell별 z-score → 전체 합치기
X_all = [];
Y_all = [];
group_id = [];

for i = 1:length(X_cell)

    x = X_cell{i};
    y = Y_cell{i};

    % z-score normalization (within subject)
    xz = (x - mean(x)) ./ std(x);
    yz = (y - mean(y)) ./ std(y);

    X_all = [X_all; xz(:)];
    Y_all = [Y_all; yz(:)];
    group_id = [group_id; i*ones(length(xz),1)];
end

% Correlations
[R_pearson, P_pearson]   = corr(X_all,Y_all,'Type','Pearson');
[R_spearman, P_spearman] = corr(X_all,Y_all,'Type','Spearman');
[R_kendall, P_kendall]   = corr(X_all,Y_all,'Type','Kendall');

disp(['Pearson  r = ',num2str(R_pearson),'   p = ',num2str(P_pearson)])
disp(['Spearman r = ',num2str(R_spearman),'   p = ',num2str(P_spearman)])
disp(['Kendall  r = ',num2str(R_kendall),'   p = ',num2str(P_kendall)])

% Linear fitting
coef = polyfit(X_all,Y_all,1);
xfit = linspace(min(X_all),max(X_all),200);
yfit = polyval(coef,xfit);

% Scatter plot (subject-wise color)
fig = figure(1); clf(fig);                 % figure(2) 열고 초기화
set(fig, 'Units','centimeters');           % 단위: cm
set(fig, 'Position', [5 5 4.75 4.75]);   
hold on
colors = lines(length(X_cell));

for i = 1:length(X_cell)
    idx = group_id == i;
    % MarkerEdgeColor를 'k'(black)로 설정하고, Size를 15로 변경했습니다.
    scatter(X_all(idx), Y_all(idx), 15, 'w', 'filled', 'MarkerEdgeColor', 'k')
end

plot(xfit,yfit,'k--','LineWidth', 1.5)

xlabel('Peak pupil size (z-score)')
ylabel('Mic. pressure (z-score)')
box off;

set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');

%% ===== 신규 변수 상관관계 분석 (Pupil Max vs IBP Onset) =====

% 전체 개체 데이터 통합 및 Z-score 정규화 (Subject-wise)
P_all = []; % Pupil Max
O_all = []; % IBP Onset Pressure
group_id_new = [];

for i = 1:length(X_cell)
    % 개체별 데이터 로드
    p = X_cell{i};   % pupil max
    o = O_cell{i};   % IBP onset
    
    % 개체 내 정규화 (Z-score)
    pz = (p - mean(p)) ./ (std(p) + eps);
    oz = (o - mean(o)) ./ (std(o) + eps);
    
    P_all = [P_all; pz(:)];
    O_all = [O_all; oz(:)];
    group_id_new = [group_id_new; i*ones(length(pz),1)];
end

% 상관계수 계산
[R_p, P_p] = corr(P_all, O_all, 'Type', 'Pearson');
[R_s, P_s] = corr(P_all, O_all, 'Type', 'Spearman');

% 피어슨 상관계수 출력
fprintf('--- Pearson Correlation ---\n');
fprintf('Correlation Coefficient (R): %.4f\n', R_p);
fprintf('P-value: %.4e\n', P_p);
if P_p < 0.05
    fprintf('Result: Statistically Significant (*)\n');
else
    fprintf('Result: Not Significant\n');
end

fprintf('\n');

% 스피어맨 상관계수 출력
fprintf('--- Spearman Rank Correlation ---\n');
fprintf('Correlation Coefficient (rho): %.4f\n', R_s);
fprintf('P-value: %.4e\n', P_s);
if P_s < 0.05
    fprintf('Result: Statistically Significant (*)\n');
else
    fprintf('Result: Not Significant\n');
end

% 시각화
fig = figure(2); clf(fig);
set(fig, 'Units','centimeters');
set(fig, 'Position', [5 5 4.75 4.75]);
hold on;
colors = lines(length(X_cell));
for i = 1:length(X_cell)
    idx = group_id_new == i;
    scatter(P_all(idx), O_all(idx), 15, 'w', 'filled', 'MarkerEdgeColor', 'k')
end

% 추세선 추가
coef_p = polyfit(P_all, O_all, 1);
fit_p = polyval(coef_p, linspace(min(P_all), max(P_all), 100));
plot(linspace(min(P_all), max(P_all), 100), fit_p, 'k--', 'LineWidth', 1.5);

xlabel('Peak pupil size (z-score)');
ylabel('Thres. Pressure (z-score)');
% title('Correlation: Pupil Max vs. IBP Onset');
box off;

set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');

%% ===== 신규 변수 상관관계 분석 (Dilation Velocity vs IBP Onset) =====

% 전체 개체 데이터 통합 및 Z-score 정규화 (Subject-wise)
V_all = []; % Pupil Velocity
O_all = []; % IBP Onset Pressure
group_id_new = [];

for i = 1:length(V_cell)
    % 개체별 데이터 로드
    v = V_cell{i};   % pupil velocity
    o = O_cell{i};   % IBP onset
    
    % 개체 내 정규화 (Z-score)
    vz = (v - mean(v)) ./ (std(v) + eps);
    oz = (o - mean(o)) ./ (std(o) + eps);
    
    V_all = [V_all; vz(:)];
    O_all = [O_all; oz(:)];
    group_id_new = [group_id_new; i*ones(length(vz),1)];
end

% 상관계수 계산
[R_p, P_p] = corr(V_all, O_all, 'Type', 'Pearson');
[R_s, P_s] = corr(V_all, O_all, 'Type', 'Spearman');

% 피어슨 상관계수 출력
fprintf('--- Pearson Correlation ---\n');
fprintf('Correlation Coefficient (R): %.4f\n', R_p);
fprintf('P-value: %.4e\n', P_p);
if P_p < 0.05
    fprintf('Result: Statistically Significant (*)\n');
else
    fprintf('Result: Not Significant\n');
end

fprintf('\n');

% 스피어맨 상관계수 출력
fprintf('--- Spearman Rank Correlation ---\n');
fprintf('Correlation Coefficient (rho): %.4f\n', R_s);
fprintf('P-value: %.4e\n', P_s);
if P_s < 0.05
    fprintf('Result: Statistically Significant (*)\n');
else
    fprintf('Result: Not Significant\n');
end

% 시각화
fig = figure(3); clf(fig);                  % figure(3) 열고 초기화
set(fig, 'Units','centimeters');           
set(fig, 'Position', [5 5 4.75 4.75]);
hold on;
colors = lines(length(V_cell));
for i = 1:length(V_cell)
    idx = group_id_new == i;
    scatter(V_all(idx), O_all(idx), 15, 'w', 'filled', 'MarkerEdgeColor', 'k')
end

% 추세선 추가
coef_v = polyfit(V_all, O_all, 1);
fit_v = polyval(coef_v, linspace(min(V_all), max(V_all), 100));
plot(linspace(min(V_all), max(V_all), 100), fit_v, 'k--', 'LineWidth', 1.5);

xlabel('Pupil dilation velocity (z-score)');
ylabel('Thres. Pressure (z-score)');
% title('Correlation: Dilation Velocity vs. IBP Onset');
box off;

set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');

%% ===== 추가 분석 2: Pupil Velocity vs IBP Max =====

PV_all = [];   % Pupil Velocity
IM_all = [];   % IBP Max
group_id_pv_im = [];

for i = 1:length(X_cell)

    pv = V_cell{i};     % pupil_velocity_all
    im = Y_cell{i};     % ibp_max_all

    % subject-wise z-score
    pvz = (pv - mean(pv)) ./ (std(pv) + eps);
    imz = (im - mean(im)) ./ (std(im) + eps);

    PV_all = [PV_all; pvz(:)];
    IM_all = [IM_all; imz(:)];
    group_id_pv_im = [group_id_pv_im; i*ones(length(pvz),1)];
end

% Correlation
[R_p, P_p] = corr(PV_all, IM_all, 'Type','Pearson');
[R_s, P_s] = corr(PV_all, IM_all, 'Type','Spearman');

fprintf('\n===== Pupil Velocity vs IBP Max =====\n');
fprintf('Pearson  R = %.4f   p = %.4e\n', R_p, P_p);
fprintf('Spearman R = %.4f   p = %.4e\n', R_s, P_s);

% Visualization
fig = figure(4); clf(fig);
set(fig,'Units','centimeters');
set(fig,'Position',[5 5 4.75 4.75]);
hold on;

for i = 1:length(X_cell)
    idx = group_id_pv_im == i;
    scatter(PV_all(idx), IM_all(idx), 15, 'w', 'filled', 'MarkerEdgeColor','k')
end

coef = polyfit(PV_all, IM_all, 1);
xfit = linspace(min(PV_all), max(PV_all), 100);
yfit = polyval(coef, xfit);
plot(xfit, yfit, 'k--', 'LineWidth',1.5)

xlabel('Pupil dilation velocity (z-score)')
ylabel('Mic. pressure (z-score)')
box off;

set(findall(fig,'Type','text'),'FontSize',7,'FontName','Arial');
set(findall(fig,'Type','axes'),'FontSize',7,'FontName','Arial');