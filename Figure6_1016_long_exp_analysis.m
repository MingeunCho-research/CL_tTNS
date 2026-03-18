%% 1016 Long term exp 분석용
clear; close all; clc;
date_list = [1016];
date_idx = 1;

for date = date_list
    %%
    if date == 1016
        stim_start = 3316;
        stim_start2 = 11722;
        OAB_start = 2752;
        stim_duration = 1200+1000;
        threshold = 230;
        skip_thres = 100;
    end

    %% Load bladder data
    cd 'C:\Users\owner\SynologyDrive\11 데이터셋\02 Pupil-OAB\CL_DATA'
    file_name = strcat('25', num2str(date, '%04d'),'_CL_success.mat');
    load(file_name);
    
    Bladder.raw{date_idx} = double(b1(:,2)); 
    
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
    
    if date == 1016
        Bladder.filt_down{date_idx} = Bladder.filt_down{date_idx}(1:end);
    end

    fig2 = figure(date_idx); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 13 14 2.5]);
    plot(Bladder.filt_down{date_idx}, 'r','LineWidth', 1.2)
    
    ylabel('IBP (mmHg)')
    xlabel('Time (s)')
    axis tight;
    ylim([15 75])
    box off;
    
    set(findall(gcf,'-property','FontName'),'FontName','Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize', 7);
    
    BP = movmean(Bladder.filt_down{date_idx}, 5);

    % Total
    [pks, locs_total] = findpeaks(BP(1:end),'MinPeakDistance', skip_thres);

    % Normal
    locs_normal = [39 339 902 1324 1568 2004 2689];
    % xline(locs_normal,'b:');

    % Before stim1
    locs_OAB = [2907, 3029, 3193, 3278];
    
    % After stim1
    [pks, locs_TNS] = findpeaks(BP(stim_start+stim_duration:stim_start+stim_duration+60*50),'MinPeakDistance', skip_thres);

    % Before stim2
    [pks, locs_OAB2] = findpeaks(BP(9000: stim_start2),'MinPeakDistance', skip_thres);

    % After stim2
    [pks, locs_TNS2] = findpeaks(BP(stim_start2+stim_duration:end),'MinPeakDistance', skip_thres);
    
    
    Total{date_idx} = diff(locs_total);
    Normal{date_idx} = diff(locs_normal);
    OAB{date_idx} = diff(locs_OAB);
    TNS{date_idx} = diff(locs_TNS);
    OAB2{date_idx} = diff(locs_OAB2);
    TNS2{date_idx} = diff(locs_TNS2);

    id_time(date_idx) = stim_start-OAB_start;

    xline(stim_start,'k:');
    xline(stim_start2,'k:');
    
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
    % plot_raw = downsample(Pupil.raw{date_idx}, 10, 1);
    plot_raw = Pupil.raw{date_idx};

    % Raw pupil data
    fig2 = figure(date_idx+200); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5 13 14 2.5]);
    plot(plot_pupil, 'b', 'linewidth', 1.2);
    axis tight
    yticks([0 1e4])
    ax = gca;
    ax.YAxis.Exponent = 4;
    % xlim([(4570)*10, (4690)*10])
    
    ylabel('Pupil size')
    xlabel('time (s)')
    set(findall(gcf,'-property','FontName'),'FontName','Arial');
    set(findall(gcf,'-property','FontSize'),'FontSize', 7);
    box off; 
    % axis off;

    % % processed pupil data
    % fig2 = figure(date_idx+100); clf(fig2);
    % set(fig2, 'Units','centimeters','Position',[5 9 4 3]);
    % plot(plot_pupil, 'k', 'linewidth', 1.2);
    % axis tight
    % xlim([4570, 4690])
    % 
    % ylabel('Pupil size')
    % xlabel('time (s)')
    % set(findall(gcf,'-property','FontName'),'FontName','Arial');
    % set(findall(gcf,'-property','FontSize'),'FontSize', 7);
    % box off; axis off;
    % % xline(stim_start, 'r--', 'linewidth', 1.2)
    % 
    % if date == 0929
    %     ylim([0, 600])
    % elseif date == 0930
    %     ylim([0, 3000])  
    % elseif date == 1003  
    %     ylim([0, 3500])
    % end
    
    date_idx = date_idx+1;
end 

%% Individual date representation
for i = 1:length(date_list)
    % 그룹 및 데이터 준비
    group = [repmat({'Norm.'}, length(Normal{i}), 1);
             repmat({'OAB1'}, length(OAB{i}), 1);
             repmat({'tTNS1'}, length(TNS{i}), 1);
             repmat({'OAB2'}, length(OAB2{i}), 1);
             repmat({'tTNS2'}, length(TNS2{i}), 1)];
    
    data_all = [Normal{i}(:); OAB{i}(:); TNS{i}(:); OAB2{i}(:); TNS2{i}(:)];
    
    fig2 = figure(i+200); clf(fig2);
    set(fig2, 'Units','centimeters','Position',[5+(i-1)*5 6 4.5 6]); 
    boxplot(data_all, group); hold on;
    
    x_positions = 1:5;
    jitterAmount = 0.05;
    
    all_groups = {Normal{i}, OAB{i}, TNS{i}, OAB2{i}, TNS2{i}};
    
    % Axes 내 모든 line 객체 가져오기
    allLines = findobj(gca, 'Type', 'line');
    
    % outlier 제외
    allLines_noOutlier = allLines(~strcmp(get(allLines, 'Tag'), 'Outliers'));
    
    % 스타일 적용
    if ~isempty(allLines_noOutlier)
        set(allLines_noOutlier, 'LineStyle', '-', 'LineWidth', 0.8, 'Color', [0 0 0]);
    end
    
    % --- 박스 테두리 색상 지정 ---
    hBox = findobj(gca, 'Tag', 'Box');
    colors = [0 0 1; 1 0 0; 0 0 1; 1 0 0; 0 0 0];
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

    % --- Scatter plot: inlier 검은 점, outlier 붉은 + ---
    for g = 1:length(all_groups)
        x = all_groups{g};
        % 1사분위수, 3사분위수, IQR 계산
        q1 = quantile(x, 0.25);
        q3 = quantile(x, 0.75);
        IQR = q3 - q1;
        lower_whisker = q1 - 1.5 * IQR;
        upper_whisker = q3 + 1.5 * IQR;

        % inlier / outlier 구분
        inlier_idx = (x >= lower_whisker) & (x <= upper_whisker);
        outlier_idx = ~inlier_idx;

        % jitter 적용
        x_jitter_in = x_positions(g) + (rand(sum(inlier_idx),1)-0.5)*2*jitterAmount;
        x_jitter_out = x_positions(g) + (rand(sum(outlier_idx),1)-0.5)*2*jitterAmount;

        % --- Inlier scatter ---
        scatter(x_jitter_in, x(inlier_idx), 8, 'MarkerFaceColor','w','MarkerEdgeColor','k','MarkerFaceAlpha',0.6);
        
        % % --- Outlier scatter ---
        % scatter(x_jitter_out, x(outlier_idx), 20, 'r', '+', 'LineWidth', 1.2);
        
        % --- Inlier끼리 선 연결 (필요하면) ---
        % line(x_jitter_in, x(inlier_idx), 'Color','k','LineWidth',0.5); 
        % -> 선 연결 시 inlier만 사용하도록
    end

    % 옵션 꾸미기
    ylabel('Inter-mic. Interval (s)');
    set(gca, 'FontSize', 7);
    yline(230, 'k:')

    % 각 그룹별 중간값 계산 및 출력
    med1 = median(Normal{i});
    med2 = median(OAB{i});
    med3 = median(TNS{i});
    med4 = median(OAB2{i});
    med5 = median(TNS2{i});
    
    disp(['Normal median: ', num2str(med1)]);
    disp(['OAB Before median: ', num2str(med2)]);
    disp(['TNS median: ', num2str(med3)]);
    disp(['OAB2 Before median: ', num2str(med4)]);
    disp(['TNS2 median: ', num2str(med5)]);
    disp(['Id Time: ', num2str(id_time(i))]);
    disp(' ')

    box off;
end


%%
fig3 = figure(i+1100); clf(fig3);
set(fig3, 'Units','centimeters','Position',[5+(i-1)*5 6 10 3.5]); 
plot(locs_total(1:end-1), Total{1},'linewidth',1.2,'Color','r');
xline(stim_start,'r:');
xline(stim_start+50*60,'r:');
xline(stim_start2,'b:');
xline(stim_start2+50*60,'b:');

yline(threshold, 'LineStyle',':', 'Color', 'k');

ylabel('Inter-mic. interval (s)')
xlabel('time (s)')
set(findall(gcf,'-property','FontName'),'FontName','Arial');
set(findall(gcf,'-property','FontSize'),'FontSize', 7);

box off;

