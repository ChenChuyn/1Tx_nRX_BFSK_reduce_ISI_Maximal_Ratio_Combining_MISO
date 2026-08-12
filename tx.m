8% Algorithm inventor: Nguyen Quoc Khuong
% Algorithm implementer: Nguyen Hong Phuc
clear; clc;

% =========================================================================
% 1. DỮ LIỆU ĐẦU VÀO & THIẾT LẬP THÔNG SỐ FSK
% =========================================================================
text = 'day_la_doan_text_khong_dau_co_do_lon_chinh_xac_128_byte_dung_de_test_du_lieu_truyen_nhan_va_luu_tru_trong_he_thong_1231234567890';

fc = 12400;       % Tần số sóng mang (Hz)
df = 400;         % Độ lệch tần số (Hz)
fs = 192000;       % Tần số lấy mẫu (Hz)
br = 50;         % Tốc độ bit (bps)
z = 350;          % Số bit chèn không
N = round(fs/br); % Số lượng mẫu trên 1 bit

% =========================================================================
% 2. CẤU TRÚC KHUNG TRUYỀN (FRAME STRUCTURE)
% =========================================================================
% Preamble 64-bit
preamble = [ ...
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ];

% Sync sequence 255-bit (m-sequence)
sync = [ ...
1 1 1 1 1 1 1 1 0 1 1 1 0 0 0 1 0 0 1 1 1 0 1 0 0 1 0 1 1 0 0 1 ...
1 1 1 1 0 1 0 0 0 0 1 0 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 1 1 1 0 0 ...
1 0 0 0 0 1 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 1 0 1 ...
1 1 0 0 0 1 0 1 0 0 1 1 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 0 1 1 ...
1 0 1 0 1 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 0 1 1 0 1 1 0 0 0 1 0 1 ...
0 0 1 1 1 1 1 1 0 1 1 0 0 1 0 0 0 0 1 1 1 0 1 1 0 1 0 0 0 1 1 0 ...
1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 1 0 1 0 1 0 1 ...
0 1 0 0 1 1 0 1 1 1 0 0 0 1 1 0 1 1 0 0 1 1 0 ];

payload = text2bits(text);
ze = zeros(1, z*N);  % Tín hiệu chèn không (Guard Interval)

% =========================================================================
% 3. MÃ HÓA ĐƯỜNG TRUYỀN & ĐIỀU CHẾ FSK
% =========================================================================
pre_sig0 = linecoding(preamble, N, 0);
pre_sig1 = linecoding(preamble, N, 1);
sync_sig0 = linecoding(sync, N, 0);
sync_sig1 = linecoding(sync, N, 1);
pay_sig0 = linecoding(payload, N, 0);
pay_sig1 = linecoding(payload, N, 1);

% Ghép khung baseband
base0 = [pre_sig0 sync_sig0 ze pre_sig0 pay_sig0 ze];
base1 = [pre_sig1 sync_sig1 ze pre_sig1 pay_sig1 ze];

% Điều chế tín hiệu
t = (0:length(base0)-1)/fs;
frame0 = cos(2*pi*(fc-df)*t) .* base0;
frame1 = cos(2*pi*(fc+df)*t) .* base1;
frame_sig = frame0 + frame1; % Tín hiệu lý tưởng (Line-of-Sight)

% =========================================================================
% 4. MÔ PHỎNG KÊNH TRUYỀN UAC (ĐA ĐƯỜNG NGẪU NHIÊN & NHIỄU)
% =========================================================================

% Chuẩn hóa để tránh hiện tượng clipping khi phát âm thanh
final_sig = frame_sig / max(abs(frame_sig));

disp('Đang phát tín hiệu FSK qua bộ loa...');
player = audioplayer(final_sig, fs);
playblocking(player);   
disp('Đã phát xong.');

% Tùy chọn: Vẽ phổ tín hiệu để kiểm tra
% figure;
% pspectrum(final_sig, fs, 'FrequencyLimits', [fc-2000 fc+2000]);
% title('Phổ tín hiệu UAC sau khi qua kênh đa đường và nhiễu');