% Prints list of MPT-files in the order of the elements in mr_study_data
% E.g. for assigning custom parameters to each element

function filelist = print_filelist(obj)
    filelist = cell(length(obj), 1);
    for i = 1:length(obj)
        filelist{i} = obj(i).meta.filenames{2,1};
    end
    disp(filelist);
end