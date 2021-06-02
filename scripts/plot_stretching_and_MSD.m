% Converts radius over time in height and fits
% 1 Measurement parameter can be examined by drawing curves with certain parameter values in red
% NameValueArgs: 
%                'highlight_parms': 'MSD': Kurven von ruhigen Beads: Rot; loosely attached: Schwarz
%                                   'inBeam': In Strahlzentrum: rot; Äußerer Teil v. Strahl: orange; Außerhalb v. Strahl: schwarz
%                                   'height_above_substr': Colormap, rot: Beads weit über Substrat
%                'ramps'    : 'on': Plots ramps for each stretching curve
%                'only_tracked': 'on': Plots only particles whose ramps can be fit well
%                'meas_names': 'on: Legend with measurement number
%                'stretchaxis': ax: pass figure axis to function, so stretch curves get plotted on it, for e.g. subplots of multiple stretch studies
%                'MSDaxis': Same for MSDs
%                'ramp_parameter': Nichts: radius; 'brightness'
function stretch_curves = plot_stretching_and_MSD(stretch_study, NameValueArgs)
arguments
stretch_study
NameValueArgs.highlight_parms
NameValueArgs.ramps
NameValueArgs.meas_names
NameValueArgs.stretchaxis
NameValueArgs.MSDaxis
NameValueArgs.ramp_parameter
end
if isfield(NameValueArgs, 'ramp_parameter'), brightness_offset = 350; end % Offset for stretching/cal brighness curves
if isfield(NameValueArgs, 'stretchaxis')
    ax1 = NameValueArgs.stretchaxis; axes(ax1); % makes figure current
else
    figure('position', [500 100 450 900]); ax1 = gca;
end
hold on; xlabel('t [s]'); ylabel('\Delta z [µm]'); title(strcat(inputname(1), stretch_study(1).meta.manual_review)); axis([0 8 0 19]); ax1.FontSize = 12;
if isfield(NameValueArgs, 'ramps')
    figure('position', [500 100 450 900]); ax2 = gca; xlabel('t [s]'); ylabel('r [px]+ offset'); ax2.FontSize = 12; hold on; title('Z calibration ramps'); 
end
if isfield(NameValueArgs, 'stretchaxis')
    ax3 = NameValueArgs.MSDaxis; axes(ax3); % makes figure current
else
    figure; ax3 = gca;
end
set(gca, 'YScale', 'log', 'XScale', 'log'); hold on; axis([4e-4 1 5e-5 0.05]); title(strcat('MSD ', inputname(1)));
incr = 0;
stretch_curves = {};
p = [];
no_ramp_flag = 0; % If no linear calibration available
    for i = 1:length(stretch_study)
        tracked = stretch_study(i).tracked{:,:};
        % Only tracked particles with meaningful ramps
        for_idx = find(tracked);
        % Iterate over Particles that are tracked, no jumps in MSD, have linear r-z-calibration
        for j = for_idx
            MPT = stretch_study(i).MPT_stretch{1,j};
            Delta_t = MPT.Properties.CustomProperties.Delta_t;
            cal = stretch_study(i).cal{1,j};
            if cal == 0
                cal = 1.5;
                no_ramp_flag = 1;
            end
            % If no option provided: The parameter for the plotting of stretch curves is the radius
            if ~isfield(NameValueArgs, 'ramp_parameter')
                r = MPT.radius-min(MPT.radius);
                height = r/cal;
            % If brightness: Plot brightness-stretching curve w/o cal
            elseif strcmp(NameValueArgs.ramp_parameter, 'brightness')
                brightness = MPT.mean_brightness;
                answer = questdlg('Use calibration for conversion?');
                if strcmp(answer, 'Yes')
                    height = (brightness-min(brightness))/cal + 0.5;
                else
                    height = brightness+incr*brightness_offset;
                end
                no_ramp_flag = 0;
                ax1.YLim = [-inf inf]; ax1.YLabel.String = sprintf('Mean brightness, offset by %3d', brightness_offset);
            end
            timevec = (0:length(height)-1)*Delta_t; timevec = timevec';
            
            pname = MPT_lib.get_particle_names(j);
            MSD = stretch_study(i).MSD_prestretch.(pname{1}); timevec2 = stretch_study(i).MSD_prestretch.Properties.CustomProperties.lagtimes;
            plot(ax3, timevec2, MSD);
            % 1 measurement parameter can be examined by drawing the respectinve stretch curve in red
            if isfield(NameValueArgs, 'highlight_parms') 
                switch NameValueArgs.highlight_parms
                case 'MSD'
                    % Colormap des MSD vor Stretching im Bereich von 10^-4 und 10^-2 bei Oszillationsminimum (0.014 s)
                    idx140 = find(timevec2>0.014, 1);                    
                    jet_map = jet(256);
                    MSD140 = MSD(idx140);
                    bin_MSD = round(256*(log10(MSD140)+2)/(-2)); bin_MSD=min(bin_MSD, 256); bin_MSD = max(bin_MSD, 1);
                    plot_color = jet_map(bin_MSD, :);
                case 'inBeam'
                    % 0: on nucleus; 1: on beam edge; 2: beam edge half way on line between beam center and particle pos
                    jet_map = jet(256);
                    % If this function is called for multiple studies not all of which have this property set
                    if any(strcmp('inBeam', stretch_study(i).custom_parms.Properties.VariableNames))
                        beamparm = stretch_study(i).custom_parms.inBeam(j);
                        plot_color = jet_map(min([round(256*beamparm/2) 256]), :);
                    else
                        plot_color = [0 0 0];
                    end
                case 'height_above_substr'
                    jet_map = jet(256);
                    if any(strcmp('hight_above_substr_pifoc', stretch_study(i).custom_parms.Properties.VariableNames)) % does Prop exist?
                        total_height = stretch_study(i).custom_parms.hight_above_substr_pifoc(j);
                        if total_height==-1
                            plot_color = [0 0 0];
                        else
                            plot_color = jet_map(round(256*total_height/9), :);
                        end
                    else
                        plot_color = [0 0 0];
                    end
                end
            end
            
            % ||======================== PLOTTING ========================||
            % Display Name and Coordinates
            [~, filename] = fileparts(stretch_study(i).meta.filenames{1});
            coord = round([mean(stretch_study(i).MPT_stretch{j}.x(1:100)) mean(stretch_study(i).MPT_stretch{j}.y(1:100))]);
            if exist('plot_color', 'var')
                p(end+1) = plot(ax1, timevec, movmean(height, round(0.02/Delta_t))+incr, 'Color', plot_color, 'linewidth', 1.5, 'DisplayName', sprintf('%s, (%d, %d)', filename, coord(1), coord(2)));
            else
                p(end+1) = plot(ax1, timevec, movmean(height, round(0.02/Delta_t))+incr, 'linewidth', 1.5, 'DisplayName', sprintf('%s, (%d, %d)', filename, coord(1), coord(2)));
            end
            if no_ramp_flag
                pstar = plot(ax1, timevec(10), height(10)+incr, '*', 'MarkerSize', 6, 'Color', [0 0 0], 'DisplayName', 'no linear z calibration');
                no_ramp_flag = 0;
            end
            % Plots the z-ramps
            if isfield(NameValueArgs, 'ramps')
                if ~isfield(NameValueArgs, 'ramp_parameter')
                    h_cal = stretch_study(i).MPT_cal{j}.radius + 2*incr;
                % If brightness (Fluoresc. Height tracking)
                elseif strcmp(NameValueArgs.ramp_parameter, 'brightness')
                    h_cal = stretch_study(i).MPT_cal{j}.mean_brightness + incr*brightness_offset;
                    ax2.YLim = [-inf inf]; ax1.YLabel.String = sprintf('Mean brightness, offset by %3d', brightness_offset);
                end
                Deltat_cal = stretch_study(i).MPT_cal{j}.Properties.CustomProperties.Delta_t;
                plot(ax2, (1:length(h_cal))*Deltat_cal, movmean(h_cal, round(0.02/Deltat_cal)), 'LineWidth', 1);
            end
            incr = incr + 1;
            if incr == 19
                figure; ax1 = gca; hold on; ylabel('\Delta z [µm]'); title('#2'); axis([0 10 19 38]);
            end
        end
    end
    if isfield(NameValueArgs, 'highlight_parms') && strcmp(NameValueArgs.highlight_parms, 'height_above_substr')
        colormap(ax1, jet_map); cb = colorbar(ax1); cb.Ticks = [0 0.33 0.66 1]; cb.TickLabels = {'0', '3', '6', '9 µm'};
        cb.Label.String = 'Height of beads above substrate';
    elseif isfield(NameValueArgs, 'highlight_parms') && strcmp(NameValueArgs.highlight_parms, 'inBeam')
        colormap(ax1, jet_map); cb = colorbar(ax1); cb.Ticks = [0 0.33 0.66 1]; cb.TickLabels = {'0', '0.66', '1.33', '2'};
        cb.Label.String = 'Dist. from beam center. / beam radius';  cb.Label.FontSize = 11;
    elseif isfield(NameValueArgs, 'highlight_parms') && strcmp(NameValueArgs.highlight_parms, 'MSD')
        colormap(ax1, jet_map); cb = colorbar(ax1); cb.Ticks = [0 0.5 1]; cb.TickLabels = {'10^{-2}', '10^{-3}', '10^{-4}'};
        cb.Label.String = 'MSD @ 14ms';
    end
    if isfield(NameValueArgs, 'meas_names') && strcmp(NameValueArgs.meas_names, 'on')
        if exist('pstar', 'var') 
            legend([p pstar]);
        else
        	legend(p);
        end
    else
        if exist('pstar', 'var'), legend(pstar, 'No linear z-calibration.'); end
    end
end