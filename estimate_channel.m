function [H0_cell, H1_cell] = estimate_channel(params, frames)
% ESTIMATE_CHANNEL Ước lượng kênh truyền cho từng frame trong cell frames
%   Đầu vào:
%       params - struct từ hàm create_params (chứa .fs, .fc, .df, .N, .sync, .z, .payload_bits)
%       frames - cell array chứa các tín hiệu frame đã thu (mỗi frame là vector)
%   Đầu ra:
%       H0_cell - cell array cùng kích thước frames, mỗi phần tử là vector kênh miền tần số cho nhánh f0
%       H1_cell - cell array tương ứng cho nhánh f1

    % --- Kiểm tra đầu vào ---
    if nargin < 2 || isempty(frames)
        error('Cần cung cấp params và frames không rỗng.');
    end
    
    % --- Giải nén thông số từ params ---
    fs = params.fs;
    fc = params.fc;
    df = params.df;
    N = params.N;
    sync_bits = params.sync;
    z = params.z;
    payload_bits = params.payload_bits;
    
    % Độ dài (mẫu) của phần sync+ze và payload+ze
    len_sync_ze = N * (length(sync_bits) + z);
    len_payload_ze = N * (length(payload_bits) + z);
    L = max(len_sync_ze, len_payload_ze);   % độ dài dùng cho FFT (zero-padding)
    
    % --- Tạo tín hiệu sync lý tưởng đã điều chế (phát) ---
    % linecoding(bits, N, 0) tạo NRZ với N mẫu/bit, giá trị 0 1
    sync_0 = [linecoding(sync_bits, N, 0) zeros(1,z*N)];
    sync_1 = [linecoding(sync_bits, N, 1) zeros(1,z*N)];
    t_hp = (0:len_sync_ze-1) / fs;
    
    % Tín hiệu băng tần cho từng nhánh (chưa qua lọc)
    xp0_band = sync_0 .* cos(2*pi*(fc-df)*t_hp);
    xp1_band = sync_1 .* cos(2*pi*(fc+df)*t_hp);
    
    % --- Thiết kế bộ lọc ---
    % Low-pass filter để lấy IQ (tần số cắt = df)
    Wn_lpf = df / (fs/2);
    [b_lpf, a_lpf] = butter(4, Wn_lpf, 'low');
    
    % Band-pass filter để tách riêng từng nhánh (băng thông 2*df)
    Wn0 = [(fc - 2*df), fc] / (fs/2);   % băng tần cho f0
    Wn1 = [fc, (fc + 2*df)] / (fs/2);   % băng tần cho f1
    [b0, a0] = butter(4, Wn0, 'bandpass');
    [b1, a1] = butter(4, Wn1, 'bandpass');
    
    % --- Tạo tín hiệu IQ cho sync phát (lý tưởng) ---
    % Hạ tần về baseband cho nhánh f0
    I0_tx = xp0_band .* cos(2*pi*(fc-df)*t_hp);
    Q0_tx = xp0_band .* sin(2*pi*(fc-df)*t_hp);
    xp0_IQ = filtfilt(b_lpf, a_lpf, I0_tx) + 1i * filtfilt(b_lpf, a_lpf, Q0_tx);
    
    % Hạ tần cho nhánh f1
    I1_tx = xp1_band .* cos(2*pi*(fc+df)*t_hp);
    Q1_tx = xp1_band .* sin(2*pi*(fc+df)*t_hp);
    xp1_IQ = filtfilt(b_lpf, a_lpf, I1_tx) + 1i * filtfilt(b_lpf, a_lpf, Q1_tx);
    
    % Zero-padding để FFT có độ dài L
    xp0_IQ_pad = [xp0_IQ, zeros(1, L - length(xp0_IQ))];
    xp1_IQ_pad = [xp1_IQ, zeros(1, L - length(xp1_IQ))];
    
    % FFT của tín hiệu phát (đã zero-pad)
    XP0 = fft(xp0_IQ_pad);
    XP1 = fft(xp1_IQ_pad);
    
    % --- Khởi tạo cell output ---
    num_frames = length(frames);
    H0_cell = cell(1, num_frames);
    H1_cell = cell(1, num_frames);
    
    % --- Lặp qua từng frame để ước lượng kênh ---
    for idx = 1:num_frames
        frame = frames{idx};
        if length(frame) < len_sync_ze
            warning('Frame %d có độ dài %d < %d (sync+ze). Bỏ qua ước lượng cho frame này.', ...
                idx, length(frame), len_sync_ze);
            continue;
        end
        
        % Cắt phần đầu frame: sync + ze (tín hiệu thu)
        hp = frame(1:len_sync_ze);
        
        % Lọc bandpass tách nhánh
        hp0_band = filtfilt(b0, a0, hp);
        hp1_band = filtfilt(b1, a1, hp);
        
       
        
        % Hạ tần về baseband cho nhánh f0
        I0_rx = hp0_band .* cos(2*pi*(fc-df)*t_hp);
        Q0_rx = hp0_band .* sin(2*pi*(fc-df)*t_hp);
        hp0_IQ = filtfilt(b_lpf, a_lpf, I0_rx) + 1i * filtfilt(b_lpf, a_lpf, Q0_rx);
        
        % Hạ tần cho nhánh f1
        I1_rx = hp1_band .* cos(2*pi*(fc+df)*t_hp);
        Q1_rx = hp1_band .* sin(2*pi*(fc+df)*t_hp);
        hp1_IQ = filtfilt(b_lpf, a_lpf, I1_rx) + 1i * filtfilt(b_lpf, a_lpf, Q1_rx);
        
        % Zero-padding để FFT có độ dài L
        hp0_IQ_pad = [hp0_IQ, zeros(1, L - length(hp0_IQ))];
        hp1_IQ_pad = [hp1_IQ, zeros(1, L - length(hp1_IQ))];
        
        % FFT
        HP0 = fft(hp0_IQ_pad);
        HP1 = fft(hp1_IQ_pad);
        
        % Chia (tránh chia cho 0)
        eps_val = 1e-6;
        H0 = (HP0 ./ (XP0 + eps_val)) +  eps_val;
        H1 = (HP1 ./ (XP1 + eps_val)) +  eps_val;
        
        % Lưu kết quả
        H0_cell{idx} = H0;
        H1_cell{idx} = H1;
        
        fprintf('Đã ước lượng kênh cho frame %d.\n', idx);
    end
    
    % Thông báo tổng kết
    valid_count = sum(~cellfun(@isempty, H0_cell));
    fprintf('Hoàn tất: ước lượng thành công cho %d/%d frame.\n', valid_count, num_frames);
end