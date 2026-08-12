function [frames, success_count] = capture_and_save_frames(params, num_trials)
% CAPTURE_AND_SAVE_FRAMES Thu và lưu các frame dựa trên thông số trong struct
%   Đầu vào:
%       params     - struct chứa các trường: .fs, .fc, .df, .N, .frame_length, ...
%       num_trials - số lần thử thu (mặc định = 6)
%   Đầu ra:
%       frames        - cell array chỉ chứa các frame thu được thành công
%       success_count - số lượng frame thành công

    if nargin < 2
        num_trials = 6;
    end

    % Giải nén thông số cần thiết
    fs = params.fs;
    fc = params.fc;
    df = params.df;
    N = params.N;
    frame_length = params.frame_length;
    sync_bits = params.sync;
    
    % --- Tạo tín hiệu sync đã điều chế ---
    sync_0 = linecoding(sync_bits, N, 0);
    sync_1 = linecoding(sync_bits, N, 1);
    t_xccor = (0:length(sync_0)-1) / fs;
    xp0 = sync_0 .* cos(2*pi*(fc-df)*t_xccor);
    xp1 = sync_1 .* cos(2*pi*(fc+df)*t_xccor);
    sync_sig = xp0 + xp1;
    
    % --- Bộ lọc bandpass ---
    [b, a] = butter(4, [fc-df*2.5, fc+df*2.5]/(fs/2), 'bandpass');
    
    frames = {};          % cell rỗng, sẽ thêm dần
    success_count = 0;
    
    for k = 1:num_trials
        fprintf('\n===== Lần thử %d / %d =====\n', k, num_trials);
        
        % Delay 5 giây trước mỗi lần ghi
        fprintf('Chờ 5 giây...\n');
        pause(5);
        
        record_time = 3 + 1.25 * frame_length / fs;
        fprintf('Ghi âm trong %.2f giây...\n', record_time);
        recObj = audiorecorder(fs, 16, 1);
        recordblocking(recObj, record_time);
        rx = getaudiodata(recObj)';
        
        % Lọc tín hiệu thu
        y = filtfilt(b, a, rx);
        
        % Tìm vị trí đồng bộ
        idx = find_header_pos(y, sync_sig);
        
        if isempty(idx)
            warning('Lần thử %d: không tìm thấy sync -> bỏ qua.', k);
            continue;
        end
        
        if idx + frame_length - 1 > length(y)
            warning('Lần thử %d: không đủ mẫu (cần %d, chỉ còn %d) -> bỏ qua.', ...
                k, frame_length, length(y)-idx+1);
            continue;
        end
        
        % Cắt frame thành công
        frame_signal = y(idx : idx+frame_length-1);
        frames{end+1} = frame_signal;   % thêm vào cell
        success_count = success_count + 1;
        fprintf('Lần thử %d: đã cắt frame thành công (vị trí %d, độ dài %d mẫu)\n', ...
            k, idx, length(frame_signal));
    end
    
    % Lưu kết quả (chỉ lưu các frame thành công)
    save('ket_qua_thu_frame.mat', 'frames');
    fprintf('\n=== Đã lưu %d frame thành công vào file ket_qua_thu_frame.mat ===\n', success_count);
    
    % In ra màn hình số khung lưu được
    fprintf('Tổng số khung thu được: %d / %d lần thử\n', success_count, num_trials);
end