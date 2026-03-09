%% CoralCTv2Mini Main script file

clear; close all force; clc;

%% Create UI figure 

UI = uifigure('Name','Coral CT v2.1 Mini','WindowState','Maximized','Color',[0.3 0.3 0.3]);

sn = 1;

% Change scene number based on forward back buttons(?)
while sn ~= 0
    
    % Create grid for multiple panels:
    uigrid = uigridlayout(UI,[100 100]);

    switch sn
        case 1
            % Load screen to import core, save as .mat file, and clip to ROI
            [sn,mfile] = GUI_LoadData(UI,uigrid);
            %[sn,mfile] = GUI_LoadDataBundle_v5(UI,uigrid);
        case 2
            % Load screen to import coral standards, calibrate density.
            [sn,mfile] = GUI_StandardCurve(UI,uigrid,mfile);
        case 3
            % Load screen to ID bands in core.
            %[s,sn] = GUI_BandID_v5(UI,uigrid,sn,mfile);
            [s,sn] = GUI_BandIDOpts(UI,uigrid,mfile);
        case 4
            % Load screen to identify band density and extension
            [s,sn] = GUI_BandDensExt(UI,uigrid,mfile);
        case 5
            % Process stress bands
            [s,sn] = GUI_SliceAnalysis(UI,uigrid,mfile);
        case 0
            close(UI);
    end
end

