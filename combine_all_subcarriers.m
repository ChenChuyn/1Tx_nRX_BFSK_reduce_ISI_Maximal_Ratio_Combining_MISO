function XR0 = combine_all_subcarriers(H0, YD0)
% COMBINE_ALL_SUBCARRIERS - MRC cho tất cả subcarriers
%
% Inputs:
%   H0  : cell {1 x nFrames}, mỗi phần tử là vector kênh (1 x L) hoặc (L x 1)
%   YD0 : cell {1 x nFrames}, mỗi phần tử là vector tín hiệu (1 x L) hoặc (L x 1)
%
% Output:
%   XR0 : vector phức (1 x L) sau khi MRC

    %% --- Kiểm tra đầu vào ---
    nFrames = length(H0);
    if nFrames == 0 || length(YD0) ~= nFrames
        error('H0 và YD0 phải cùng số phần tử và không rỗng.');
    end

    % Đảm bảo tất cả cùng độ dài
    L = length(H0{1});
    for i = 1:nFrames
        if length(H0{i}) ~= L || length(YD0{i}) ~= L
            error('Tất cả các vector trong H0 và YD0 phải cùng độ dài.');
        end
    end

    %% --- Khởi tạo ---
    XR0 = zeros(1, L);   % output

    %% --- MRC từng subcarrier ---
    for k = 1:L
        
        % Lấy vector kênh và tín hiệu tại subcarrier k
        h_k = zeros(nFrames,1);
        y_k = zeros(nFrames,1);

        for i = 1:nFrames
            h_k(i,1) = H0{i}(k);
            y_k(i,1) = YD0{i}(k);
        end

        % MRC: s = (h^H y) / (h^H h)
        sig = 1e-6;
        num = h_k' * y_k;
        den = h_k' * h_k + sig;

        if den > 0
            XR0(k) = num / den;
        else
            XR0(k) = 0;
        end
    end
end