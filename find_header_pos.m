function idx = find_header_pos(rx, header)
% Tìm vị trí bắt đầu header trong rx

rx     = rx(:);
header = header(:);

h = conj(flipud(header));
y = filter(h, 1, rx);

[~, idx_peak] = max(abs(y));

% quy đổi về vị trí bắt đầu header
idx = idx_peak - length(header) + 1;
end
