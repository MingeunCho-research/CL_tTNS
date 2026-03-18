%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (앞부분 동일)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc; close all;

%% Intan initialize
%%%%%%%%%%%%%% Intan connection %%%%%%%%%%%%%%
app.tcommand = tcpclient('localhost', 5000);
pause(1);
write(app.tcommand, uint8('execute ClearAllDataOutputs')); % Port 초기화

% --- 파라미터 계산 ---   
stimFreq = 20;
if stimFreq <= 0 
    % App 환경이 아니라면 uialert는 주석 처리하거나 대체하세요
    % uialert(app.UIFigure, '자극 주파수는 0보다 커야 합니다.', '입력 오류');
    error('자극 주파수는 0보다 커야 합니다.');
end
pulseNum   = stimFreq;                 % 1초에 필요한 pulse 수
pulsePeriod = round(1e6 / stimFreq);   % 마이크로초 단위로 환산
amplitude  = 2550;
duration   = 200;

% --- 자극 설정 명령 리스트 ---
cmds = {
    '.Source KeyPressF1'
    '.StimEnabled True'
    '.FirstPhaseAmplitudeMicroAmps %d'
    '.SecondPhaseAmplitudeMicroAmps %d'
    '.FirstPhaseDurationMicroseconds %d'
    '.SecondPhaseDurationMicroseconds %d'
    '.PulseOrTrain PulseTrain'
    '.NumberOfStimPulses %d'
    '.PulseTrainPeriodMicroseconds %d'
    '.RefractoryPeriodMicroseconds 1'
    '.PostStimAmpSettleMicroseconds 0'
    '.Polarity PositiveFirst'
    '.EnableAmpSettle False'
    '.TriggerEdgeOrLevel Level'
};
paramValues = { amplitude, amplitude, duration, duration, pulseNum, pulsePeriod };

for i = 1:1   % i = 1:16 가능
    chanStr = sprintf('b-%03d', i-1);
    paramIdx = 1;
    for j = 1:numel(cmds)
        cmd = cmds{j};
        if contains(cmd, '%d')
            formatted = sprintf(['set ', chanStr, cmd], paramValues{paramIdx});
            paramIdx = paramIdx + 1;
        else
            formatted = ['set ', chanStr, cmd];
        end
        write(app.tcommand, uint8(formatted));
    end
end
write(app.tcommand, uint8('execute UploadStimParameters'));
pause(5);
write(app.tcommand, uint8('set runmode run'));

%% === Intan 제어용 전역/상태 ===
global tcommand stimActive stimTimer STIM_DURATION_SEC
tcommand           = app.tcommand;   % 콜백에서 쓰기 쉽게 전역으로 노출
stimActive         = false;          % 현재 자극 중?
stimTimer          = [];             % 20분 종료 타이머 핸들
STIM_DURATION_SEC  = 20*60;          % ★ 20분

%% Python과 Real-time 통신
global micturition_time interval stim_trigger
global low_interval_count n_required refractory_until_time REFRACT_SEC
global short_interval_total_count interval_thresh

micturition_time            = [];
interval                    = [];
stim_trigger                = 0;

low_interval_count          = 0;      % ★ 누적 카운트
n_required                  = 2;      % 누적 기준
REFRACT_SEC                 = 30*60;  % 30분 휴지기
refractory_until_time       = -inf;
short_interval_total_count  = 0;
interval_thresh             = 240;    % 임계값(초)

HOST = "127.0.0.1";
PORT = 50010;

srv = tcpserver(HOST, PORT, "ByteOrder","little-endian", "Timeout",10);
srv.UserData = struct( ...
    't0', tic, ...
    'rx', 0, ...
    'time_axis', [], ...
    'pupil_axis', [], ...
    'hLine', [], ...
    'expectingEvent', uint8(0), ...
    'pendingEventTime', NaN, ...
    'det_fs', 1.0 ...
);

fprintf('[INFO] tcpserver listening on %s:%d\n', HOST, PORT);

fig = figure('Name','Pupil size (TCP) + Events','NumberTitle','off','Color','w');
hLine = plot(nan, nan, 'b-', 'LineWidth', 1.5); grid on; hold on;
xlabel('Time (s)'); ylabel('Pupil area'); title('Pupil size (TCP)');
srv.UserData.hLine = hLine;

configureCallback(srv, "byte", 4, @onBytes);
if srv.NumBytesAvailable >= 4, onBytes(srv, []); end
figClose = onCleanup(@()cleanupServer(srv));


%% === 저장: TCP 객체 제외하고 저장 ===
% vars = whos;
% varList = {};
% 
% for i = 1:length(vars)
%     cls = vars(i).class;
%     name = vars(i).name;
% 
%     % tcp 관련 객체는 저장에서 제외
%     if strcmp(cls, 'tcpclient') || strcmp(cls, 'tcpserver')
%         fprintf('[SKIP] %s (%s)\n', name, cls);
%         continue;
%     end
% 
%     varList{end+1} = name; %#ok<SAGROW>
% end
% 
% save('0710_test_temp_2.mat', varList{:});
% fprintf('[SAVE] 저장 완료: 0703_test_temp.mat\n');


% ===== 콜백 =====
function onBytes(s, ~)
    % 외부 전역 변수
    global micturition_time interval stim_trigger
    global low_interval_count n_required refractory_until_time REFRACT_SEC
    global short_interval_total_count interval_thresh
    global STIM_DURATION_SEC

    ud  = s.UserData;
    EPS = 1e-6;

    while s.NumBytesAvailable >= 4
        v = read(s, 1, "single");   % float32

        % ---- 이벤트 페이로드 수신 중? ----
        if ud.expectingEvent == 2
            ud.pendingEventTime = double(v);
            ud.expectingEvent   = uint8(1);
            write(s, uint8(170), "uint8"); % ACK
            continue

        elseif ud.expectingEvent == 1
            interval_sec = double(v);

            % 이벤트 시각: Python 1Hz
            t_line = ud.pendingEventTime;
            xline(t_line, 'r--', 'LineWidth', 1.2);
            fprintf('[EVENT] x=%.2f s | interval=%s\n', ...
                t_line, ternary(~isnan(interval_sec) && isfinite(interval_sec), ...
                sprintf('%.6f s',interval_sec),'NaN'));

            % 기록 누적
            micturition_time(end+1) = t_line;      %#ok<AGROW>
            interval(end+1)         = interval_sec; %#ok<AGROW>

            % 짧은 간격 판정(누적 카운트)
            if ~isempty(interval) && isfinite(interval(end))
                last_iv  = interval(end);
                is_short = (last_iv <= interval_thresh + EPS);
            else    
                last_iv  = NaN; is_short = false;
            end
            fprintf('[DEBUG] last_iv=%.6f | thresh=%.6f | is_short=%d | refractory_until=%.2f | t=%.2f\n', ...
                last_iv, interval_thresh, is_short, refractory_until_time, t_line);

            % 휴지기 여부
            in_refractory = (t_line < refractory_until_time);
            if in_refractory
                if is_short
                    short_interval_total_count = short_interval_total_count + 1;
                    fprintf('[SHORT][REFRACT] t=%.2f s | interval=%.6f s <= %.6f s | total=%d\n', ...
                        t_line, last_iv, interval_thresh, short_interval_total_count);
                else
                    fprintf('[REFRACT] active until %.2f s → skip trigger\n', refractory_until_time);
                end
                low_interval_count = 0;

            else
                if is_short
                    short_interval_total_count = short_interval_total_count + 1;
                    low_interval_count        = low_interval_count + 1;
                    fprintf('[SHORT] t=%.2f s | interval=%.6f s <= %.6f s | total=%d | cumulative=%d/%d \n', ...
                        t_line, last_iv, interval_thresh, ...
                        short_interval_total_count, low_interval_count, n_required);

                    % ---- 누적 n회 → 트리거 발동 + 20분 자극 ----
                    if (low_interval_count >= n_required) && (stim_trigger == 0)
                        stim_trigger = 1;                       % 래치 on
                        xline(t_line, 'g--', 'LineWidth', 2);   % 즉시 표기
                        refractory_until_time = t_line + REFRACT_SEC;
                        fprintf(['[STIM] fired at %.2f s → refractory %d s (until %.2f s)\n' ...
                                 '[STIM] draw green dashed line at x=%.2f s\n'], ...
                                t_line, REFRACT_SEC, refractory_until_time, t_line);
                        drawnow limitrate;

                        % === 20분 자극 시작 ===
                        startStim20min();

                        % 래치 해제 및 카운트 리셋
                        stim_trigger       = 0;
                        low_interval_count = 0;
                    end
                else
                    % 누적 방식: reset 없음
                end
            end

            % 상태 초기화
            ud.expectingEvent = uint8(0);
            ud.pendingEventTime = NaN;
            write(s, uint8(170), "uint8"); % ACK
            continue
        end

        % ---- 일반 패킷: NaN이면 이벤트 패킷 시작 ----
        if isnan(v)
            ud.expectingEvent = uint8(2);
            write(s, uint8(170), "uint8"); % ACK
            continue
        end

        % ---- 일반 pupil 샘플 처리 ----
        ud.rx = ud.rx + 1;
        t_det = (ud.rx - 1) / ud.det_fs;

        ud.time_axis(end+1)  = t_det;        %#ok<AGROW>
        ud.pupil_axis(end+1) = double(v);    %#ok<AGROW>

        if ~isempty(ud.hLine) && isgraphics(ud.hLine)
            set(ud.hLine, 'XData', ud.time_axis, 'YData', ud.pupil_axis);
            drawnow limitrate
        end

        write(s, uint8(170), "uint8");       % ACK
    end
    s.UserData = ud;
end



% ===== 자극 20분 실행/정지 유틸 =====
function startStim20min()
    global tcommand stimActive stimTimer STIM_DURATION_SEC
    if stimActive
        fprintf('[Stim] already active → skip start\n');
        return;
    end
    try
        write(tcommand, uint8('execute ManualStimTriggerOn F1'));
        fprintf('[Stim] ON (20 min)\n');
        stimActive = true;
    catch ME
        warning('[Stim] ON failed: %s', ME.message);
        return;
    end
    % 20분 후 OFF하는 one-shot 타이머
    try
        stimTimer = timer('ExecutionMode','singleShot', ...
                          'StartDelay', STIM_DURATION_SEC, ...
                          'TimerFcn', @(~,~) stopStim());
        start(stimTimer);
    catch ME
        warning('[Stim] timer start failed: %s', ME.message);
    end
end

function stopStim()
    global tcommand stimActive stimTimer
    try
        write(tcommand, uint8('execute ManualStimTriggerOff F1'));
        fprintf('[Stim] OFF\n');
    catch ME
        warning('[Stim] OFF failed: %s', ME.message);
    end
    stimActive = false;
    if ~isempty(stimTimer) && isvalid(stimTimer)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Intan + TCP + Closed-loop stimulation controller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc; close all;

%% Intan initialize
%%%%%%%%%%%%%% Intan connection %%%%%%%%%%%%%%
app.tcommand = tcpclient('localhost', 5000);
pause(1);
write(app.tcommand, uint8('execute ClearAllDataOutputs')); % Port 초기화

% --- 파라미터 계산 ---   
stimFreq = 20;
if stimFreq <= 0 
    error('자극 주파수는 0보다 커야 합니다.');
end
pulseNum   = stimFreq;                 % 1초에 필요한 pulse 수
pulsePeriod = round(1e6 / stimFreq);   % 마이크로초 단위로 환산
amplitude  = 2550;
duration   = 200;

% --- 자극 설정 명령 리스트 ---
cmds = {
    '.Source KeyPressF1'
    '.StimEnabled True'
    '.FirstPhaseAmplitudeMicroAmps %d'
    '.SecondPhaseAmplitudeMicroAmps %d'
    '.FirstPhaseDurationMicroseconds %d'
    '.SecondPhaseDurationMicroseconds %d'
    '.PulseOrTrain PulseTrain'
    '.NumberOfStimPulses %d'
    '.PulseTrainPeriodMicroseconds %d'
    '.RefractoryPeriodMicroseconds 1'
    '.PostStimAmpSettleMicroseconds 0'
    '.Polarity PositiveFirst'
    '.EnableAmpSettle False'
    '.TriggerEdgeOrLevel Level'
};
paramValues = { amplitude, amplitude, duration, duration, pulseNum, pulsePeriod };

for i = 1:1   % i = 1:16 가능
    chanStr = sprintf('b-%03d', i-1);
    paramIdx = 1;
    for j = 1:numel(cmds)
        cmd = cmds{j};
        if contains(cmd, '%d')
            formatted = sprintf(['set ', chanStr, cmd], paramValues{paramIdx});
            paramIdx = paramIdx + 1;
        else
            formatted = ['set ', chanStr, cmd];
        end
        write(app.tcommand, uint8(formatted));
    end
end
write(app.tcommand, uint8('execute UploadStimParameters'));
pause(5);
write(app.tcommand, uint8('set runmode run'));

%% === Intan 제어용 전역/상태 ===
global tcommand stimActive stimTimer STIM_DURATION_SEC
tcommand           = app.tcommand;   % 콜백에서 쓰기 쉽게 전역으로 노출
stimActive         = false;          % 현재 자극 중?
stimTimer          = [];             % 20분 종료 타이머 핸들
STIM_DURATION_SEC  = 20*60;          % 20분

%% Python과 Real-time 통신
global micturition_time interval stim_trigger
global low_interval_count n_required refractory_until_time REFRACT_SEC
global short_interval_total_count interval_thresh
global Stim_on   % ★ 자극 ON/OFF 플래그

micturition_time            = [];
interval                    = [];
stim_trigger                = 0;

low_interval_count          = 0;      % 누적 카운트
n_required                  = 3;      % ★ 연속 3회 기준
REFRACT_SEC                 = 30*60;  % 30분 휴지기
refractory_until_time       = -inf;
short_interval_total_count  = 0;
interval_thresh             = 240;    % 임계값(초)

Stim_on                     = 1;      % ★ 실행 여부 제어 (1=ON, 0=OFF)

HOST = "127.0.0.1";
PORT = 50010;

srv = tcpserver(HOST, PORT, "ByteOrder","little-endian", "Timeout",10);
srv.UserData = struct( ...
    't0', tic, ...
    'rx', 0, ...
    'time_axis', [], ...
    'pupil_axis', [], ...
    'hLine', [], ...
    'expectingEvent', uint8(0), ...
    'pendingEventTime', NaN, ...
    'det_fs', 1.0 ...
);

fprintf('[INFO] tcpserver listening on %s:%d\n', HOST, PORT);

fig = figure('Name','Pupil size (TCP) + Events','NumberTitle','off','Color','w');
hLine = plot(nan, nan, 'b-', 'LineWidth', 1.5); grid on; hold on;
xlabel('Time (s)'); ylabel('Pupil area'); title('Pupil size (TCP)');
srv.UserData.hLine = hLine;

configureCallback(srv, "byte", 4, @onBytes);
if srv.NumBytesAvailable >= 4, onBytes(srv, []); end
figClose = onCleanup(@()cleanupServer(srv));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== 콜백 =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function onBytes(s, ~)
    global micturition_time interval stim_trigger
    global low_interval_count n_required refractory_until_time REFRACT_SEC
    global short_interval_total_count interval_thresh
    global STIM_DURATION_SEC Stim_on

    ud  = s.UserData;
    EPS = 1e-6;

    while s.NumBytesAvailable >= 4
        v = read(s, 1, "single");   % float32

        % ---- 이벤트 페이로드 수신 중? ----
        if ud.expectingEvent == 2
            ud.pendingEventTime = double(v);
            ud.expectingEvent   = uint8(1);
            write(s, uint8(170), "uint8"); % ACK
            continue

        elseif ud.expectingEvent == 1
            interval_sec = double(v);

            % 이벤트 시각: Python 1Hz
            t_line = ud.pendingEventTime;
            xline(t_line, 'r--', 'LineWidth', 1.2);
            fprintf('[EVENT] x=%.2f s | interval=%s\n', ...
                t_line, ternary(~isnan(interval_sec) && isfinite(interval_sec), ...
                sprintf('%.6f s',interval_sec),'NaN'));

            % 기록 누적
            micturition_time(end+1) = t_line;      %#ok<AGROW>
            interval(end+1)         = interval_sec; %#ok<AGROW>

            % 짧은 간격 판정
            if ~isempty(interval) && isfinite(interval(end))
                last_iv  = interval(end);
                is_short = (last_iv <= interval_thresh + EPS);
            else    
                last_iv  = NaN; is_short = false;
            end

            % 휴지기 여부
            in_refractory = (t_line < refractory_until_time);
            if in_refractory
                low_interval_count = 0;

            else
                if is_short
                    low_interval_count = low_interval_count + 1;
                    fprintf('[SHORT] t=%.2f s | interval=%.6f s | cumulative=%d/%d \n', ...
                        t_line, last_iv, low_interval_count, n_required);

                    % ---- 연속 n회 기준 → 트리거 발동 ----
                    if (low_interval_count >= n_required) && (stim_trigger == 0)
                        stim_trigger = 1;                       % 래치 on
                        xline(t_line, 'g--', 'LineWidth', 2);   % 즉시 표기
                        refractory_until_time = t_line + REFRACT_SEC;
                        fprintf('[STIM] fired at %.2f s → refractory %d s (until %.2f s)\n', ...
                                t_line, REFRACT_SEC, refractory_until_time);

                        % === Stim_on 플래그 확인 후 실행 ===
                        if Stim_on == 1
                            fprintf('[STIM] Stim_on=1 → 실제 자극 수행\n');
                            startStim20min();
                        else
                            fprintf('[STIM] Stim_on=0 → 자극은 수행하지 않음\n');
                        end

                        % 래치 해제 및 카운트 리셋
                        stim_trigger       = 0;
                        low_interval_count = 0;
                    end
                end
            end

            % 상태 초기화
            ud.expectingEvent = uint8(0);
            ud.pendingEventTime = NaN;
            write(s, uint8(170), "uint8"); % ACK
            continue
        end

        % ---- 일반 패킷: NaN이면 이벤트 패킷 시작 ----
        if isnan(v)
            ud.expectingEvent = uint8(2);
            write(s, uint8(170), "uint8"); % ACK
            continue
        end

        % ---- 일반 pupil 샘플 처리 ----
        ud.rx = ud.rx + 1;
        t_det = (ud.rx - 1) / ud.det_fs;

        ud.time_axis(end+1)  = t_det;        %#ok<AGROW>
        ud.pupil_axis(end+1) = double(v);    %#ok<AGROW>

        if ~isempty(ud.hLine) && isgraphics(ud.hLine)
            set(ud.hLine, 'XData', ud.time_axis, 'YData', ud.pupil_axis);
            drawnow limitrate
        end

        write(s, uint8(170), "uint8");       % ACK
    end
    s.UserData = ud;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== 자극 20분 실행/정지 유틸 =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function startStim20min()
    global tcommand stimActive stimTimer STIM_DURATION_SEC
    if stimActive
        fprintf('[Stim] already active → skip start\n');
        return;
    end
    try
        write(tcommand, uint8('execute ManualStimTriggerOn F1'));
        fprintf('[Stim] ON (20 min)\n');
        stimActive = true;
    catch ME
        warning('[Stim] ON failed: %s', ME.message);
        return;
    end
    % 20분 후 OFF하는 one-shot 타이머
    try
        stimTimer = timer('ExecutionMode','singleShot', ...
                          'StartDelay', STIM_DURATION_SEC, ...
                          'TimerFcn', @(~,~) stopStim());
        start(stimTimer);
    catch ME
        warning('[Stim] timer start failed: %s', ME.message);
    end
end

function stopStim()
    global tcommand stimActive stimTimer
    try
        write(tcommand, uint8('execute ManualStimTriggerOff F1'));
        fprintf('[Stim] OFF\n');
    catch ME
        warning('[Stim] OFF failed: %s', ME.message);
    end
    stimActive = false;
    if ~isempty(stimTimer) && isvalid(stimTimer)
        try, delete(stimTimer); catch, end
    end
    stimTimer = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== 간단 3항연산 보조 =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== 정리 =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cleanupServer(s)
    try
        stopStim();
    catch
    end
    try
        if ~isempty(s) && isvalid(s)
            configureCallback(s, "off");
            clear s;
            disp('[CLEANUP] tcpserver closed');
        end
    catch
        disp('[CLEANUP] already closed');
    end
end

        try, delete(stimTimer); catch, end
    end
    stimTimer = [];
end

% ===== 간단 3항연산 보조 =====
function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end

% ===== 정리 =====
function cleanupServer(s)
    try
        % 안전하게 자극 OFF 및 타이머 정리
        stopStim();
    catch
    end
    try
        if ~isempty(s) && isvalid(s)
            configureCallback(s, "off");
            clear s;
            disp('[CLEANUP] tcpserver closed');
        end
    catch
        disp('[CLEANUP] already closed');
    end
end

