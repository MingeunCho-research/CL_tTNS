%% Figure 2. 동공과 배뇨 간의 상관관계를 디테일하게 분석 진행
% Micturition에 대한 tTNS의 효과를 검증하기 위함
close all; clc; clear;
cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB'
addpath('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\Codes\function');
date_list = [0911]; 

date_idx = 1;
for date = date_list
    exp_idx = 1;
    pathname = strcat('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\25', num2str(date, '%04d'),'_test');
    cd(pathname);

    exp_list = [3];

    for exp_num = exp_list
        % Step 1. bladder data loading
        % load and filt the data
        bladder_file = strcat('25', num2str(date, '%04d'),'_OAB_',num2str(exp_num),'.mat');
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
        pupil_file = strcat('2025-',[date_str(1:2) '-' date_str(3:4)],'_video_',num2str(exp_num),'_pupil_area.csv');
        pupil = readtable(pupil_file);
        Pupil.raw{date_idx, exp_idx} = pupil.FilteredArea; 
        clear date_str pupil

        % pupil 예외처리
        if date == 723 && exp_idx == 1
            Pupil.raw{date_idx,exp_idx} = Pupil.raw{date_idx,exp_idx}(1:31500);
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
         
        baseline = mean(Pupil.filt_down{date_idx, exp_idx}(1:30));
        temp_pupil_norm = Pupil.filt_down{date_idx, exp_idx} / baseline;

        %% Pupil detection
        slope_threshold = 0.1;
        group_gap_sec = 5;
        min_group_len = 5;
        amp_delta_min = 1;
        min_event_gap = 20;
        events = detectPupilEvents(temp_pupil_norm, slope_threshold, group_gap_sec, min_group_len, amp_delta_min, min_event_gap);
        
        figure();
        subplot(2,1,1)
        plot(Bladder.filt_down{date_idx, exp_idx});
        axis tight

        subplot(2,1,2)
        plot(temp_pupil_norm);
        xline(events(:,1));
        axis tight
        ylim([0,10]);


        %%
        exp_idx = exp_idx+1;
    end
    date_idx = date_idx+1;
end


%%
function events = detectPupilEvents(pupil_data, slope_threshold, group_gap_sec, min_group_len, amp_delta_min, min_event_gap)
% detectPupilEvents : pupil_data에서 이벤트 탐지
%
% 입력:
%   pupil_data      : 1 Hz 정규화 pupil 데이터 (벡터)
%   slope_threshold : 기울기 임계값 (예: 0.1 → 초당 0.1 이상 상승)
%   group_gap_sec   : 그룹 간 간격 임계값 (초)
%   min_group_len   : 그룹 최소 길이 (초)
%   amp_delta_min   : 시작→피크 최소 Δ (단위: 정규화 값)
%   min_event_gap   : 이벤트 최소 간격 (초)
%
% 출력:
%   events : [t_start, t_peak, interval] 행렬
%            t_start = 이벤트 시작 시점 (초)
%            t_peak  = 피크 시점 (초)
%            interval = 이전 이벤트 시작~현재 이벤트 시작 간격 (초)

    if isempty(pupil_data)
        events = [];
        return;
    end

    % --- 기울기 계산 ---
    dy = diff(pupil_data);
    t  = 0:(length(pupil_data)-1);  % 초 단위 time axis (1 Hz 가정)

    rising_idx = find(dy > slope_threshold);

    % 그룹핑
    groups = {};
    if ~isempty(rising_idx)
        group = rising_idx(1);
        for k = 2:length(rising_idx)
            if (rising_idx(k) - rising_idx(k-1)) <= group_gap_sec
                group(end+1) = rising_idx(k); %#ok<AGROW>
            else
                groups{end+1} = group; %#ok<AGROW>
                group = rising_idx(k);
            end
        end
        groups{end+1} = group;
    end

    events = [];
    last_event_start = -inf;

    % 각 그룹 검사
    for g = 1:length(groups)
        idxs = groups{g};
        if length(idxs) < min_group_len
            continue;
        end
        t_start = idxs(1);
        t_end   = idxs(end);

        [peak_val, rel_idx] = max(pupil_data(t_start:t_end));
        t_peak = t_start + rel_idx - 1;

        amp_delta = peak_val - pupil_data(t_start);
        if amp_delta < amp_delta_min
            continue;
        end

        % 최소 이벤트 간격 조건
        if (t_start - last_event_start) < min_event_gap
            continue;
        end

        if isfinite(last_event_start)
            interval = t_start - last_event_start;
        else
            interval = NaN;
        end

        events(end+1, :) = [t_start, t_peak, interval]; %#ok<AGROW>
        last_event_start = t_start;
    end
end
