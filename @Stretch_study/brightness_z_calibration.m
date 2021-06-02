% Converts the brightness from the fluorescence signal of a stretching measurement into height units
% Stores them in stretch_study(i).bright_cal
function stretch_study = brightness_z_calibration(stretch_study)
    
    % Graph displaying ramps and maximum stretch amplitude
    f1 = figure; ax1 = gca; title('r [px], smoothed to 20ms'); hold on; legend('show'); f2 = figure; ax2 = gca; hold on;
    incr = 0;
    for i = 1:length(stretch_study)
        tracked_idx = find(stretch_study(i).tracked{1,:});
        cal = zeros(size(stretch_study(i).tracked));
        for k = tracked_idx
            % Extract attributes from table properties
            MPT = stretch_study(i).MPT_cal{k};
            ampl = MPT.Properties.CustomProperties.ampl_ramp;
            f_ramp = MPT.Properties.CustomProperties.f_ramp;
            Delta_t = MPT.Properties.CustomProperties.Delta_t;
            Delta_z = ampl/(0.5*(1/f_ramp)/Delta_t);
            r = MPT.radius;
            % Smoothes down to a time resolution of ~ 20 ms
            smooth_pts = round(0.02/Delta_t);

            
            % Find first 3 minima; Recording of >= 3 s @ 1Hz necessary
            nr_pts_half = floor(ampl/Delta_z);
            r_smooth = movmean(r, round(ampl/(4*Delta_z)));
            min_idx = find_cal_minima(r_smooth, nr_pts_half, 3, 10); % Yields indices of first 3 minima
            
            z_vec = Delta_z*(1:length(r))';
            r = movmean(r, smooth_pts); 
            
            % Aus den letzten 2 min 4 Kurven extrahieren, linear interpolieren, Bereich wo alle pos. sind finden und mitteln
            % In Stretching-Kurve aus jedem Intensitätswert einem Höhenwert zuordnen
            
            
            
            plot(ax1, 1.5*incr+r);
            
            
            
            
            incr = incr+1;
        end
        stretch_study(i).cal = array2table(cal, 'VariableNames', stretch_study(i).tracked.Properties.VariableNames);
        stretch_study(i).cal.Properties.Description = ['Slope [px/µm] of z ramp; Fraction of ramp ampl. fitted: ' num2str(fit_frac) 'r^2 threshold for non-linear particles: ' num2str(rsquare_thresh)];
        stretch_study(i).cal = addprop(stretch_study(i).cal, 'Delta_z', 'table'); stretch_study(i).cal.Properties.CustomProperties.Delta_z = Delta_z;
        plot(ax2, i*ones(length(cal), 1), cal', '^', 'linestyle', 'none', 'markersize', 8);
    end
    axes(ax2); xlabel('cell nr.'); ylabel('cal constant [px]/µm'); set(ax1, 'fontsize', 14); axes(ax1); xlabel('summed up Deltaz [µm]'); ylabel('Radius [px]'); set(ax2, 'fontsize', 14);

end