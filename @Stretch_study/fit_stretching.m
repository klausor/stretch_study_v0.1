% Converts radius over time in height and fits

function stretch_curves = fit_stretching(stretch_study, varargin)
incr = 1;
stretch_curves = {};
fitting_script_path = 'C:\Users\Alexander\Desktop\Programmieren\Mathematica\fitting_skript.m';
    for i = 1:length(stretch_study)
        % Iterate over Particles that are tracked, no jumps in MSD, have linear r-z-calibration
        for j = find(stretch_study(i).tracked{1,:})
            MPT = stretch_study(i).MPT_stretch{1,j};
            Delta_t = MPT.Properties.CustomProperties.Delta_t;
            cal = stretch_study(i).cal{1,j};
            % relative radius
            r = MPT.radius-min(MPT.radius);
            height = r/cal;
            timevec = (0:length(r)-1)*Delta_t; timevec = timevec';
            
            % Smoothing and cropping; "stretch": time | height(stretch) | height(relax)
            stretch= preprocess_stretching(height, Delta_t);
            [parms, fitd] = MPT_lib.apply_mathematica_script(stretch, fitting_script_path);
            parms = array2table(parms, 'VariableNames', {'E1', 'E2', 'eta1', 'eta2', 'E1relax', 'E2relax', 'eta1relax', 'eta2relax'}, 'RowNames', {'Estimate', 'Standard Error', 't-Statistic', 'P-Value'});
            parms.Properties.Description = 'Mathematica NonlinearModelFit, Saved parameters: nlmresult[ParameterTable]';
            fitdata = array2table(fitd, 'VariableNames', {'t', 'zfit(t) [µm]'});
            
            if length(varargin)==1 && strcmp(varargin{1}, 'test')
                figure; plot(timevec, height); hold on;
                fun = modelBurgersFixed(parms.E1(1), parms.E2(1), parms.eta1(1), parms.eta2(1));
                fplot(timevec, fun(timevec), 'Color', 'r', 'linewidth', 1);
            end
            incr = incr + 1;
        end
    end
    legend(p([1 4]), 'on the cell', 'inside the cell');
end