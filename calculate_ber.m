function ber = calculate_ber(params, Rx_data)
% CALCULATE_BER Tính tỷ lệ lỗi bit giữa dữ liệu giải mã và dữ liệu gốc
%   Đầu vào:
%       params  - struct chứa trường .payload_bits (vector bit gốc)
%       Rx_data - vector bit giải mã (logical hoặc double 0/1)
%   Đầu ra:
%       ber     - tỷ lệ lỗi bit (số bit sai / tổng số bit)

    % Lấy bit gốc
    tx_bits = params.payload_bits(:);   % chuyển thành vector cột
    rx_bits = Rx_data(:);               % chuyển thành vector cột
    
    % Đảm bảo cùng độ dài (cắt theo độ dài ngắn hơn)
    min_len = min(length(tx_bits), length(rx_bits));
    if length(tx_bits) ~= length(rx_bits)
        warning('Độ dài bit gốc (%d) và bit giải mã (%d) khác nhau. Chỉ tính trên %d bit đầu.', ...
            length(tx_bits), length(rx_bits), min_len);
        tx_bits = tx_bits(1:min_len);
        rx_bits = rx_bits(1:min_len);
    end
    
    % Đếm số bit sai
    errors = sum(tx_bits ~= rx_bits);
    ber = errors / min_len;
    
    % In kết quả ra màn hình
    fprintf('\n=== KẾT QUẢ BER ===\n');
    fprintf('Tổng số bit so sánh: %d\n', min_len);
    fprintf('Số bit lỗi: %d\n', errors);
    fprintf('Tỷ lệ lỗi bit (BER): %.6f (%.4f%%)\n', ber, ber*100);
end