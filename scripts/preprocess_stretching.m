% Getestet, 12.03., stimmt
% Ändern bevor direkt gefitet werden kann: 
%   - r: px in µm umrechnen
% MPT2txt in Matlab programmieren. Figure mit Slider leicht umsetzbar
% Measurement nr
% Input: h: Calibrated but not smoothed

function [stretch] = preprocess_stretching(h, Delta_t)
    on_time = 1.25; % Shutter open for 1.3 s
    % 1/50 s is a meaningful level of smoothing (Tobi: ca. 1/35 s);
    h = movmean(h, 50);
    timevec = (0:length(h)-1)'*Delta_t;
    A = crop_stretching(timevec, h);
    waitfor(A, 'complete');
    xon = min([A.redline1.XData(1) A.redline2.XData(1)]);
    xoff = max([A.redline1.XData(1) A.redline2.XData(1)]);
    delete(A);

    % 0.1 s before stretching, curve set to 0 for more stable fitting
    padding = zeros(floor(0.1/Delta_t), 1);
    range_on = timevec>xon & timevec < xon+on_time-0.1;
    range_off = timevec>xoff & timevec < xoff+on_time-0.1;

    % Offset to zero;
    % Lenghts should be the same +-1 with same nr of zeros before (same idx(t=0))
    % TEST 
    h_stretch = [padding; h(range_on)-min(h(range_on))];
    h_relax = [padding; -1*h(range_off)+max(h(range_off))];
    len = min(length(h_stretch), length(h_relax));
    h_stretch = h_stretch(1:len); h_relax = h_relax(1:len);
    % Time is zero at stretching onset - From Tobi Skript - vllt wg. CumDistrFunc
    timevec = Delta_t*((0:length(h_stretch)-1)-length(padding))';
    % Cut datasets to same length
    stretch = [timevec h_stretch h_relax];
end