% Add parms for each measurement to all particles of this measurement as a column in the 'custom_parms' property of stretch study
% Excel: 1st column name: 'measurement'
%        2nd column name: <parameter name>
function stretch_study = add_custom_parms(stretch_study)

    % --------------------------------- INPUTS and IMPORT data from excel sheet --------------------------------------- %
    % All custom props having been used are listed for choice
    [file, path] = uigetfile('C:\*.xlsx');
    sheet_name = inputdlg('Which sheet?');
    warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
    T = readtable(fullfile(path, file), 'Range', 'A1', 'Sheet', sheet_name{1});
    warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');

    % ------------------------- CURRENTLY ONLY ADDS SECON COLUMN ----------------%
    parm_name = T.Properties.VariableNames{2};
    descr = inputdlg('Add description of added parameter');
    for i = 1:length(stretch_study)
        [~, meas_name] = fileparts(stretch_study(i).meta.filenames{2});
        if ~strcmp(meas_name, T{i,1})
            error('measurement names in table dont match with meas in stretch_study');
        end
        % for non tracked or bad calibration particles: -1 in custom props
        tracked = stretch_study(i).tracked{:,:};
        parm_vec = -1*ones(size(tracked));
        parm_vec(find(tracked)) = T.(parm_name)(i);
        stretch_study(i).custom_parms.(parm_name) = parm_vec';
        stretch_study(i).custom_parms.Properties.VariableDescriptions{end+1} = sprintf('%s, Parameter manually added from excel table %s', descr{1,1}, file);
    end
end