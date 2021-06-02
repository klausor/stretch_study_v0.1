% Finds <nr_min> minima in r_smooth, that are separated by 2*<nr_pts_half> points
% shift: Index in r_smooth where the searching for first minimum starts

% For calibration with fluorescence brightness signal

function min_idx = find_cal_minima(r_smooth, nr_pts_half, nr_min, shift)
    min_idx = zeros(length(nr_min), 1);
    for j = 0:nr_min-1
        % Index range in which to search jth minimum
        idx_range = (2*j)*nr_pts_half + shift : (2*j+2)*nr_pts_half + shift;
        [~, min_idx(j)] = min(r_smooth(idx_range));
        % If min is first or last idx in range -> shift and search
        if min_idx(j) == idx_range(1) || min_idx(j) == idx_range(end) 
            min_idx = find_cal_minima(r_smooth, nr_pts_half, nr_min, shift+5);
            break
        end
    end
end