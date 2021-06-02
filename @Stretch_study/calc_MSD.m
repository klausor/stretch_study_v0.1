% Stretch_study method
% Applies MPT_to_MSDs on a stretch_study object, converting the first <mr_period> seconds of
% tracking into MSDs
% mr_period: Waiting time for MR before stretching starts; Should be 3 s
% Changes tracked attribute, excluding MSD-jump-particles



function stretch_study = calc_MSD(stretch_study, mr_period, varargin)
    addpath(genpath('C:\Users\Alexander\Desktop\Programmieren\mr_study_data'));
    
    % MSD settings
    switch questdlg('COM-correction?', '', 'No', 'Yes', 'Abbrechen', 'No')
        case 'Yes'
            msd_mode.com = true;
            disp('performing COM-correction ...');
        case 'No'
            msd_mode.com = false;
        otherwise
            return
    end
    switch questdlg('Calculate log-spaced MSDs or all MSDs?', '', 'Log; precision 0.001', 'All', 'Log; precision 0.001')
        case 'Log; precision 0.001'
            msd_mode.bigdata = true;
            msd_mode.bigdata_precision = 0.001;
        case 'All'
            msd_mode.bigdata = false;
        otherwise
            return
    end
    
    if msd_mode.com, error('COM not yet implemented for stretch study'); end
    % Cut stretching-MPT cell to first 3 s (MR) and convert to MSD table
    for i = 1:length(stretch_study)
        MPT = stretch_study(i).MPT_stretch;
        tracked_ = cellfun(@(x) ~isempty(x), MPT);
        Delta_t = MPT{find(tracked_,1)}.Properties.CustomProperties.Delta_t;
        nr_datapts_mr = floor(mr_period/Delta_t);
        for j = 1:length(MPT)
            if ~isempty(MPT{j})
                MPT{j} = MPT{j}(1:nr_datapts_mr,:);
            end
        end
        [stretch_study(i).MSD_prestretch, ~, tracked] = MPT_to_MSDs(msd_mode, MPT, stretch_study(i).meta.filenames{1,1}, 'del_unphysical');
        stretch_study(i).tracked{1, :} = stretch_study(i).tracked{1,:} & tracked; % Particles with jump-MSDs excluded
    end

end