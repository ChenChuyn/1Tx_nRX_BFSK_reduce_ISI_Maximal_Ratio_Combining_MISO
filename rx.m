% MISO - maximal ratio combining 
clc;clear;
params = create_params(); % khởi tạo các thông số

[frames, cnt] = capture_and_save_frames(params, 4); % thu âm và lưu các khung sau khi đã cắt

[H0, H1] = estimate_channel(params, frames); % ma trận kênh 

[YD0, YD1] = extract_payload_spectrum(params, frames);

XR0 = combine_all_subcarriers(H0, YD0);  % vector hàng 1xL
XR1 = combine_all_subcarriers(H1, YD1);  % vector hàng 1xL


% === Giả sử đã có: params, XR0, XR1 ===
N = params.N;
payload_bits = params.payload_bits;
len_payload_samples = N * length(payload_bits);

% 1. IFFT và cắt lấy phần payload
xr0 = ifft(XR0);
xr1 = ifft(XR1);
xd0 = xr0(1:len_payload_samples);
xd1 = xr1(1:len_payload_samples);

% 2. Kết hợp vi phân (differential)
xd = xd1 - xd0;   % vector cột (len_payload_samples x 1)

% 3. Chia thành các symbol (mỗi symbol có N mẫu)
num_symbols = floor(length(xd) / N);
xd_scat = xd(1:num_symbols * N);
xd_mat = reshape(xd_scat, N, []);   % mỗi cột là 1 symbol (N mẫu)

% 4. Trung bình các mẫu trong từng symbol → dùng để vẽ chòm sao
sym_mean = mean(xd_mat, 1).';        % vector cột (num_symbols x 1)

% Vẽ chòm sao TRƯỚC khi xoay pha
figure;
scatterplot(sym_mean);
title('Constellation BEFORE Rotation (symbol averages)');
grid on;

% 5. Ước lượng pha xoay từ tất cả các mẫu có phần thực > 0
%    (dùng xd gốc, không phải trung bình symbol)
%    Lưu ý: nếu không có mẫu nào thỏa mãn, dùng toàn bộ xd
samples_pos_real = xd(real(xd) > 0);
if isempty(samples_pos_real)
    pha = mean(angle(xd));
else
    pha = mean(angle(samples_pos_real));
end
fprintf('Ước lượng pha xoay: %.4f rad\n', pha);

% 6. Xoay pha toàn bộ tín hiệu xd (từng mẫu)
xr = xd * exp(-1j * pha);

% 7. Lại chia symbol và lấy trung bình cho chòm sao SAU xoay
xr_sc = xr(1:num_symbols * N);
xr_mat = reshape(xr_sc, N, []);
sym_mean_rot = mean(xr_mat, 1)';

% Vẽ chòm sao SAU khi xoay pha
figure;
scatterplot(sym_mean_rot);
title('Constellation AFTER Rotation (symbol averages)');
grid on;

% 8. Giải điều chế: bit = 1 nếu phần thực >= 0
Rx_data = (sym_mean_rot) >= 0;

% 9. Chuyển bit thành văn bản (cần hàm bits2text_pad)
RX_text = bits2text_pad(Rx_data);
disp('--- Decoded Text ---');
disp(RX_text);
% ... sau khi giải mã có Rx_data ...
ber = calculate_ber(params, Rx_data);