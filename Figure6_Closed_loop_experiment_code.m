% 2025-07-23 IMS LAB
% Sunguk Hong, Mingeun Cho
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get pupil size from Python and detect OAB
% sec 1. Pupil size detection
% sec 2. Detect Micturition
% sec 3. Calculate micturition interval and put it into mic_interval
% sec 4. If interval is short enough to diagnose OAB, set trigger on
% sec 5. Start stimulation for 20 min
% sec 6. Rest for 30 min (no stimulation)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Initialize
%%%%%%%%%%%%%% Pupil connection %%%%%%%%%%%%%%%
import java.net.ServerSocket
import java.io.*

server = ServerSocket(50007);
disp('Waiting for connection...')
socket = server.accept();
disp('Client connected.')

input_stream = socket.getInputStream();
reader = DataInputStream(input_stream);

%%%%%%%%%%%%%% Intan connection %%%%%%%%%%%%%%
app.tcommand = tcpclient('localhost', 5000);
pause(1);
write(app.tcommand, uint8('execute ClearAllDataOutputs')); % Port 초기화

% --- 파라미터 계산 ---
stimFreq = 20;
if stimFreq <= 0
    uialert(app.UIFigure, '자극 주파수는 0보다 커야 합니다.', '입력 오류');
    return;
end
pulseNum = stimFreq;                   % 1초에 필요한 pulse 수
pulsePeriod = round(1e6 / stimFreq);   % 마이크로초 단위로 환산
amplitude = 2550;
duration = 200;

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

% --- 파라미터 값 대응 (포맷에 맞춰 순서 중요) ---
paramValues = {
    amplitude, amplitude, ...
    duration, duration, ...
    pulseNum, pulsePeriod
};

% === 채널 루프 ===
for i = 1:1   % i = 1:16 으로 설정 시 전체 채널 사용 가능
    chanStr = sprintf('b-%03d', i-1);  % b-000, b-001, ..., b-015
    
    paramIdx = 1;  % 파라미터 인덱스 초기화
    
    for j = 1:length(cmds)
        cmd = cmds{j};
        
        % %d 포맷 포함 시 파라미터 채우기
        if contains(cmd, '%d')
            formatted = sprintf(['set ', chanStr, cmd], paramValues{paramIdx});
            paramIdx = paramIdx + 1;
        else
            formatted = ['set ', chanStr, cmd];
        end
        
        % 명령 전송
        write(app.tcommand, uint8(formatted));
    end
end

% === 업로드 실행 ===
write(app.tcommand, uint8('execute UploadStimParameters'));
pause(5);  % 자극기 내부 설정 적용 대기

% === 자극 수행 준비 ===
write(app.tcommand, uint8('set runmode run'));

%% Parameters for OAB logic
mic_interval = [];
OAB_threshold = 600;       % OAB 진단 기준 (초 단위, 예: 10분)
stim_duration = 20*60;     % 20분 (초 단위)
rest_duration = 30*60;     % 30분 (초 단위)
last_stim_time = -Inf;     % 마지막 자극 시작 시각

%% Main code
while true
    % ========================
    % Get Pupil size
    % ========================
    if reader.available() >= 4  % float = 4 bytes
        bytes = zeros(1,4,'uint8');
        for i = 1:4
            bytes(i) = reader.read();
        end
        pupil_area = typecast(uint8(bytes), 'single'); % 동공 크기
        fprintf("Received pupil area: %.2f\n", pupil_area);
    end
    pause(0.1);

    % ========================
    % Detect micturition
    % ========================
    % (여기서는 micturition flag가 Python에서 온다고 가정)
    if exist('micturition','var') && micturition == 1
        if exist('last_mict_time','var')
            mic_interval = toc(last_mict_time);
            fprintf('Micturition interval: %.1f sec\n', mic_interval);
        end
        last_mict_time = tic;  % 배뇨 발생 시각 업데이트
        micturition = 0;       % flag reset
    end

    % ========================
    % Diagnose OAB
    % ========================
    if exist('mic_interval','var') && mic_interval < OAB_threshold
        OAB = 1;
    else
        OAB = 0;
    end

    % ========================
    % Start stimulation
    % ========================
    % 조건: OAB 양성 + 마지막 자극 후 30분 이상 경과
    if OAB == 1 && (etime(clock, last_stim_time) > rest_duration)
        disp('[Start] 자극 시작');
        stim_time = tic;
        last_stim_time = clock;  % 자극 시작 시각 기록

        while toc(stim_time) < stim_duration
            % 자극 시작
            try
                write(app.tcommand, uint8('execute ManualStimTriggerOn F1'));
                disp('[Stim] ON');
            catch
                warning('[Stim] ON 명령 실패');
            end
    
            pause(1);  % 1초 자극 유지 (필요시 stimTime 변수로 조정)
    
            % 자극 종료
            try
                write(app.tcommand, uint8('execute ManualStimTriggerOff F1'));
                disp('[Stim] OFF');
            catch
                warning('[Stim] OFF 명령 실패');
            end

            pause(1);  % 다음 자극까지 대기
        end

        disp('[End] 자극 종료 - 30분 휴지기 시작');
    end
end
