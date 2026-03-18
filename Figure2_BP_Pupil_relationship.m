%% Figure 2. 동공과 배뇨 간의 상관관계를 디테일하게 분석 진행
% Micturition에 대한 tTNS의 효과를 검증하기 위함
close all; clc; clear;
cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB'
addpath('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\Codes\function');
date_list = [0703 0710 0711 0714 0721 0722]; % 0721 0723도 확인한다?
% date_list = [0701 0703 0710 0711 0714 0722 0728]; 
% 해당 리스트는 250818, 데이터 괜찮은 애들만 추려놨음.

% date_list = [0703 0710 0711 0714 0722 260203 260209];

date_idx = 1;
for date = date_list
    exp_idx = 1;
    
    if date == 0710
        exp_list = [2 3]; % 2 3
    elseif date == 0711
        exp_list = [4]; % 4 5(?) 7(??) 9(??)
    elseif date == 0703
        exp_list = [1]; % 1 2(??)
    elseif date == 0701
        exp_list = [2]; % 단일
    elseif date == 0714
        exp_list = [1]; % 단일
    elseif date == 0721
        exp_list = [2]; %
    elseif date == 0722
        exp_list = [2 3]; % 1(??) 2 3ㅁ
    elseif date == 0723
        exp_list = [1]; % 1(??) 2 3ㅁ
    elseif date == 0728
        exp_list = [2]; % 2(?)
    else
        exp_list = [1]; % 2(?)
    end

    for exp_num = exp_list
        % Step 1. bladder data loading
        % load and filt the data
        if date == 260203 || date == 260209
            pathname = strcat('\\IMSNAS\main\11 데이터셋\02 Pupil-OAB\', num2str(date), '_baseline');
            cd(pathname);
            bladder_file = strcat(num2str(date, '%6d'),'_OAB_',num2str(exp_num),'.mat');
        else
            pathname = strcat('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\25', num2str(date, '%04d'),'_test');
            cd(pathname);
            bladder_file = strcat('25', num2str(date, '%04d'),'_OAB_',num2str(exp_num),'.mat');
        end
        load(bladder_file);
        Bladder.raw{date_idx, exp_idx} = double(b1(:,2)); 
        clear b1 m000

        % Bladder filtering
        fc_slope = 0.2; % 0.2
        fs = 100;
        [b, a] = butter(2, fc_slope/(fs/2));
        Bladder.filt{date_idx, exp_idx} = filtfilt(b, a, Bladder.raw{date_idx, exp_idx});
        Bladder.filt_down{date_idx, exp_idx} = downsample(Bladder.filt{date_idx, exp_idx},100,1);  % 1 Hz
        
        % step 2. Pupil data loading
        date_str = num2str(date, '%04d');
        if date == 260203 || date == 260209
            pupil_file = strcat('2026-',[date_str(3:4) '-' date_str(5:6)],'_video_',num2str(exp_num),'_pupil_area.csv');
        else
            pupil_file = strcat('2025-',[date_str(1:2) '-' date_str(3:4)],'_video_',num2str(exp_num),'_pupil_area_v3.csv');
        end
        
        pupil = readtable(pupil_file);
        Pupil.raw{date_idx, exp_idx} = pupil.FilteredArea; 
        clear date_str pupil

        % pupil 예외처리
        if date == 723 && exp_idx == 1
            Pupil.raw{date_idx,exp_idx} = Pupil.raw{date_idx,exp_idx}(1:31500);
        elseif date == 260203 && exp_idx == 1
            Pupil.raw{date_idx,exp_idx} = Pupil.raw{date_idx,exp_idx}(1:47000);
        elseif date == 260209 && exp_idx == 1
            Pupil.raw{date_idx,exp_idx} = Pupil.raw{date_idx,exp_idx}(1:36500);
        end

        % Pupil filtering
        fs = 10;
        fc_pupil = 0.05; %0.05
        [b, a] = butter(2, fc_pupil/(fs/2));
        Pupil.filt{date_idx, exp_idx} = filtfilt(b, a, Pupil.raw{date_idx, exp_idx});
        Pupil.filt_down{date_idx, exp_idx} = downsample(Pupil.filt{date_idx, exp_idx}, 10, 1);

        % 종료 시점 기준으로 데이터 길이 통일
        len_bladder = length(Bladder.filt_down{date_idx, exp_idx});
        len_pupil   = length(Pupil.filt_down{date_idx, exp_idx});
        
        min_len = min(len_bladder, len_pupil);
        
        Bladder.filt_down{date_idx, exp_idx} = Bladder.filt_down{date_idx, exp_idx}(end-min_len+1:end);
        Pupil.filt_down{date_idx, exp_idx}   = Pupil.filt_down{date_idx, exp_idx}(end-min_len+1:end);
        
        %%%% Micturition detecting %%%%
        slope_thresh = 0.35;
        cluster_time = 2;  % seconds
        min_group_length = 2;  % seconds
        [Bladder.slope_time{date_idx, exp_idx}, Bladder.slope_val{date_idx, exp_idx}] = detect_slope_increase(Bladder.filt_down{date_idx, exp_idx}-min(Bladder.filt_down{date_idx, exp_idx}), 1, slope_thresh, cluster_time, min_group_length);
    
        figure();
        plot(Bladder.filt_down{date_idx, exp_idx});
        xline(Bladder.slope_time{date_idx, exp_idx});

        if exp_num == 1 && date == 0703
            include_list = [1:5 7 9 10]; % 9, 19, 21은 애매하다.
        elseif exp_num == 2 && date == 0710
            include_list = [1 3:7 9 11 12]; % 9, 19, 21은 애매하다.
        elseif exp_num == 3 && date == 0710
            include_list = [1 2 4 5 7 9 10 12 13 15 16 17 18]; % 9, 19, 21은 애매하다.
        elseif exp_num == 4 && date == 0711
            include_list = [1 3 4 5 8 10];
        elseif exp_num == 1 && date == 0714 % ???
            include_list = [1 3 4 5 7:10 12 13 15:17 19 21]; % 22 24 25는 우선 제외함
        elseif exp_num == 2 && date == 0721
            include_list = [1:6]; % 9, 19, 21은 애매하다.
        elseif exp_num == 3 && date == 0721
            include_list = [1 3 4 7 8 10 12 13  14 16]; % 9, 19, 21은 애매하다.
        elseif exp_num == 2 && date == 0722
            include_list = [1:6]; % 9, 19, 21은 애매하다.
        elseif exp_num == 3 && date == 0722
            include_list = [1:7]; % 9, 19, 21은 애매하다.
        elseif exp_num == 1 && date == 0723
            include_list = [1:4 6 7 9:23]; % 9, 19, 21은 애매하다.
        elseif exp_num == 1 && date == 260203
            include_list = [1:5 7:9 11 12 19:29]; % 9, 19, 21은 애매하다.
        end

        Bladder.slope_time{date_idx, exp_idx} = Bladder.slope_time{date_idx, exp_idx}(include_list);
        Bladder.slope_val{date_idx, exp_idx} = Bladder.slope_val{date_idx, exp_idx}(include_list);
        
        

        %%%% pupil data detecting %%%%
        slope_thresh = max(Pupil.filt_down{date_idx, exp_idx})/80; % /30 worked in most of case
        cluster_time = 3;  % seconds
        min_group_length = 3;  % seconds
        [Pupil.slope_time{date_idx, exp_idx}, Pupil.slope_val{date_idx, exp_idx}] = detect_slope_increase(Pupil.filt_down{date_idx, exp_idx}, 1, slope_thresh, cluster_time, min_group_length);

        if exp_num == 1 && date == 0703
            pupil_list = [1:8];
        elseif exp_num == 2 && date == 0710
            pupil_list = [1:9];
        elseif exp_num == 3 && date == 0710
            pupil_list = [1:13]; % 방광압 14 누락됨.
        elseif exp_num == 4 && date == 0711
            pupil_list = [1 2 3 5 7 8];
        elseif exp_num == 1 && date == 0714 % ???
            pupil_list = [2 4 5 6 8 10 11 12 15 16 18 19 20 21 22]; % 방광압 16-18 안 찾아졌음
        elseif exp_num == 2 && date == 0721
            pupil_list = [2 3 6 7 8 9];
        elseif exp_num == 2 && date == 0722
            pupil_list = [1 2 3 5 6 9];
        elseif exp_num == 3 && date == 0722
            pupil_list = [1 2 4 7 8 10 15]; % 6 OR 7을 사용
        elseif exp_num == 1 && date == 260203
            pupil_list = [1:5 7:9 11 12 19:29]; % 6 OR 7을 사용
        end
        
        Pupil.slope_time{date_idx, exp_idx} = Pupil.slope_time{date_idx, exp_idx}(pupil_list);
        Pupil.slope_val{date_idx, exp_idx} = Pupil.slope_val{date_idx, exp_idx}(pupil_list);


        %% peak-peak interval 계산을 위하여...
        % Representative plotting용
        % 배뇨 peak 탐색 + CC 계산을 위하여 자극 이전 150초 - 이후 100초
        for i = 1:length(include_list)
            temp_data = Bladder.filt_down{date_idx, exp_idx};
            temp_idx = Bladder.slope_time{date_idx, exp_idx}(i);
            if temp_idx - 150 > 0
                if temp_idx+100 < length(temp_data)    
                    Bladder.part{date_idx, exp_idx}{i} = temp_data(temp_idx-150:temp_idx+100);
                else
                    Bladder.part{date_idx, exp_idx}{i} = temp_data(temp_idx-150:end);
                end
            else
                Bladder.part{date_idx, exp_idx}{i} = temp_data(1:temp_idx+100);
            end
            [pk, loc] = findpeaks(Bladder.part{date_idx, exp_idx}{i}(50:end), ...
                      'MinPeakHeight', max(Bladder.part{date_idx, exp_idx}{i}(50:end))*0.8);
            if ~isempty(pk)
                % 첫 번째 peak의 값과 위치 저장
                Bladder.peak_val{date_idx, exp_idx}(i)  = pk(1);
                Bladder.peak_time{date_idx, exp_idx}(i) = loc(1) + 49 + temp_idx; % 100:end 했으므로 index 보정
            else
                Bladder.peak_val{date_idx, exp_idx}(i)  = NaN;
                Bladder.peak_time{date_idx, exp_idx}(i) = NaN;
            end
        end

        % 방광 peak 탐색 + CC 계산을 위하여 자극 이전 150초 - 이후 100초 구간 데이터 획득
        for i = 1:length(pupil_list)
            temp_data = Pupil.filt_down{date_idx, exp_idx};
            temp_idx  = Pupil.slope_time{date_idx, exp_idx}(i);
            if temp_idx > 0
                if temp_idx+100 < length(temp_data)    
                    Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx:temp_idx+100);
                else
                    Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx:end);
                end
            else
                Pupil.part{date_idx, exp_idx}{i} = temp_data(1:temp_idx+100);
            end
            [pk, loc] = findpeaks(Pupil.part{date_idx, exp_idx}{i}(1:end), ...
                      'MinPeakHeight', max(Pupil.part{date_idx, exp_idx}{i}(1:end))*0.8);

            if ~isempty(pk)
                % 첫 번째 peak의 값과 위치 저장
                Pupil.peak_val{date_idx, exp_idx}(i)  = pk(1);
                Pupil.peak_time{date_idx, exp_idx}(i) = loc(1) + temp_idx; % 100:end 했으므로 index 보정
            else
                Pupil.peak_val{date_idx, exp_idx}(i)  = NaN;
                Pupil.peak_time{date_idx, exp_idx}(i) = NaN;
            end
        end

        % for j = 1:length(Pupil.part{date_idx,exp_idx})
        %     figure();
        %     plot(Pupil.part{date_idx,exp_idx}{j});
        % end

        % % 그래프용
        % for i = 1:length(include_list)
        %     temp_data = Bladder.filt_down{date_idx, exp_idx};
        %     temp_idx  = Bladder.slope_time{date_idx, exp_idx}(i);
        % 
        %     % temp_idx 이후 100샘플까지만
        %     if temp_idx + 100 <= length(temp_data)
        %         Bladder.part{date_idx, exp_idx}{i} = temp_data(temp_idx : temp_idx+100);
        %     else
        %         Bladder.part{date_idx, exp_idx}{i} = temp_data(temp_idx : end);
        %     end
        % 
        %     % peak 찾기
        %     part_data = Bladder.part{date_idx, exp_idx}{i};
        %     [pk, loc] = findpeaks(part_data, ...
        %                           'MinPeakHeight', max(part_data)*0.8);
        % 
        %     if ~isempty(pk)
        %         % 첫 번째 peak의 값과 위치 저장
        %         Bladder.peak_val{date_idx, exp_idx}(i)  = pk(1);
        %         Bladder.peak_time{date_idx, exp_idx}(i) = loc(1) + temp_idx - 1; 
        %         % loc은 part 내 index니까 원래 인덱스로 보정
        %     else
        %         Bladder.peak_val{date_idx, exp_idx}(i)  = NaN;
        %         Bladder.peak_time{date_idx, exp_idx}(i) = NaN;
        %     end
        % end
        % 
        % for i = 1:length(pupil_list)
        %     temp_data = Pupil.filt_down{date_idx, exp_idx};
        %     temp_idx  = Pupil.slope_time{date_idx, exp_idx}(i);
        % 
        %     % temp_idx 이후 100샘플까지만
        %     if temp_idx + 100 <= length(temp_data)
        %         Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx : temp_idx+100);
        %     else
        %         Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx : end);
        %     end
        % 
        %     % peak 찾기
        %     part_data = Pupil.part{date_idx, exp_idx}{i};
        %     [pk, loc] = findpeaks(part_data, ...
        %                           'MinPeakHeight', max(part_data)*0.8);
        % 
        %     if ~isempty(pk)
        %         % 첫 번째 peak의 값과 위치 저장
        %         Pupil.peak_val{date_idx, exp_idx}(i)  = pk(1);
        %         Pupil.peak_time{date_idx, exp_idx}(i) = loc(1) + temp_idx - 1; 
        %         % loc은 part 내 index니까 원래 인덱스로 보정
        %     else
        %         Pupil.peak_val{date_idx, exp_idx}(i)  = NaN;
        %         Pupil.peak_time{date_idx, exp_idx}(i) = NaN;
        %     end
        % end

        %% Peak 잘 detect 되었는지 체크용
        figure();
        sgtitle(strcat(num2str(date), '-',num2str(exp_num)));
        subplot(2,1,1);
        plot(Bladder.filt_down{date_idx, exp_idx})
        hold on;
        for i = 1:length(Bladder.slope_time{date_idx, exp_idx})
            xline(Bladder.slope_time{date_idx, exp_idx}(i), 'k--', ...
                'Label', num2str(i), ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'bottom');
        end

        subplot(2,1,2);
        plot(Pupil.filt_down{date_idx, exp_idx});
        hold on;
        for i = 1:length(Pupil.slope_time{date_idx, exp_idx})
            xline(Pupil.slope_time{date_idx, exp_idx}(i), 'k--', ...
                'Label', num2str(i), ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'bottom');
        end

        for i = 1:length(Pupil.peak_time{date_idx, exp_idx})
            xline(Pupil.peak_time{date_idx, exp_idx}(i), 'k:', ...
                'Label', num2str(i), ...
                'LabelOrientation', 'horizontal', ...
                'LabelVerticalAlignment', 'bottom');
        end
        exp_idx = exp_idx+1;
    end
    clear a b
    date_idx = date_idx+1;
end


%% Figure 4-a. Representative plot
fig = figure(2); clf(fig);                 % figure(2) 열고 초기화
set(fig, 'Units','centimeters');           % 단위: cm
set(fig, 'Position', [5 5 8 4]);   
% 1 1 3
for i = 1
    for j = 1
        for k = 7
            % Bladder (왼쪽 y축, 빨강)
            yyaxis left
            plot(Bladder.part{i,j}{k}, 'LineWidth', 1.2, 'Color', 'r');
            ylabel('IBP (mmHg)', 'Color', 'r');    % 라벨 색상도 빨강으로
            hold on;
            axis tight;
            ylim([12, 35]);
            
            % y축(틱/축선) 색상 설정
            ax = gca;
            ax.YAxis(1).Color = [1 0 0];           % 왼쪽 y축(틱/축선) 빨강
            
            % Pupil (오른쪽 y축, 검정)
            yyaxis right
            x = Pupil.part{i,j}{k};
            mn = min(x); mx = max(x);
            x_norm = (mx > mn) * (x - mn) / max(eps, (mx - mn));  % 0-1 정규화
            plot(x_norm, 'LineWidth', 1.2, 'Color', 'k');
            ylabel('Pupil size (Norm.)', 'Color', 'k');           % 라벨 색상 검정
            axis tight;
            ylim([0, 1.1])
            
            % 오른쪽 y축(틱/축선) 색상 설정
            ax.YAxis(2).Color = [0 0 0];           % 오른쪽 y축 검정

        end
    end
end

xlabel('Time(s)');
set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');

%% Figure 3-b 개체별 동공-배뇨 반응 연관성 (Cross correlation)
% %% 동공 반응과 배뇨 반응 간의 연관성
% idx = 1;
% for i = 1:6
%     for j = 1:2
%         for k = 1:length(Bladder.part{i,j})
%             temp_bp = Bladder.part{i,j}{k};
%             temp_pupil = Pupil.part{i,j}{k};
% 
%             % 두 벡터 길이 맞추기
%             min_len = min(length(temp_bp), length(temp_pupil));
%             temp_bp = temp_bp(1:min_len);
%             temp_pupil = temp_pupil(1:min_len);
% 
%             % 상관계수 계산
%             [xc, lags] = xcorr(temp_bp, temp_pupil, 'coeff');  % 교차상관
%             [CC_val(idx), idx_max] = max(xc);                      % 최대 상관값
%             lag_at_max(idx) = lags(idx_max);                       % 최대 상관값일 때의 지연
%             idx = idx+1;
%         end
%     end
% end
% 
% % CC_val plotting (정리/수정 버전)
% fig = figure(1); clf(fig);
% set(fig, 'Units','centimeters','Position',[5 5 3.5 4]);  % Figure 크기
% 
% ax = axes('Parent', fig); 
% hold(ax, 'on');
% 
% % --- boxplot ---
% h = boxplot(ax, CC_val, 'Labels', {'CC'}, ...
%     'Colors', 'k', 'Widths', 0.3, 'Symbol', '');
% set(h, {'LineWidth'}, {1.2});
% 
% % --- 모든 line component를 실선으로 ---
% allLines = findobj(ax, 'Type', 'Line');
% set(allLines, 'LineStyle', '-', 'Color', 'k');
% 
% % --- 박스 색상 채우기 (붉은색, 투명도 50%) ---
% boxes = findobj(ax, 'Tag', 'Box');
% for j = 1:length(boxes)
%     patch(get(boxes(j), 'XData'), get(boxes(j), 'YData'), ...
%           [1 0 0], 'FaceAlpha', 0.5, 'EdgeColor', 'k');
% end
% 
% % --- scatter (흰 내부 + 검정 테두리, 약한 jitter) ---
% num_points  = numel(CC_val);
% x_jittered  = 1 + (rand(num_points,1) - 0.5) * 0.05;
% scatter(ax, x_jittered, CC_val, 8, ...
%     'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
% 
% % --- 축/라벨/범위 ---
% xlim(ax, [0.5 1.5]);               % 박스 중앙 정렬
% ylim(ax, [0.4 1]);                  % 필요시 조정
% ylabel(ax, 'Correlation coefficient');
% box(ax, 'off'); grid(ax, 'off');
% 
% % --- 폰트 통일 ---
% set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
% set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');
% 
% fprintf('CC_val: mean = %.3f, median = %.3f\n', mean(CC_val),median(CC_val));

CC_by_subj_cond = cell(6,2);  % 개체×조건별 CC 모으기

for i = 1:6
    for j = 1:2
        for k = 1:length(Bladder.part{i,j})
            temp_bp    = Bladder.part{i,j}{k};
            temp_pupil = Pupil.part{i,j}{k};
            min_len = min(length(temp_bp), length(temp_pupil));
            [xc,~] = xcorr(temp_bp(1:min_len), temp_pupil(1:min_len), 'coeff');
            CC_by_subj_cond{i,j}(end+1,1) = max(xc);
        end
    end
end

% 개체별 trial-weighted 평균 (모든 trial 합쳐서 평균)
CC_mean_trialWeighted = nan(6,1);
for i = 1:6
    all_trials = [CC_by_subj_cond{i,1}; CC_by_subj_cond{i,2}];
    CC_mean_trialWeighted(i) = mean(all_trials,'omitnan');
end

% === 개체별 trial-weighted 평균 데이터 준비 ===
m = CC_mean_trialWeighted(:);
m = m(isfinite(m));   % NaN 제거(박스/산점도 모두 동일 기준)

% === Figure 생성 ===
fig = figure; clf(fig);
set(fig, 'Units','centimeters','Position',[5 5 3.5 4]);  % 창 크기

ax = axes('Parent', fig); hold(ax, 'on');

% --- boxplot (outlier 심볼 제거, 얇은 폭) ---
h = boxplot(ax, m, 'Labels', {'CC (mean)'}, ...
    'Colors', 'k', 'Widths', 0.3, 'Symbol', '');
set(h, {'LineWidth'}, {1.2});

% --- 모든 line component를 실선으로 변경 ---
allLines = findobj(ax, 'Type', 'Line');
set(allLines, 'LineStyle', '-', 'Color', 'k');

% --- 박스 색상 채우기 (붉은색, 투명도 50%) ---
boxes = findobj(ax, 'Tag', 'Box');
for j = 1:length(boxes)
    patch(get(boxes(j), 'XData'), get(boxes(j), 'YData'), ...
          [1 0 0], 'FaceAlpha', 0.5, 'EdgeColor', 'k');
end

% --- 산점도 (흰 내부 + 검정 테두리, 가벼운 jitter) ---
xj = 1 + (rand(numel(m),1) - 0.5) * 0.05;
scatter(ax, xj, m, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% --- 축/레이블/범위 ---
xlim(ax, [0.5 1.5]);                % 박스 중앙 정렬
ylabel(ax, 'Mean correlation');
ylim(ax, [0.5 1]);                  % 필요 시 조정
box(ax, 'off'); grid(ax, 'off');


% --- 폰트 통일 ---
set(findall(fig,'Type','text'), 'FontSize', 7, 'FontName', 'Arial');
set(findall(fig,'Type','axes'), 'FontSize', 7, 'FontName', 'Arial');

% === 평균/중앙값 및 사분위수 계산 및 출력 ===
mu = mean(m, 'omitnan');
md = median(m, 'omitnan');
q1 = quantile(m, 0.25);
q3 = quantile(m, 0.75);

fprintf('Trial-weighted CC mean   = %.4f\n', mu);
fprintf('Trial-weighted CC median = %.4f\n', md);
fprintf('Trial-weighted CC median [Q1, Q3] = %.4f [%.4f, %.4f]\n', md, q1, q3);

%% === Figure 3-c. slope_time 기반 violin + scatter ===
idx = 1;
predict_time = []; % 초기화

for i = 1:6
    for j = 1:2
        temp_bp = Bladder.slope_time{i,j};
        temp_pupil = Pupil.slope_time{i,j};
        
        if ~isempty(temp_bp) && ~isempty(temp_pupil)
            for k = 1:min(length(temp_bp), length(temp_pupil))
                predict_time(idx) = - temp_pupil(k) + temp_bp(k);
                idx = idx + 1;
            end
        end
    end
end

data = predict_time(:);

% 사분위수 및 통계량 계산
Q1 = quantile(data, 0.25);
Q2 = median(data);
Q3 = quantile(data, 0.75);
mu = mean(data,'omitnan');
sd = std(data,'omitnan'); 

% 밀도 추정
[f, xi] = ksdensity(data);
y_jitter = (rand(size(data)) - 0.5) * 0.3;

close all;
figure(3); hold on;
set(gcf, 'Units','centimeters','Position',[5 5 7 2]);

fill([xi fliplr(xi)], ...
     [f -fliplr(f)]/max(f)*0.45, ...
     [1 0.5 0.5], 'FaceAlpha',1, 'EdgeColor','none');

scatter(data, y_jitter, 5, ...
    'MarkerFaceColor','r', 'MarkerEdgeColor','k', ...
    'LineWidth',0.2, 'MarkerFaceAlpha',0.5, 'MarkerEdgeAlpha',0);

% plot([Q1 Q1], [-0.2 0.2], 'r-', 'LineWidth',1);
% plot([Q2 Q2], [-0.25 0.25], 'b-', 'LineWidth',1.2);
% plot([Q3 Q3], [-0.2 0.2], 'r-', 'LineWidth',1);

fprintf('[Slope_time] Median [Q1, Q3] = %.3f [%.3f, %.3f]\n', Q2, Q1, Q3);
fprintf('[Slope_time] Mean ± SD = %.3f ± %.3f\n\n', mu, sd);

ylim([-0.5 0.5]); yticks([]); xlabel('Micturition detection time (s)');
% xticks([-50 0 50 100]); xticklabels({'-50','0','50','100'});
% xlim([-50, 100]); box off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7 );
xline(0,'k:')

%% === Figure 4-C2  peak_time 기반 violin + scatter ===
idx = 1;
predict_time = [];

for i = 1:6
    for j = 1:2
        temp_bp = Bladder.slope_time{i,j};
        temp_pupil = Pupil.peak_time{i,j};
        
        if ~isempty(temp_bp) && ~isempty(temp_pupil)
            for k = 1:min(length(temp_bp), length(temp_pupil))
                predict_time(idx) = -temp_pupil(k) + temp_bp(k);
                idx = idx + 1;
            end
        end
    end
end

data = predict_time(:);

% 사분위수 및 통계량 계산
Q1 = quantile(data, 0.25);
Q2 = median(data);
Q3 = quantile(data, 0.75);
mu = mean(data,'omitnan');
sd = std(data,'omitnan');

% 밀도 추정
[f, xi] = ksdensity(data);
y_jitter = (rand(size(data)) - 0.5) * 0.3;

% Figure
figure(4); hold on;
set(gcf, 'Units','centimeters','Position',[13 5 7 2]);

fill([xi fliplr(xi)], ...
     [f -fliplr(f)]/max(f)*0.45, ...
     [0.5 0.5 1], 'FaceAlpha',1, 'EdgeColor','none');

scatter(data, y_jitter, 5, ...
    'MarkerFaceColor','b', 'MarkerEdgeColor','k', ...
    'LineWidth',0.2, 'MarkerFaceAlpha',0.5, 'MarkerEdgeAlpha',0);

% plot([Q1 Q1], [-0.2 0.2], 'b-', 'LineWidth',1);
% plot([Q2 Q2], [-0.25 0.25], 'r-', 'LineWidth',1.2);
% plot([Q3 Q3], [-0.2 0.2], 'b-', 'LineWidth',1);

fprintf('[Peak_time] Median [Q1, Q3] = %.3f [%.3f, %.3f]\n', Q2, Q1, Q3);
fprintf('[Peak_time] Mean ± SD = %.3f ± %.3f\n\n', mu, sd);

ylim([-0.5 0.5]); yticks([]); xlabel('Micturition detection time (s)');
box off;
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

xline(0,'k:')


%% Figure 4-d 동공 최대 크기 - 방광압 최대 크기 비교 (연관 없기를 기대함)
idx = 1;
predict_time = []; % 미리 초기화
animal_list = [1];
for i = 1:6
    for j = 1:2
        for k = 1:length(Bladder.peak_val{i,j})
            temp_bp = Bladder.peak_val{i,j}(k);
            temp_pupil = Pupil.peak_val{i,j}(k);
            
            % 비어있는 cell은 건너뛰기
            
            if ~isempty(temp_bp) && ~isempty(temp_pupil)
                for k = 1:min(length(temp_bp), length(temp_pupil))
                    peak_bp(idx) = temp_bp(1);
                    peak_pupil(idx) = temp_pupil(1);
                    idx = idx + 1;
                end
            end
        end
    end
    
    animal_list = [animal_list idx];
end

num_animals = length(animal_list)-1;  % 개체 수
mean_bp = nan(1, num_animals);
mean_pupil = nan(1, num_animals);

for a = 1:num_animals
    idx_start = animal_list(a);
    idx_end   = animal_list(a+1) - 1;

    mean_bp(a)     = mean(peak_bp(idx_start:idx_end), 'omitnan');
    mean_pupil(a)  = mean(peak_pupil(idx_start:idx_end), 'omitnan');
end

%%%%%%%%%%%%%%%%%% 상관계수 계산 %%%%%%%%%%%%%%%%%%%%%
% Z-score 정규화
bp_z    = (peak_bp   - mean(peak_bp,'omitnan'))   ./ std(peak_bp,'omitnan');
pupil_z = (peak_pupil - mean(peak_pupil,'omitnan')) ./ std(peak_pupil,'omitnan');

% 상관계수 계산
[r, p] = corrcoef(bp_z, pupil_z,'Rows','pairwise');
fprintf('Correlation (Z-score) r=%.3f, p=%.3f\n', r(1,2), p(1,2));

% 산점도
figure(5); set(gcf, 'Units','centimeters','Position',[10 5 4 4]); hold on;
scatter(bp_z', pupil_z', 8, ...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 회귀직선 추가
coeffs = polyfit(bp_z, pupil_z, 1);    % 1차 회귀계수 [slope, intercept]
x_fit = linspace(min(bp_z), max(bp_z), 100);
y_fit = polyval(coeffs, x_fit);
plot(x_fit, y_fit, 'r-', 'LineWidth',1);

xlabel('Mic. pressure (z-score)');
ylabel('Max. Pupil size (z-score)');
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize',7);

% 회귀모델 적합
mdl = fitlm(peak_bp(:), peak_pupil(:));

% R² 값 출력
R2 = mdl.Rsquared.Ordinary;
R2_adj = mdl.Rsquared.Adjusted;

fprintf('R² = %.3f, Adjusted R² = %.3f\n', R2, R2_adj);

%% Figure 4-e-1 동공 micturition threshold - Micturition threshold pressure 비교 (연관 없기를 기대함)
idx = 1;
predict_time = []; % 미리 초기화
animal_list = [1];
for i = 1:6
    for j = 1:2
        for k = 1:length(Bladder.slope_val{i,j})
            temp_bp = Bladder.slope_val{i,j}(k);
            temp_pupil = Pupil.slope_val{i,j}(k);
            
            % 비어있는 cell은 건너뛰기
            
            if ~isempty(temp_bp) && ~isempty(temp_pupil)
                for k = 1:min(length(temp_bp), length(temp_pupil))
                    slope_bp(idx) = temp_bp(1);
                    slope_pupil(idx) = temp_pupil(1);
                    idx = idx + 1;
                end
            end
        end
    end
    
    animal_list = [animal_list idx];
end

num_animals = length(animal_list)-1;  % 개체 수
mean_bp = nan(1, num_animals);
mean_pupil = nan(1, num_animals);

for a = 1:num_animals
    idx_start = animal_list(a);
    idx_end   = animal_list(a+1) - 1;

    mean_bp(a)     = mean(slope_bp(idx_start:idx_end), 'omitnan');
    mean_pupil(a)  = mean(slope_pupil(idx_start:idx_end), 'omitnan');
end

%%%%%%%%%%%%%%%%%% 상관계수 계산 %%%%%%%%%%%%%%%%%%%%%
% Z-score 정규화
bp_z_slope    = (slope_bp   - mean(slope_bp,'omitnan'))   ./ std(slope_bp,'omitnan');
pupil_z_slope = (slope_pupil - mean(slope_pupil,'omitnan')) ./ std(slope_pupil,'omitnan');

% 상관계수 계산
[r_slope, p_slope] = corrcoef(bp_z_slope, pupil_z_slope,'Rows','pairwise');
fprintf('Correlation (Z-score) r=%.3f, p=%.3f\n', r_slope(1,2), p_slope(1,2));

% 산점도
figure(7); set(gcf, 'Units','centimeters','Position',[10 10 4 4]); hold on;
scatter(bp_z_slope', pupil_z_slope', 8, ...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 회귀직선 추가
coeffs = polyfit(bp_z_slope, pupil_z_slope, 1);    % 1차 회귀계수 [slope, intercept]
x_fit = linspace(min(bp_z_slope), max(bp_z_slope), 100);
y_fit = polyval(coeffs, x_fit);
plot(x_fit, y_fit, 'r-', 'LineWidth',1);

xlabel('Threshold Pressure (z-score)');
ylabel('Pupil size (z-score)');
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

% 회귀모델 적합
mdl = fitlm(slope_bp(:), slope_pupil(:));

% R² 값 출력
R2 = mdl.Rsquared.Ordinary;
R2_adj = mdl.Rsquared.Adjusted;

fprintf('R² = %.3f, Adjusted R² = %.3f\n', R2, R2_adj);

%% Figure 4-e-2 동공 peak - Micturition threshold pressure 비교 (연관 없기를 기대함)
idx = 1;
predict_time = []; % 미리 초기화
animal_list = [1];
for i = 1:6
    for j = 1:2
        for k = 1:length(Bladder.slope_val{i,j})
            temp_bp = Bladder.slope_val{i,j}(k);
            temp_pupil = Pupil.peak_val{i,j}(k);
            
            % 비어있는 cell은 건너뛰기
            
            if ~isempty(temp_bp) && ~isempty(temp_pupil)
                for k = 1:min(length(temp_bp), length(temp_pupil))
                    slope_bp(idx) = temp_bp(1);
                    slope_pupil(idx) = temp_pupil(1);
                    idx = idx + 1;
                end
            end
        end
    end
    
    animal_list = [animal_list idx];
end

num_animals = length(animal_list)-1;  % 개체 수
mean_bp = nan(1, num_animals);
mean_pupil = nan(1, num_animals);

for a = 1:num_animals
    idx_start = animal_list(a);
    idx_end   = animal_list(a+1) - 1;

    mean_bp(a)     = mean(slope_bp(idx_start:idx_end), 'omitnan');
    mean_pupil(a)  = mean(slope_pupil(idx_start:idx_end), 'omitnan');
end

%%%%%%%%%%%%%%%%%% 상관계수 계산 %%%%%%%%%%%%%%%%%%%%%
% Z-score 정규화
bp_z_slope    = (slope_bp   - mean(slope_bp,'omitnan'))   ./ std(slope_bp,'omitnan');
pupil_z_slope = (slope_pupil - mean(slope_pupil,'omitnan')) ./ std(slope_pupil,'omitnan');

% 상관계수 계산
[r_slope, p_slope] = corrcoef(bp_z_slope, pupil_z_slope,'Rows','pairwise');
fprintf('Correlation (Z-score) r=%.3f, p=%.3f\n', r_slope(1,2), p_slope(1,2));

% 산점도
figure(8); set(gcf, 'Units','centimeters','Position',[15 10 4 4]); hold on;
scatter(bp_z_slope', pupil_z_slope', 8, ...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 회귀직선 추가
coeffs = polyfit(bp_z_slope, pupil_z_slope, 1);    % 1차 회귀계수 [slope, intercept]
x_fit = linspace(min(bp_z_slope), max(bp_z_slope), 100);
y_fit = polyval(coeffs, x_fit);
plot(x_fit, y_fit, 'r-', 'LineWidth',1);

xlabel('Threshold Pressure (z-score)');
ylabel('Max. Pupil size (z-score)');
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

% 회귀모델 적합
mdl = fitlm(slope_bp(:), slope_pupil(:));

% R² 값 출력
R2 = mdl.Rsquared.Ordinary;
R2_adj = mdl.Rsquared.Adjusted;

fprintf('R² = %.3f, Adjusted R² = %.3f\n', R2, R2_adj);


%% Figure 4-e-3 동공 확장 속도? - Micturition threshold pressure 비교 (연관 없기를 기대함)
idx = 1;
predict_time = []; % 미리 초기화
animal_list = [1];
for i = 1:6
    for j = 1:2
        for k = 1:length(Bladder.slope_val{i,j})
            temp_bp = Bladder.slope_val{i,j}(k);
            temp_pupil = Pupil.slope_val{i,j}(k);
            
            % 비어있는 cell은 건너뛰기
            
            if ~isempty(temp_bp) && ~isempty(temp_pupil)
                for k = 1:min(length(temp_bp), length(temp_pupil))
                    slope_bp(idx) = temp_bp(1);
                    slope_pupil(idx) = temp_pupil(1);
                    idx = idx + 1;
                end
            end
        end
    end
    
    animal_list = [animal_list idx];
end

num_animals = length(animal_list)-1;  % 개체 수
mean_bp = nan(1, num_animals);
mean_pupil = nan(1, num_animals);

for a = 1:num_animals
    idx_start = animal_list(a);
    idx_end   = animal_list(a+1) - 1;

    mean_bp(a)     = mean(slope_bp(idx_start:idx_end), 'omitnan');
    mean_pupil(a)  = mean(slope_pupil(idx_start:idx_end), 'omitnan');
end

%%%%%%%%%%%%%%%%%% 상관계수 계산 %%%%%%%%%%%%%%%%%%%%%
% Z-score 정규화
bp_z_slope    = (slope_bp   - mean(slope_bp,'omitnan'))   ./ std(slope_bp,'omitnan');
pupil_z_slope = (slope_pupil - mean(slope_pupil,'omitnan')) ./ std(slope_pupil,'omitnan');

% 상관계수 계산
[r_slope, p_slope] = corrcoef(pupil_z_slope, bp_z_slope, 'Rows','pairwise');
fprintf('Correlation (Z-score) r=%.3f, p=%.3f\n', r_slope(1,2), p_slope(1,2));

% 산점도
figure(7); set(gcf, 'Units','centimeters','Position',[10 10 3.5 4]); hold on;
scatter(pupil_z_slope', bp_z_slope', 8, ...
        'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

% 회귀직선 추가
coeffs = polyfit(pupil_z_slope, bp_z_slope, 1);    % 1차 회귀계수 [slope, intercept]
x_fit = linspace(min(bp_z_slope), max(bp_z_slope), 100);
y_fit = polyval(coeffs, x_fit);
plot(x_fit, y_fit, 'r-', 'LineWidth',1);

xlabel('Mic. Pressure (z-score)'); ylabel('Pupil size (z-score)');
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

% 회귀모델 적합
mdl = fitlm(slope_bp(:), slope_pupil(:));

% R² 값 출력
R2 = mdl.Rsquared.Ordinary;
R2_adj = mdl.Rsquared.Adjusted;

fprintf('R² = %.3f, Adjusted R² = %.3f\n', R2, R2_adj);

%% Figure 4-f. Pupil이 확대되는 정도를 분석함
pupil_area = zeros(6,1);
for i = 1:6
    idx = 1;
    for j = 1:2
        for k = 1:length(Pupil.slope_val{i,j})
            % pupil_area(i,idx) = abs(Pupil.peak_val{i,j}(k)/Pupil.slope_val{i,j}(k)); % 기존 동공 상대 변화 기준
            pupil_area(i,idx) = abs(Pupil.peak_val{i,j}(k)/mean(Pupil.filt_down{i,j}));
            idx = idx+1;
        end
    end
end
pupil_area(pupil_area == 0) = NaN;

% === 1. 전체 데이터 boxplot + scatter (0 제외) ===
all_data = pupil_area(:);
all_data = all_data(all_data~=0 & ~isnan(all_data));  % 0, NaN 제외

fig1 = figure; clf(fig1);
set(fig1, 'Units','centimeters','Position',[5 5 3 4]);
ax1 = axes('Parent', fig1); hold(ax1, 'on');

% --- boxplot ---
h1 = boxplot(ax1, all_data, 'Labels', {' '}, ...
    'Colors','k','Widths',0.3,'Symbol','');
set(h1, {'LineWidth'}, {1.2});

% --- 모든 line component를 실선/검정으로 ---
allLines = findobj(ax1, 'Type', 'Line');
set(allLines, 'LineStyle', '-', 'Color', 'k');

% --- 박스 색상 채우기 (빨강, 투명도 50%) ---
boxes = findobj(ax1, 'Tag', 'Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), ...
          [1 1 1], 'FaceAlpha',0.5,'EdgeColor','k');
end

% --- 산점도 (흰 내부 + 검정 테두리, jitter 추가) ---
xj = 1 + (rand(numel(all_data),1)-0.5)*0.05;
scatter(ax1, xj, all_data, 8, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

ylabel(ax1,'\DeltaRelative Pupil Area');
xlim(ax1,[0.5 1.5]); box(ax1,'off'); grid(ax1,'off');

% --- 폰트 ---
set(findall(fig1,'Type','text'), 'FontSize', 7, 'FontName','Arial');
set(findall(fig1,'Type','axes'), 'FontSize', 7, 'FontName','Arial');

% --- 통계값 계산 및 출력 ---
mu_all = mean(all_data,'omitnan');
md_all = median(all_data,'omitnan');
q1_all = quantile(all_data,0.25);
q3_all = quantile(all_data,0.75);

fprintf('[All data] mean = %.4f, median = %.4f, [Q1,Q3] = %.4f [%.4f, %.4f]\n', ...
    mu_all, md_all, md_all, q1_all, q3_all);


%% Pupil dilation 정도 분석
row_means = mean(pupil_area, 2, 'omitnan');
row_means = row_means(row_means~=0 & ~isnan(row_means));  % 0, NaN 제외

fig2 = figure; clf(fig2);
set(fig2, 'Units','centimeters','Position',[5 9 3.5 4]);
ax2 = axes('Parent', fig2); hold(ax2, 'on');

h2 = boxplot(ax2, row_means, 'Labels', {' '}, ...
    'Colors','k','Widths',0.3,'Symbol','');
set(h2, {'LineWidth'}, {1.2});

allLines = findobj(ax2, 'Type', 'Line');
set(allLines, 'LineStyle', '-', 'Color', 'k');

boxes = findobj(ax2, 'Tag', 'Box');
for j = 1:length(boxes)
    patch(get(boxes(j),'XData'), get(boxes(j),'YData'), ...
          [1 1 1], 'FaceAlpha', 0.1,'EdgeColor','k');
end

xj = 1 + (rand(numel(row_means),1)-0.5)*0.05;
scatter(ax2, xj, row_means, 10, ...
    'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);

ylabel(ax2,'Relative pupil size (fold)');
xlim(ax2,[0.5 1.5]); box(ax2,'off'); grid(ax2,'off');
ylim([0.5 7]);
yline(1, 'k:')
 
set(findall(fig2,'Type','text'), 'FontSize',7, 'FontName','Arial');
set(findall(fig2,'Type','axes'), 'FontSize',7, 'FontName','Arial');

% --- 통계값 계산 및 출력 ---
mu_row = mean(row_means,'omitnan');
md_row = median(row_means,'omitnan');
q1_row = quantile(row_means,0.25);
q3_row = quantile(row_means,0.75);

fprintf('[Row means] mean = %.4f, median = %.4f, [Q1,Q3] = %.4f [%.4f, %.4f]\n', ...
    mu_row, md_row, md_row, q1_row, q3_row);

% --- Median 선 색상 강조 ---
hMedian = findobj(gca, 'Tag', 'Median');
set(hMedian, 'Color', [0.9 0 0], 'LineWidth', 1.2);  % 빨간색, 약간 두껍게