% plots and fits radius-over-z ramps
% Test ok; Inspected with breakpoints; 
% Fitparameters stored in stretch_study(i).cal identical and in same order as their calculation in the script including non tracked ones
% See CAOS_METHODS_EVALUATION -> Stretching for diagrams for example rsquare thresholds; 0.88 seems to be good 10.03.21
% Radius smoothed to a resolution of 20 ms

function stretch_study = r_z_calibration(stretch_study)
% fit_frac: The triangular ramp is fitted from t(minimum) to t(min + % fitfrac*t_halframp); Additionally, only ramps are taken into account that have a significant slope at the start
    fit_frac = 0.7;
    rsquare_thresh = 0.9; % Include only particles with almost constant Slope
    % Which parameter should be fitted for height calibration?
    parm_list = {'radius', 'mean_brightness'};
    idx = listdlg('ListString', parm_list, 'InitialValue', 1, 'Name', 'Select height calibration parameter');
    if strcmp(parm_list{idx}, 'radius')
        fit_frac = 0.8;
    elseif strcmp(parm_list{idx}, 'mean_brightness')
        fit_frac = 0.5;
    end
    
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
            calparm = MPT.(parm_list{idx});
            
            % Find one maximum and one minimum and fit in between
            nr_pts_half = round(ampl/Delta_z);
            r_smooth = movmean(calparm, round(ampl/(4*Delta_z)));
            %[~, idx_max] = max(r_smooth(2*nr_pts_half:4*nr_pts_half)); idx_max = idx_max + 2*nr_pts_half;
            [~, idx_min] = min(r_smooth(2*nr_pts_half:4*nr_pts_half));
            idx_min = idx_min + 2*nr_pts_half;

            z_vec = Delta_z*(1:length(calparm))';
            % 0.02 Smoothing down to a time resolution of 20 ms
            if 0.02/Delta_t > 1, calparm = smooth(calparm, round(0.02/Delta_t)); end 
            
            plot(ax1, z_vec, 1.5*incr+calparm);
            % a: slope in px/µm
            ft = fittype(@(a, b, x) a.*x + b, 'independent', 'x');
            current_a = zeros(2,1); % stays zero for bad particles
            % 2 Slopes are fit and the result is averaged
            for j = 1:2
                % From min to min +- fit_frac * one nominal slope lenth;
                fitlims = [idx_min idx_min + nr_pts_half * fit_frac * (1-2*mod(j,2))];
                fitlims = round(sort(fitlims)); % smaller limit first
                [f, gof] = fit(z_vec(fitlims(1):fitlims(2)), calparm(fitlims(1):fitlims(2)), ft, 'StartPoint',[1 9]);
                fc = @(x) f.a.*x+f.b;
               % If cannot be properly fitted linearly: Skip particle
                % Rsquared: Mittl. quadratische Abw. d. Regression vom Mittelwert /(durch) mittl quadr. Abweichung der stichproben vom Mittelwert
                if gof.rsquare < rsquare_thresh
                    current_a = zeros(2,1);
                    break
                end
                fplot(ax1, @(x) 1.5*incr + fc(x), [z_vec(fitlims(1)) z_vec(fitlims(2))], 'Color', 'r', 'linewidth', 1, 'DisplayName', sprintf('r^2: %.2f', gof.rsquare));
                current_a(j) = f.a;
            end
            cal(k) = (abs(current_a(1)) + abs(current_a(2)))/2;
            incr = incr+1;
        end
        stretch_study(i).cal = array2table(cal, 'VariableNames', stretch_study(i).tracked.Properties.VariableNames);
        stretch_study(i).cal.Properties.Description = ['Slope [px/µm] of z ramp; Fraction of ramp ampl. fitted: ' num2str(fit_frac) 'r^2 threshold for non-linear particles: ' num2str(rsquare_thresh)];
        stretch_study(i).cal = addprop(stretch_study(i).cal, 'Delta_z', 'table'); stretch_study(i).cal.Properties.CustomProperties.Delta_z = Delta_z;
        plot(ax2, i*ones(length(cal), 1), cal', '^', 'linestyle', 'none', 'markersize', 8);
    end
    axes(ax2); xlabel('cell nr.'); ylabel('cal constant [px]/µm'); set(ax1, 'fontsize', 14); axes(ax1); xlabel('$\mathrm{\sum \Delta z}$', 'Interpreter', 'Latex');  ylabel('Radius [px]'); set(ax2, 'fontsize', 14);
end