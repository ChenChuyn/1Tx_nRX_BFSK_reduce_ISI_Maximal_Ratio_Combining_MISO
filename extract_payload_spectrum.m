function [YD0, YD1] = extract_payload_spectrum(params, frames)
% EXTRACT_PAYLOAD_SPECTRUM Trích xuất phổ của phần payload từ các frame
%   Đầu vào:
%       params - struct từ create_params (chứa .fs, .fc, .df, .N, .payload_bits, .z)
%       frames - cell array chứa các tín hiệu frame đã thu (mỗi frame là vector)
%   Đầu ra:
%       YD0 - cell array, mỗi phần tử là phổ (FFT) của payload đã được hạ tần về baseband cho nhánh f0
%       YD1 - tương tự cho nhánh f1

    % Giải nén thông số
    fs = params.fs;
    fc = params.fc;
    df = params.df;
    N = params.N;
    payload_bits = params.payload_bits;
    z = params.z;
    
    len_payload_ze = N * (length(payload_bits) + z);
    
    % Thiết kế bộ lọc (giống với hàm estimate_channel)
    Wn_lpf = df / (fs/2);
    [b_lpf, a_lpf] = butter(4, Wn_lpf, 'low');
    
    Wn0 = [(fc - 2*df), fc] / (fs/2);
    Wn1 = [fc, (fc + 2*df)] / (fs/2);
    [b0, a0] = butter(4, Wn0, 'bandpass');
    [b1, a1] = butter(4, Wn1, 'bandpass');
    
    num_frames = length(frames);
    YD0 = cell(1, num_frames);
    YD1 = cell(1, num_frames);
    
    for idx = 1:num_frames
        frame = frames{idx};
        if length(frame) < len_payload_ze
            warning('Frame %d có độ dài %d < %d (payload+ze). Bỏ qua.', idx, length(frame), len_payload_ze);
            continue;
        end
        
        % Lấy phần cuối của frame: payload + ze
        payload_part = frame(end - len_payload_ze + 1 : end);
        
        % Tách nhánh bằng bandpass
        p0_band = filtfilt(b0, a0, payload_part);
        p1_band = filtfilt(b1, a1, payload_part);
        
        % Thời gian tương ứng
        t = (0:len_payload_ze-1) / fs;
        
        % Hạ tần về baseband cho nhánh f0
        I0 = p0_band .* cos(2*pi*(fc-df)*t);
        Q0 = p0_band .* sin(2*pi*(fc-df)*t);
        p0_IQ = filtfilt(b_lpf, a_lpf, I0) + 1i * filtfilt(b_lpf, a_lpf, Q0);
        
        % Hạ tần cho nhánh f1
        I1 = p1_band .* cos(2*pi*(fc+df)*t);
        Q1 = p1_band .* sin(2*pi*(fc+df)*t);
        p1_IQ = filtfilt(b_lpf, a_lpf, I1) + 1i * filtfilt(b_lpf, a_lpf, Q1);
        
        % FFT (không zero-pad thêm)
        YD0{idx} = fft(p0_IQ);
        YD1{idx} = fft(p1_IQ);
        
        fprintf('Đã xử lý payload cho frame %d.\n', idx);
    end
    
    valid = sum(~cellfun(@isempty, YD0));
    fprintf('Hoàn tất: xử lý thành công %d/%d frame.\n', valid, num_frames);
end