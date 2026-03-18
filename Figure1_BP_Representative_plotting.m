%% Figure 2. 동공과 배뇨 간의 상관관계를 디테일하게 분석 진행
% Micturition에 대한 tTNS의 효과를 검증하기 위함
close all; clc; clear;
cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB'
addpath('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\Codes\function');
date_list = [0722]; % 0721 0723도 확인한다?
% date_list = 0728;
% date_list = [0701 0703 0710 0711 0714 0722 0728]; 
% 해당 리스트는 250818, 데이터 괜찮은 애들만 추려놨음. 

date_idx = 1;
for date = date_list
    exp_idx = 1;
    pathname = strcat('C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\25', num2str(date, '%04d'),'_test');
    cd(pathname);

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
    end

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
        pupil_file = strcat('2025-',[date_str(1:2) '-' date_str(3:4)],'_video_',num2str(exp_num),'_pupil_area_v3.csv');
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
        diff = len_bladder - len_pupil
        
        Bladder.filt_down{date_idx, exp_idx} = Bladder.filt_down{date_idx, exp_idx}(end-min_len+1:end);
        Pupil.filt_down{date_idx, exp_idx}   = Pupil.filt_down{date_idx, exp_idx}(end-min_len+1:end);
        
        %%%% Micturition detecting %%%%
        slope_thresh = 0.35;
        cluster_time = 2;  % seconds
        min_group_length = 2;  % seconds
        [Bladder.slope_time{date_idx, exp_idx}, Bladder.slope_vals{date_idx, exp_idx}] = detect_slope_increase(Bladder.filt_down{date_idx, exp_idx}-min(Bladder.filt_down{date_idx, exp_idx}), 1, slope_thresh, cluster_time, min_group_length);

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
        end

        Bladder.slope_time{date_idx, exp_idx} = Bladder.slope_time{date_idx, exp_idx}(include_list);
        
        

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
        end
        
        Pupil.slope_time{date_idx, exp_idx} = Pupil.slope_time{date_idx, exp_idx}(pupil_list);


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
            temp_idx = Pupil.slope_time{date_idx, exp_idx}(i);
            if temp_idx - 150 > 0
                if temp_idx+100 < length(temp_data)    
                    Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx-150:temp_idx+100);
                else
                    Pupil.part{date_idx, exp_idx}{i} = temp_data(temp_idx-150:end);
                end
            else
                Pupil.part{date_idx, exp_idx}{i} = temp_data(1:temp_idx+100);
            end
            [pk, loc] = findpeaks(Pupil.part{date_idx, exp_idx}{i}(50:end), ...
                      'MinPeakHeight', max(Pupil.part{date_idx, exp_idx}{i}(50:end))*0.8);

            if ~isempty(pk)
                % 첫 번째 peak의 값과 위치 저장
                Pupil.peak_val{date_idx, exp_idx}(i)  = pk(1);
                Pupil.peak_time{date_idx, exp_idx}(i) = loc(1) + 49 + temp_idx; % 100:end 했으므로 index 보정
            else
                Pupil.peak_val{date_idx, exp_idx}(i)  = NaN;
                Pupil.peak_time{date_idx, exp_idx}(i) = NaN;
            end
        end

        %% Peak 잘 detect 되었는지 체크용
        % figure();  
        % sgtitle(strcat(num2str(date), '-',num2str(exp_num)));
        % subplot(2,1,1);
        % plot(Bladder.filt_down{date_idx, exp_idx})
        % hold on;
        % for i = 1:length(Bladder.slope_time{date_idx, exp_idx})
        %     xline(Bladder.slope_time{date_idx, exp_idx}(i), 'k--', ...
        %         'Label', num2str(i), ...
        %         'LabelOrientation', 'horizontal', ...
        %         'LabelVerticalAlignment', 'bottom');
        % end
        % 
        % subplot(2,1,2);

        %% figure 1
        figure(); set(gcf, 'Units','centimeters','Position',[5 5 8 2.5]);
        plot(Bladder.filt_down{date_idx, exp_idx}, 'color','r','linewidth',1.2);
        hold on;
        
        % for i = 1:length(Pupil.slope_time{date_idx, exp_idx})
        %     xline(Pupil.slope_time{date_idx, exp_idx}(i), 'k--');
        % end
        xlim([100, 300])
        
        % 축 라인만 남기고 숫자 제거
        xticks([]); yticks([]);
        xlabel(''); ylabel('');
        box off;
        
        % 축 두께 설정
        set(gca, 'LineWidth', 1);
        
        % 배경 색상
        set(gcf, 'Color', 'w');   % figure 배경
        set(gca, 'Color', 'none');   % axes 배경
        
        %% figure 2
        figure(); set(gcf, 'Units','centimeters','Position',[10 5 8 2.5]);
        plot(Pupil.filt_down{date_idx, exp_idx}, 'color','k','linewidth',1.2);
        hold on;
        
        for i = 1:length(Pupil.slope_time{date_idx, exp_idx})
            xline(Pupil.slope_time{date_idx, exp_idx}(i), 'k--');
        end
        
        xlim([150, 300])

        % 축 라인만 남기고 숫자 제거
        xticks([]); yticks([]);
        xlabel(''); ylabel('');
        box off;
        
        % 축 두께 설정
        set(gca, 'LineWidth', 1);
        
        % 배경 색상
        set(gcf, 'Color', 'w');   % figure 배경
        set(gca, 'Color', 'none');   % axes 배경
        
        % 글꼴 설정
        set(findall(gcf,'-property','FontName'),'FontName','Arial');
        set(findall(gcf,'-property','FontSize'),'FontSize',5);

    
        %%
        exp_idx = exp_idx + 1;
    end
    clear a b
    date_idx = date_idx+1;
end
