function params = create_params()
% CREATE_PARAMS Khởi tạo struct chứa toàn bộ thông số hệ thống
%   params = create_params() trả về struct với các trường:
%       .text, .fc, .df, .fs, .br, .z, .N, .preamble, .sync,
%       .payload_bits, .ze_bits, .frame_bits, .frame_length

    % Văn bản cần truyền
    params.text = 'day_la_doan_text_khong_dau_co_do_lon_chinh_xac_128_byte_dung_de_test_du_lieu_truyen_nhan_va_luu_tru_trong_he_thong_1231234567890';
    
    % Thông số điều chế
    params.fc = 12400;      % tần số sóng mang (Hz)
    params.df = 400;        % độ dịch tần số FSK (Hz)
    params.fs = 192000;      % tần số lấy mẫu (Hz)
    params.br = 800;        % tốc độ bit (bps)
    params.z = 350;         % số bit zero chèn vào frame
    
    % Số mẫu trên mỗi bit
    params.N = round(params.fs / params.br);
    
    % Preamble 64 bit (dạng nhị phân)
    params.preamble = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
                       1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
                       1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 ...
                       1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0];
    
    % Sync 255 bit (mã Barker dài)
    params.sync = [1 1 1 1 1 1 1 1 0 1 1 1 0 0 0 1 0 0 1 1 1 0 1 0 0 1 0 1 1 0 0 1 ...
                   1 1 1 1 0 1 0 0 0 0 1 0 0 1 0 0 0 1 1 0 1 0 1 1 1 0 1 1 1 1 0 0 ...
                   1 0 0 0 0 1 0 1 1 1 0 1 1 0 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 1 0 1 ...
                   1 1 0 0 0 1 0 1 0 0 1 1 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 0 1 1 ...
                   1 0 1 0 1 1 0 1 0 0 0 1 1 1 0 0 0 0 1 1 0 1 1 0 1 1 0 0 0 1 0 1 ...
                   0 0 1 1 1 1 1 1 0 1 1 0 0 1 0 0 0 0 1 1 1 0 1 1 0 1 0 0 0 1 1 0 ...
                   1 0 1 0 1 1 0 0 1 1 1 0 0 1 0 0 1 0 1 1 0 0 0 0 1 1 0 1 0 1 0 1 ...
                   0 1 0 0 1 1 0 1 1 1 0 0 0 1 1 0 1 1 0 0 1 1 0];
    
    % Chuyển văn bản thành chuỗi bit
    params.payload_bits = text2bits(params.text);
    
    % Bit zero chèn (số bit = z)
    params.ze_bits = zeros(1, params.z);
    
    % Ghép toàn bộ frame (ở dạng bit)
    params.frame_bits = [params.sync, params.ze_bits, params.preamble, ...
                         params.payload_bits, params.ze_bits];
    
    % Chiều dài frame tính theo số mẫu
    params.frame_length = length(params.frame_bits) * params.N;
end