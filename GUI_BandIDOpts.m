function [s3,sn] = GUI_BandIDOpts(UI,uigrid,mfile)
% created 3/6/24 - Mariya
% edited 2/5/25 to include plotted point where band intersects in
% previous slide
% last edited 10/5/25 for mini version

% Screen 3 - Allows users to manually select bands + edit all bands
% edited to allow users to also select stress bands

%% Set default parameters
metadata = mfile.metadata;
ReconDims = mfile.ReconDims;
hpxS = metadata.PixelSpacing;
SectionLength = 10; % default section length = 10 cm
SectionOverlap = 25; % default section overlap = 25%
contra = [0.4 1.5]; % default max/min density contrast
projOptions = {'max','mean','min'}; % projection options
proj = projOptions{2}; % set default proj to 'min'
slabThick = 3; % default slab thickness is 3mm
%layersTot = 0;

section = 1; SectionRange = []; SectionTot = [];
slabNum = 1;
ScanXn = [];

loadSection;

slabLoc = chooseSlabLocs;
middle = [slabLoc(1), slabLoc(4)]; % horizontal and vertical center lines

% check if bandLocs exists
variableInfo = who(mfile);

if ismember('bandLocs',variableInfo) && ~isempty(mfile.bandLocs)
    bandLocs = mfile.bandLocs;
else
    bandLocs = cell(1,6);
end

if ismember('stressBands',variableInfo) && ~isempty(mfile.stressBands)
    stressBands = mfile.stressBands;
    %startBand = size(bandLocs,1);
else
    stressBands = cell(1,6);
    %startBand = 1;
end
hPolyline = [];

%% Panel 1 - set section length and overlap
s3(1).panel = uipanel(uigrid,'Title','1. Set Section Parameters');
s3(1).panel.Layout.Row = [3 15];
s3(1).panel.Layout.Column = [3 25];

s3(1).grid = uigridlayout(s3(1).panel,[20 10]);
s3(1).label(1) = uilabel(s3(1).grid);
s3(1).label(1).Text = 'Section Length (cm)';
s3(1).label(1).Layout.Column = [1 10];
s3(1).label(1).Layout.Row = [1 3];

s3(1).field(1) = uieditfield(s3(1).grid,"numeric","Limits",[5 40],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",SectionLength);
s3(1).field(1).Layout.Column = [11 17];
s3(1).field(1).Layout.Row = [1 3];

s3(1).label(2) = uilabel(s3(1).grid);
s3(1).label(2).Text = 'Section Overlap (%)';
s3(1).label(2).Layout.Column = [1 10];
s3(1).label(2).Layout.Row = [4 6];

s3(1).field(2) = uieditfield(s3(1).grid,"numeric","Limits",[10 30],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",SectionOverlap);
s3(1).field(2).Layout.Column = [11 17];
s3(1).field(2).Layout.Row = [4 6];

s3(1).button(1) = uibutton(s3(1).grid);
s3(1).button(1).Text = 'Set Section Parameters';
s3(1).button(1).Layout.Column = [1 18];
s3(1).button(1).Layout.Row = [7 9];

%% Panel 2 - input plotting parameters
%thick = round(3/hpxS)/2; % default slice thickness (3mm) in pixels!!

s3(2).panel = uipanel(uigrid,'Title','2. Slab Plotting Parameters');
s3(2).panel.Layout.Row = [17 50];
s3(2).panel.Layout.Column = [3 25];

s3(2).grid = uigridlayout(s3(2).panel,[40 20]);
s3(2).label(1) = uilabel(s3(2).grid);
s3(2).label(1).Text = 'Enter minimum density';
s3(2).label(1).Layout.Column = [1 10];
s3(2).label(1).Layout.Row = [1 3];

s3(2).field(1) = uieditfield(s3(2).grid,"numeric","Value",contra(1));
s3(2).field(1).Layout.Column = [13 20];
s3(2).field(1).Layout.Row = [1 3];

s3(2).label(2) = uilabel(s3(2).grid);
s3(2).label(2).Text = 'Enter maximum density';
s3(2).label(2).Layout.Column = [1 12];
s3(2).label(2).Layout.Row = [4 6];

s3(2).field(2) = uieditfield(s3(2).grid,"numeric","Value",contra(2));
s3(2).field(2).Layout.Column = [13 20];
s3(2).field(2).Layout.Row = [4 6];

s3(2).label(3) = uilabel(s3(2).grid);
s3(2).label(3).Text = 'Choose projection';
s3(2).label(3).Layout.Column = [1 12];
s3(2).label(3).Layout.Row = [7 9];

s3(2).field(3) = uidropdown(s3(2).grid);
s3(2).field(3).Items = projOptions;
s3(2).field(3).Layout.Column = [13 20];
s3(2).field(3).Layout.Row = [7 9];

s3(2).label(4) = uilabel(s3(2).grid);
s3(2).label(4).Text = 'Slab Thickness (mm)';
s3(2).label(4).Layout.Column = [1 12];
s3(2).label(4).Layout.Row = [10 12];

s3(2).field(4) = uieditfield(s3(2).grid,"numeric","Limits",[0.2 12],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",slabThick);
s3(2).field(4).Layout.Column = [13 20];
s3(2).field(4).Layout.Row = [10 12];

s3(2).label(5) = uilabel(s3(2).grid);
s3(2).label(5).Text = 'Slab X Location (pixels)';
s3(2).label(5).Layout.Column = [1 12];
s3(2).label(5).Layout.Row = [13 15];

slabXloc = 1;
s3(2).field(5) = uieditfield(s3(2).grid,"numeric","Limits",[1 size(ScanXn,2)],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",slabXloc);
s3(2).field(5).Layout.Column = [13 20];
s3(2).field(5).Layout.Row = [13 15];
s3(2).field(5).Enable = "off";

s3(2).label(6) = uilabel(s3(2).grid);
s3(2).label(6).Text = 'Slab Y Location (pixels)';
s3(2).label(6).Layout.Column = [1 12];
s3(2).label(6).Layout.Row = [16 18];

slabYloc = slabLoc(slabNum);
s3(2).field(6) = uieditfield(s3(2).grid,"numeric","Limits",[1 size(ScanXn,1)],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",slabYloc);
s3(2).field(6).Layout.Column = [13 20];
s3(2).field(6).Layout.Row = [16 18];
s3(2).field(6).Enable = "off";

s3(2).button(1) = uibutton(s3(2).grid);
s3(2).button(1).Text = 'Apply Plotting Parameters';
s3(2).button(1).FontWeight = 'bold';
s3(2).button(1).Layout.Column = [1 20];
s3(2).button(1).Layout.Row = [19 21];

% s3(2).button(2) = uibutton(s3(2).grid);
% s3(2).button(2).Text = 'Set Parameters';
% s3(2).button(2).Enable = 'off';
% s3(2).button(2).FontWeight = 'bold';
% s3(2).button(2).Layout.Column = [8 20];
% s3(2).button(2).Layout.Row = [16 19];
% s3(2).button(2).BackgroundColor = [0.9294 0.4627 0.3804];

%% Panel 3 - Plot middle of core with slab location
s3(3).panel = uipanel(uigrid,'Title','3. Core Slab Location');
s3(3).panel.Layout.Row = [52 80];
s3(3).panel.Layout.Column = [3 25];

%% Panel 4 - Plot the Slab
s3(4).panel = uipanel(uigrid,'Title','4. Selected Slab of CT Scan');
s3(4).panel.Layout.Row = [3 80];
s3(4).panel.Layout.Column = [27 70];
s3(4).axis(1) = axes(s3(4).panel);

%% Panel 5 - Section and Slab Info
s3(5).panel = uipanel(uigrid,'Title','5. Section and Slab Info');
s3(5).panel.Layout.Row = [3 20];
s3(5).panel.Layout.Column = [72 98];

s3(5).grid = uigridlayout(s3(5).panel,[20 10]);
s3(5).label(1) = uilabel(s3(5).grid);
s3(5).label(1).Text = ['Section # (i.e. Section 1 is the top ' int2str(SectionLength) ' cm of the core)'];
s3(5).label(1).WordWrap = 'on';
s3(5).label(1).Layout.Column = [1 16];
s3(5).label(1).Layout.Row = [1 4];

s3(5).field(1) = uieditfield(s3(5).grid,"numeric","Limits",[1 SectionTot],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",section, 'Editable', true);
s3(5).field(1).Layout.Column = [17 20];
s3(5).field(1).Layout.Row = [1 4];
%s3(5).field(1).BackgroundColor = '#c4c3c2';

s3(5).label(2) = uilabel(s3(5).grid);
s3(5).label(2).Text = 'Slab # (out of 6)';
s3(5).label(2).WordWrap = 'on';
s3(5).label(2).Layout.Column = [1 16];
s3(5).label(2).Layout.Row = [5 8];

s3(5).field(2) = uieditfield(s3(5).grid,"numeric","Limits",[1 6],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",slabNum, 'Editable', true);
s3(5).field(2).Layout.Column = [17 20];
s3(5).field(2).Layout.Row = [5 8];
%s3(5).field(2).BackgroundColor = '#c4c3c2';

s3(5).cbx(1) = uicheckbox(s3(5).grid,"Text"," Plot existing bands");
s3(5).cbx(1).Layout.Column = [1 10];
s3(5).cbx(1).Layout.Row = [9 12];
s3(5).cbx(1).Value = 1;

s3(5).button(1) = uibutton(s3(5).grid);
s3(5).button(1).Text = 'Apply';
s3(5).button(1).Enable = 'off';
s3(5).button(1).Layout.Column = [11 20];
s3(5).button(1).Layout.Row = [9 12];

sliceText = ["Slice 1", "Slice 2", "Slice 3", "Slice 4", "Slice 5", "Slice 6"];
colorOpts = {[1 1 1], [1 0 0], [0 1 1], [0 1 0], [1 1 0], [1 0 1]}; % white, red, cyan, green, yellow, magenta

for k = 1:6
    s3(5).label(3+k) = uilabel(s3(5).grid);
    s3(5).label(3+k).Text = sliceText(k);
    s3(5).label(3+k).FontColor = colorOpts{k}; % Set color
    s3(5).label(3+k).Layout.Column = (k-1)*3 + [1 3]; % Spread out labels
    s3(5).label(3+k).Layout.Row = [12 15];
end

%% Panel 6 - Band Editing
s3(6).panel = uipanel(uigrid,'Title','6. User Band Editing');
s3(6).panel.Layout.Row = [21 39];
s3(6).panel.Layout.Column = [72 98];

s3(6).grid = uigridlayout(s3(6).panel,[30 20]);
s3(6).label(1) = uilabel(s3(6).grid);
s3(6).label(1).Text = 'Delete Band #';
s3(6).label(1).Layout.Column = [1 6];
s3(6).label(1).Layout.Row = [1 3];

s3(6).field(1) = uieditfield(s3(6).grid,"numeric","Limits",[1 145],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",1, 'Editable', true);
s3(6).field(1).Layout.Column = [7 9];
s3(6).field(1).Layout.Row = [1 3];

s3(6).button(1) = uibutton(s3(6).grid);
s3(6).button(1).Text = 'Delete in this slab';
s3(6).button(1).Enable = 'off';
s3(6).button(1).Layout.Column = [1 9];
s3(6).button(1).Layout.Row = [4 7];

s3(6).button(2) = uibutton(s3(6).grid);
s3(6).button(2).Text = 'Delete in all slabs';
s3(6).button(2).Enable = 'off';
s3(6).button(2).Layout.Column = [1 9];
s3(6).button(2).Layout.Row = [8 11];

s3(6).label(2) = uilabel(s3(6).grid);
s3(6).label(2).Text = 'Insert new band';
s3(6).label(2).Layout.Column = [11 17];
s3(6).label(2).Layout.Row = [1 3];

s3(6).field(2) = uieditfield(s3(6).grid,"numeric","Limits",[1 145],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",1, 'Editable', true);
s3(6).field(2).Layout.Column = [18 20];
s3(6).field(2).Layout.Row = [1 3];

s3(6).button(3) = uibutton(s3(6).grid);
s3(6).button(3).Text = 'Insert a new band';
s3(6).button(3).Enable = 'off';
s3(6).button(3).Layout.Column = [11 20];
s3(6).button(3).Layout.Row = [4 7];

s3(6).button(4) = uibutton(s3(6).grid,'state');
s3(6).button(4).Text = 'Save Band';
s3(6).button(4).Value = 0;
s3(6).button(4).Enable = 'off';
s3(6).button(4).Layout.Column = [11 20];
s3(6).button(4).Layout.Row = [8 11];

s3(6).label(2) = uilabel(s3(6).grid);
s3(6).label(2).Text = '(Select band, hit ENTER, and press "Save Band")';
s3(6).label(2).WordWrap = 'on';
s3(6).label(2).Layout.Column = [11 20];
s3(6).label(2).Layout.Row = [12 15];

% colorOpts = ['w';'r';'c';'g';'y';'c'];
%
% blackBox = uicontrol(s3(6).panel, 'Style', 'text', 'String', 'Slab 1', 'BackgroundColor', 'black','ForegroundColor','w');
% blackBox.Position = [10, 12, 50, 20]; % [left, bottom, width, height]

%% Panel 7 - Stress Band Identification
s3(7).panel = uipanel(uigrid,'Title','7. Stress Band Identification');
s3(7).panel.Layout.Row = [40 65];
s3(7).panel.Layout.Column = [72 98];

s3(7).grid = uigridlayout(s3(7).panel,[30 20]);
s3(7).label(1) = uilabel(s3(7).grid);
s3(7).label(1).Text = 'OPTIONAL - Identify stress bands within core';
s3(7).label(1).FontWeight = 'bold';
s3(7).label(1).Layout.Column = [1 20];
s3(7).label(1).Layout.Row = [1 3];

s3(7).label(2) = uilabel(s3(7).grid);
s3(7).label(2).Text = 'User-identified stress bands will be marked along the final Along-Polyp Density. Stress band ID will not affect any calculations.';
s3(7).label(2).WordWrap = 'on';
s3(7).label(2).Layout.Column = [1 20];
s3(7).label(2).Layout.Row = [4 7];

s3(7).label(3) = uilabel(s3(7).grid);
s3(7).label(3).Text = 'Delete stress band';
s3(7).label(3).Layout.Column = [1 7];
s3(7).label(3).Layout.Row = [10 12];

s3(7).field(1) = uieditfield(s3(7).grid,"numeric","Limits",[1 145],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",1, 'Editable', true);
s3(7).field(1).Layout.Column = [7 9];
s3(7).field(1).Layout.Row = [10 12];

s3(7).button(1) = uibutton(s3(7).grid);
s3(7).button(1).Text = 'Delete in this slab';
s3(7).button(1).Enable = 'off';
s3(7).button(1).Layout.Column = [1 9];
s3(7).button(1).Layout.Row = [13 16];

s3(7).button(2) = uibutton(s3(7).grid);
s3(7).button(2).Text = 'Delete in all slabs';
s3(7).button(2).Enable = 'off';
s3(7).button(2).Layout.Column = [1 9];
s3(7).button(2).Layout.Row = [17 20];

s3(7).label(4) = uilabel(s3(7).grid);
s3(7).label(4).Text = 'ID new stress band';
s3(7).label(4).Layout.Column = [11 17];
s3(7).label(4).Layout.Row = [10 12];

s3(7).field(2) = uieditfield(s3(7).grid,"numeric","Limits",[1 145],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",1, 'Editable', true);
s3(7).field(2).Layout.Column = [18 20];
s3(7).field(2).Layout.Row = [10 12];

s3(7).button(3) = uibutton(s3(7).grid);
s3(7).button(3).Text = 'Insert new stress band';
s3(7).button(3).Enable = 'off';
s3(7).button(3).Layout.Column = [11 20];
s3(7).button(3).Layout.Row = [13 16];

s3(7).button(4) = uibutton(s3(7).grid,'state');
s3(7).button(4).Text = 'Save Band';
s3(7).button(4).Value = 0;
s3(7).button(4).Enable = 'off';
s3(7).button(4).Layout.Column = [11 20];
s3(7).button(4).Layout.Row = [17 20];

%% Panel 8 - Band Identification

s3(8).panel = uipanel(uigrid,'Title','8. Finished Band Identification');
s3(8).panel.Layout.Row = [66 80];
s3(8).panel.Layout.Column = [72 98];

s3(8).grid = uigridlayout(s3(8).panel,[30 10]);
s3(8).label(5) = uilabel(s3(8).grid);
s3(8).label(5).Text = 'Done with band ID for entire core?';
s3(8).label(5).FontSize = 14;
s3(8).label(5).Layout.Column = [1 10];
s3(8).label(5).Layout.Row = [1 4];

s3(8).button(6) = uibutton(s3(8).grid, 'state');
s3(8).button(6).Text = 'Done IDing Bands';
s3(8).button(6).FontWeight = 'bold';
s3(8).button(6).BackgroundColor = [0.9294 0.4627 0.3804];
s3(8).button(6).Layout.Column = [1 10];
s3(8).button(6).Layout.Row = [5 10];

%% Initialize button call backs and screen variables:
UpdateCallbacks;

% wait for user interactions
waitfor(s3(8).button(6),'Value',true)

% save bandlocs to matfile if currently plotting
% if exist('hPolyline','var') || ishandle(hPolyline)
%     if slabNum >= 1 && slabNum <= 3
%         bandLocs{bandNum, slabNum} = [hPolyline.Position(:, 1), repmat(slabLoc(slabNum),height(hPolyline.Position),1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
%     elseif slabNum >= 4 && slabNum <= 6
%         bandLocs{bandNum, slabNum} = [repmat(slabLoc(slabNum), height(hPolyline.Position),1), hPolyline.Position(:, 1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
%     end
% end

% delete last rows if they are entirely empty
for row = size(bandLocs, 1):-1:1
    isEmptyRow = all(cellfun('isempty', bandLocs(row, :)));
    if isEmptyRow
        bandLocs(row, :) = [];
    else
        break;
    end
end

% repeat for stress bands
for row = size(stressBands, 1):-1:1
    isEmptyRow = all(cellfun('isempty', stressBands(row, :)));
    if isEmptyRow
        stressBands(row, :) = [];
    else
        break;
    end
end

% check if any cells are missing a value (this would be at the end)
anyEmpty = false;

for col = 1:size(bandLocs, 2)
    if isempty(bandLocs{end, col})
        anyEmpty = true;
        break;
    end
end

anyEmptySB = false;

for col = 1:size(stressBands, 2)
    if isempty(stressBands{end, col})
        anyEmptySB = true;
        break;
    end
end

if anyEmpty
    % stop break
    s3(8).button(6).Value = false;

    % set an alert
    uialert(UI,['You have not picked band ', int2str(size(bandLocs,1)), ' in all slabs. Finish picking the band or delete the band from all slabs before continuing to the next page.'],'Incomplete Band ID','Icon','error');
elseif anyEmptySB
    % stop break
    s3(8).button(6).Value = false;

    % set an alert
    uialert(UI,'You have not finished picking a stress band in all slabs. Finish picking the band or delete the band from all slabs before continuing to the next page.','Incomplete Band ID','Icon','error');
end


% edit the z-location of matfile to account for ReconDims.Z shift
%     for k = 1:size(bandLocs,1)
%         for j = 1:size(bandLocs,2)
%             format long
%             bandLocs{k,j}(:,3) = bandLocs{k,j}(:,3)-ReconDims.Z(1);
%         end
%     end

mfile.bandLocs = bandLocs;
save(mfile.Properties.Source, '-append','bandLocs');

% if resumed, continue to next scene:
clf(UI)
sn = 4;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateCallbacks
        % Panel 1 - Set Section Length and Overlap
        s3(1).button(1).ButtonPushedFcn = {@loadCoreSection};

        % Panel 2 - input plotting parameters
        s3(2).button(1).ButtonPushedFcn = {@ApplyPlottingParams};
        %s3(2).button(2).ButtonPushedFcn = {@SetPlottingParams};

        % Panel 5 - switch slab numbers
        s3(5).button(1).ButtonPushedFcn = {@SwitchSlabView};

        % Panel 6 - Band Editing
        s3(6).button(1).ButtonPushedFcn = {@DeleteSlabBand};
        s3(6).button(2).ButtonPushedFcn = {@DeleteEntireBand};
        s3(6).button(3).ButtonPushedFcn = {@InsertBand};

        % Panel 7 - Stress Band Identification
        s3(7).button(1).ButtonPushedFcn = {@DeleteStressBand};
        s3(7).button(2).ButtonPushedFcn = {@DeleteEntireStressBand};
        s3(7).button(3).ButtonPushedFcn = {@InsertStressBand};

    end

    function loadCoreSection(src,event)
        % disable button once it's pressed
        %s3(1).button(1).Enable = 'off';

        % parse user input
        SectionLength = s3(1).field(1).Value;
        SectionOverlap = s3(1).field(2).Value;

        % load section of core
        loadSection
        slabLoc = chooseSlabLocs;

        % change color of button and fields to indicate no more choice
        %src.BackgroundColor = '#b0b0b0';
        %src.Text = 'Done';
        %s3(1).field(1).Editable = false;
        %s3(1).field(2).Editable = false;
        %s3(1).field(1).BackgroundColor = '#d9d9d9';
        %s3(1).field(2).BackgroundColor = '#d9d9d9';
        plotSlabLoc;

        UpdateCallbacks;
    end

    function ApplyPlottingParams(src,event)
        s3(5).button(1).Enable = 'on';

        % parse user input
        contra(1) = s3(2).field(1).Value;
        contra(2) = s3(2).field(2).Value;
        slabThick = s3(2).field(4).Value;
        %slabLoc(slabNum) = s3(2).field(5).Value;
        % if slabNum < 4
        %     slabXloc = s3(2).field(5).Value;
        % else
        %     slabYloc = s3(2).field(6).Value;
        % end

        selectedOption = s3(2).field(3).Value;
        % Update the 'proj' variable based on the selected option
        switch selectedOption
            case 'max'
                proj = 'max';
            case 'min'
                proj = 'min';
            case 'mean'
                proj = 'mean';
        end

        % plot figure
        plotSlab
        plotSlabLoc

        if s3(5).cbx(1).Value == 1
            plotExistingBands
            plotExistingStressBands
            plotOtherSlabBands
        end

        % turn on buttons
        s3(6).button(1).Enable = 'on';
        s3(6).button(2).Enable = 'on';
        s3(6).button(3).Enable = 'on';

        s3(7).button(1).Enable = 'on';
        s3(7).button(2).Enable = 'on';
        s3(7).button(3).Enable = 'on';

        UpdateCallbacks;
    end

    function SwitchSlabView(src,event)
        % parse user input
        section = s3(5).field(1).Value;
        slabNum = s3(5).field(2).Value;

        % load that section
        loadSection

        % switch slab view
        plotSlabLoc
        plotSlab

        if s3(5).cbx(1).Value == 1
            plotExistingBands
            plotExistingStressBands
            plotOtherSlabBands
            plotOtherStressBands
        end

        UpdateCallbacks;
    end

    function DeleteSlabBand(src, event)
        % parse user input
        toBeDeleted = s3(6).field(1).Value;

        % prompt to double check if you want to delete the band from this
        % slab only
        msg = ['This will delete Band #', int2str(toBeDeleted), ' from the this slab only. Would you like to continue?'];
        title = 'Confirm band deletion';
        uiconfirm(UI,msg,title,'Options',{'Delete Band','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);

        function dlgcallback(src, event)
            if event.SelectedOption == "Delete Band"
                % delete from only this slab
                bandLocs{toBeDeleted,slabNum} = [];

                % move column up
                bandLocs(toBeDeleted:size(bandLocs,1)-1,slabNum) = bandLocs(toBeDeleted+1:size(bandLocs,1),slabNum);
                % replace last cell with empty matrix
                bandLocs{end,slabNum} = [];

                % replot slab
                plotSlab

                % plot existing bands
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands


                % save bandLocs to mfile
                mfile.bandLocs = bandLocs;
            end
        end

        UpdateCallbacks;
    end

    function DeleteEntireBand(src, event)
        % parse user input
        toBeDeleted = s3(6).field(1).Value;

        % prompt to double check if you want to delete entire band
        msg = ['This will delete Band #', int2str(toBeDeleted), ' from the entire core'];
        title = 'Confirm band deletion';
        uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);

        function dlgcallback(src, event)
            if event.SelectedOption == "Confirm"
                % delete from all slabs
                bandLocs(toBeDeleted,:) = [];

                % replot slab
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % save bandLocs to mfile
                mfile.bandLocs = bandLocs;

            end
        end

        UpdateCallbacks;
    end

    function InsertBand(src, event)
        % parse user input
        toBeInserted = s3(6).field(2).Value;

        % find if there are empty cells at the end of bandLocs
        idx = find(~cellfun(@isempty,bandLocs(:,slabNum)));

        % prompt to double check if you want to insert band
        if isempty(idx) && toBeInserted == 1
            msg = ['This will add a new band (Band #', int2str(toBeInserted),')'];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        elseif toBeInserted <= idx(end) %&& toBeInserted ~= 1
            msg = ['This will insert a new band between Band #', int2str(toBeInserted - 1), ' and current Band #', int2str(toBeInserted)];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        elseif toBeInserted > idx(end) || (toBeInserted == size(bandLocs,1) & isempty(bandLocs{end,slabNum}))
            msg = ['This will add a new band (Band #', int2str(toBeInserted),')'];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        end

        function dlgcallback(src, event)
            if event.SelectedOption == "Confirm"
                if toBeInserted <= size(bandLocs,1)
                    % insert new cell
                    bandLocs{end+1,slabNum} = []; % insert empty cell at end
                    bandLocs(toBeInserted+1 : end,slabNum) = bandLocs(toBeInserted : end-1,slabNum); % move cells down
                    bandLocs{toBeInserted,slabNum} = []; % make this cell empty
                elseif toBeInserted > size(bandLocs,1) || (toBeInserted == size(bandLocs,1) & isempty(bandLocs{end,slabNum}))
                    bandLocs{toBeInserted,slabNum} = []; % make this cell empty
                end
                % replot slab
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % User instruction message
                %uialert(UI,'Pick band, hit ENTER, and press Save Band (blue button)','Replot band','Icon','info');
                s3(6).button(4).Enable = 'on';
                s3(6).button(4).BackgroundColor = '#8ac9f2';

                % Manual Band ID
                userBand;

                % wait for user to hit enter and then button
                waitfor(s3(6).button(4),'Value',1)

                % save bands to bandLocs
                if slabNum >= 1 && slabNum <= 3
                    bandLocs{toBeInserted, slabNum} = [hPolyline.Position(:, 1), repmat(slabLoc(slabNum), height(hPolyline.Position),1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
                elseif slabNum >= 4 && slabNum <= 6
                    bandLocs{toBeInserted, slabNum} = [repmat(slabLoc(slabNum), height(hPolyline.Position),1), hPolyline.Position(:, 1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
                end

                % delete polyline
                delete(hPolyline);

                % replot slab and existing bands
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % Reset button
                s3(6).button(4).Enable = 'off';
                s3(6).button(4).BackgroundColor = [0.96 0.96 0.96];

                % delete last rows if they are entirely empty
                for row = size(bandLocs, 1):-1:1
                    isEmptyRow = all(cellfun('isempty', bandLocs(row, :)));
                    if isEmptyRow
                        bandLocs(row, :) = [];
                    else
                        break;
                    end
                end

                % save bandLocs to mfile
                mfile.bandLocs = bandLocs;

                % NEW - update field to show next band
                %s3(6).field(2).Value = toBeInserted + 1;
                set(s3(6).field(2), 'Value', toBeInserted + 1);
                drawnow;


            end
        end


        UpdateCallbacks;
    end

%
    function DeleteStressBand(src, event)
        % parse user input
        toBeDeletedSB = s3(7).field(1).Value;

        % prompt to double check if you want to delete the band from this
        % slab only
        msg = ['This will delete Stress Band #', int2str(toBeDeletedSB), ' from the this slab only. Would you like to continue?'];
        title = 'Confirm band deletion';
        uiconfirm(UI,msg,title,'Options',{'Delete Stress Band','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);

        function dlgcallback(src, event)
            if event.SelectedOption == "Delete Stress Band"
                % delete from only this slab
                stressBands{toBeDeletedSB,slabNum} = [];

                % move column up
                stressBands(toBeDeletedSB:size(stressBands,1)-1,slabNum) = stressBands(toBeDeletedSB+1:size(stressBands,1),slabNum);
                % replace last cell with empty matrix
                stressBands{end,slabNum} = [];

                % replot slab
                plotSlab

                % plot existing bands
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % save bandLocs to mfile
                mfile.stressBands = stressBands;
            end
        end

        UpdateCallbacks;
    end

    function DeleteEntireStressBand(src, event)
        % parse user input
        toBeDeletedSB = s3(7).field(1).Value;

        % prompt to double check if you want to delete entire band
        msg = ['This will delete Stress Band #', int2str(toBeDeletedSB), ' from the entire core'];
        title = 'Confirm stress band deletion';
        uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
            'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);

        function dlgcallback(src, event)
            if event.SelectedOption == "Confirm"
                % delete from all slabs
                stressBands(toBeDeletedSB,:) = [];

                % replot slab
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % save stressBands to mfile
                mfile.stressBands = stressBands;

            end
        end

        UpdateCallbacks;
    end

    function InsertStressBand(src, event)
        % parse user input
        toBeInsertedSB = s3(7).field(2).Value;

        % find if there are empty cells at the end of stressBands
        idx = find(~cellfun(@isempty,stressBands(:,slabNum)));

        % prompt to double check if you want to insert band
        if isempty(idx) && toBeInsertedSB == 1
            msg = ['This will add a new stress band (Band #', int2str(toBeInsertedSB),')'];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        elseif toBeInsertedSB <= idx(end) && toBeInsertedSB ~= 1
            msg = ['This will insert a new stress band between Band #', int2str(toBeInsertedSB - 1), ' and current Band #', int2str(toBeInsertedSB)];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        elseif toBeInsertedSB > idx(end) || (toBeInsertedSB == size(stressBands,1) & isempty(stressBands{end,slabNum}))
            msg = ['This will add a new stress band (Band #', int2str(toBeInsertedSB),')'];
            title = 'Confirm band insertion';
            uiconfirm(UI,msg,title,'Options',{'Confirm','Cancel'}, ...
                'DefaultOption',1,'CancelOption',2,'CloseFcn',@dlgcallback);
        end

        function dlgcallback(src, event)
            if event.SelectedOption == "Confirm"
                if toBeInsertedSB <= size(stressBands,1)
                    % insert new cell
                    stressBands{end+1,slabNum} = []; % insert empty cell at end
                    stressBands(toBeInsertedSB+1 : end,slabNum) = stressBands(toBeInsertedSB : end-1,slabNum); % move cells down
                    stressBands{toBeInsertedSB,slabNum} = []; % make this cell empty
                elseif toBeInsertedSB > size(stressBands,1) || (toBeInsertedSB == size(stressBands,1) & isempty(stressBands{end,slabNum}))
                    stressBands{toBeInsertedSB,slabNum} = []; % make this cell empty
                end
                % replot slab
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % User instruction message
                %uialert(UI,'Pick band, hit ENTER, and press Save Band (blue button)','Replot band','Icon','info');
                s3(7).button(4).Enable = 'on';
                s3(7).button(4).BackgroundColor = '#8ac9f2';

                % Manual Band ID
                userBand;

                % wait for user to hit enter and then button
                waitfor(s3(7).button(4),'Value',1)

                % save bands to stressBands
                if slabNum >= 1 && slabNum <= 3
                    stressBands{toBeInsertedSB, slabNum} = [hPolyline.Position(:, 1), repmat(slabLoc(slabNum), height(hPolyline.Position),1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
                elseif slabNum >= 4 && slabNum <= 6
                    stressBands{toBeInsertedSB, slabNum} = [repmat(slabLoc(slabNum), height(hPolyline.Position),1), hPolyline.Position(:, 1), (hPolyline.Position(:, 2)+SectionRange(1)-1)];
                end

                % delete polyline
                delete(hPolyline);

                % replot slab and existing bands
                plotSlab
                plotExistingBands
                plotExistingStressBands
                plotOtherSlabBands
                plotOtherStressBands

                % Reset button
                s3(7).button(4).Enable = 'off';
                s3(7).button(4).BackgroundColor = [0.96 0.96 0.96];

                % delete last rows if they are entirely empty
                for row = size(stressBands, 1):-1:1
                    isEmptyRow = all(cellfun('isempty', stressBands(row, :)));
                    if isEmptyRow
                        stressBands(row, :) = [];
                    else
                        break;
                    end
                end

                % save stressBands to mfile
                mfile.stressBands = stressBands;


            end
        end


        UpdateCallbacks;
    end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% BAND-ID FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function userBand
        hPolyline = drawpolyline(s3(4).axis(1), 'Color', 'r','InteractionsAllowed','none');
    end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% OTHER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loads in specified section of matfile core
    function loadSection

        %loads CT images and assembles into 3D matrix X
        metadata = mfile.metadata;
        numLayers = length(ReconDims.Z);

        % Set image pixel spacing (mm/vox)
        hpxS = metadata.PixelSpacing;
        pxS = metadata.PixelZSpacing;

        %Clip ids to section, % overlap
        NumVoxels = round(SectionLength/(0.1*pxS)); %vox/section
        SectionTot = ceil(numLayers/NumVoxels);

        %Define overlap as fraction (comes in as percentage)
        denom = round(100/SectionOverlap);

        if section==1
            OverlapLayers = 0;
            SectionRange = (NumVoxels*(section-1)+ReconDims.Z(1)) : (NumVoxels*(section)+ReconDims.Z(1)-1);
        elseif section==SectionTot
            OverlapLayers = floor(NumVoxels/denom);
            SectionRange = (NumVoxels*(section-1)+ReconDims.Z(1)-OverlapLayers):ReconDims.Z(end);
        else
            OverlapLayers = floor(NumVoxels/denom);
            SectionRange = (NumVoxels*(section-1)+ReconDims.Z(1)-OverlapLayers) : NumVoxels*(section)+ReconDims.Z(1)-1;
        end

        %Step 5: Read data from the section and rescale slope
        ScanXn = double(mfile.Scan(ReconDims.X,ReconDims.Y,SectionRange))*metadata.RescaleSlope + metadata.RescaleIntercept;

    end

% Selects the 6 slab locations
    function [slabLoc] = chooseSlabLocs
        % choose core filter
        [h2] = chooseCoreFilter(hpxS);

        % set up slab positions: sample core for general location within image
        samp = floor(median(ReconDims.Z)); % sample middle of ReconDims.Z
        %Xsamp = double(mfile.Scan(:,:,samp)).*metadata.RescaleSlope + metadata.RescaleIntercept;
        Xsamp = double(mfile.Scan(ReconDims.X,ReconDims.Y,samp)).*metadata.RescaleSlope + metadata.RescaleIntercept;
        filteredXcore(:,:) = imsharpen(imfilter(Xsamp, h2, 'replicate'));


        % determine where coral is in the image
        level = graythresh(filteredXcore);
        coralSamp = imbinarize(filteredXcore,level);
        coralSamp = bwareaopen(coralSamp, 50);

        [r,c] = find(coralSamp);

        % select top/bottom/left/rightmost points of the core in the sampled
        % slice
        [~,loc] = min(r);
        topMost = [c(loc),r(loc)];
        [~,loc] = max(r);
        bottomMost = [c(loc),r(loc)];
        [~,loc] = max(c);
        rightMost = [c(loc),r(loc)];
        [~,loc] = min(c);
        leftMost = [c(loc),r(loc)];

        center = [round((rightMost(1)+leftMost(1))/2),round((topMost(2)+bottomMost(2))/2)];

        % Select Location of Slabs
        slabLoc_temp(1:3) = [round((center(2)+topMost(2))/2) center(2) round((center(2)+bottomMost(2))/2)]; % horizontal cuts
        slabLoc_temp(4:6) = [round((center(1)+leftMost(1))/2) center(1) round((center(1)+rightMost(1))/2)]; % vertical cuts

        ords = [2 1 3 5 4 6]; % order in which slabs will appear (start with middle slab first)
        slabLoc = slabLoc_temp(ords);
    end

% Draws slab based on slab number and location
    function slabDraw3 = drawSlab
        thick = round(slabThick/hpxS)/2; % slab thickness in pixels!!
        thick = thick(1); % correct for scanned files
        if slabNum<4
            slabDraw3 = zeros(size(ScanXn,1),1,size(ScanXn,3));
            if strcmp(proj,'min')
                slabDraw3(:,:,1:size(ScanXn,3))  = min(ScanXn(:,slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:),[],2);
            elseif strcmp(proj,'mean')
                slabDraw3(:,:,1:size(ScanXn,3))  = mean(ScanXn(:,slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:),2);
            elseif strcmp(proj,'max')
                slabDraw3(:,:,1:size(ScanXn,3))  = max(ScanXn(:,slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:),[],2);
            end
            slabDraw3 = permute(slabDraw3,[3,1,2]);
        else % if i>=4
            slabDraw3 = zeros(size(ScanXn,2),1,size(ScanXn,3));
            if strcmp(proj,'min')
                slabDraw3(:,:,1:size(ScanXn,3))  = min(ScanXn(slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:,:),[],1);
            elseif strcmp(proj,'mean')
                slabDraw3(:,:,1:size(ScanXn,3))  = mean(ScanXn(slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:,:),1);
            elseif strcmp(proj,'max')
                slabDraw3(:,:,1:size(ScanXn,3))  = max(ScanXn(slabLoc(slabNum)-thick:slabLoc(slabNum)+thick,:,:),[],1);
            end
            slabDraw3 = permute(slabDraw3,[3,1,2]);
        end
    end

% Plots selected slab
    function plotSlab
        % set existing variables
        slabDraw3 = drawSlab;
        mtd = mfile.metadata;
        pxS = mtd.PixelZSpacing;

        % Calculate the distance in centimeters for 10 equally spaced labels
        numLabels = 10;
        ySpacingPixels = round(length(SectionRange) / (numLabels - 1));

        % Create y-axis tick positions and labels
        yTickPositions = 0:ySpacingPixels:length(SectionRange);
        yTickLabels = sprintf('%.1f\n', (yTickPositions+(SectionRange(1)-1)) * pxS / 10);

        % Clear the axis before updating
        if isfield(s3(4), 'axis') && isvalid(s3(4).axis(1))
            cla(s3(4).axis(1), 'reset');
        else
            s3(4).axis(1) = axes(s3(4).panel);
        end

        s3(4).axis.NextPlot = 'add';
        fig1 = imagesc(s3(4).axis(1), [1, size(ScanXn, 2)], [1 length(SectionRange)], slabDraw3);
        axis(s3(4).axis(1), 'ij');
        colormap(s3(4).axis(1), 'bone');
        title(s3(4).axis(1),['Section ',num2str(section),' of ',num2str(SectionTot),', slide ',num2str(slabNum),' of 6']);
        set(s3(4).axis(1), 'CLim', contra); % set color limits
        set(s3(4).axis(1), 'YTick', yTickPositions);
        set(s3(4).axis(1), 'YTickLabel', yTickLabels);
        ylabel(s3(4).axis(1), 'Distance Downcore (cm)', 'FontWeight', 'bold', 'FontSize', 13);
        set(s3(4).axis(1), 'FontWeight', 'bold', 'FontSize', 13);
        s3(4).axis(1).Position = [0.01, 0.01, 0.9, 0.9];
        axis(s3(4).axis(1), 'image');
        % set axis properties
        s3(4).axis(1).XTick = []; s3(4).axis(1).XLabel = [];
        s3(4).axis(1).DataAspectRatio = [1 1 1];

        UpdateCallbacks;
    end

% Plots location of slab in top-down cross-section
    function plotSlabLoc
        s3(3).axes = axes(s3(3).panel);
        h=figure;
        set(h,'visible','off');
        % imshow(ScanXn(:,:,ceil(size(ScanXn,3)/2)), 'Parent', s3(3).axes, 'InitialMagnification', 'fit');
        % hold on;
        imagesc(s3(3).axes, ScanXn(:,:,ceil(size(ScanXn,3)/2)));
        hold(s3(3).axes, 'on')
        colormap(s3(3).axes, 'bone');
        s3(3).axes.YDir = 'normal'; s3(3).axes.XDir = 'normal';
        axis(s3(3).axes, 'image'); % make aspect ration 1:1
        s3(3).axes.XTick = []; s3(3).axes.YTick = [];
        line(s3(3).axes, [1, size(ScanXn,2)], [middle(1), middle(1)], 'color', 'white', 'LineWidth', 0.7); hold on
        line(s3(3).axes, [middle(2), middle(2)], [1, size(ScanXn,1)], 'color', 'white', 'LineWidth', 0.7); hold on

        % line(s3(3).axes, [middle(1), middle(1)], [1, size(ScanXn,2)], 'color', 'white', 'LineWidth', 0.7); hold on
        % line(s3(3).axes, [1, size(ScanXn,1)], [middle(2), middle(2)], 'color', 'white', 'LineWidth', 0.7); hold on

        if slabNum < 4
            line(s3(3).axes, [1, size(ScanXn,2)], [slabLoc(slabNum), slabLoc(slabNum)], 'color', '#eb7f0c', 'LineWidth', 3);
        else
            line(s3(3).axes, [slabLoc(slabNum), slabLoc(slabNum)], [1, size(ScanXn,1)], 'color', '#FFA500', 'LineWidth', 3);
        end

        % if slabNum < 4
        %     line(s3(3).axes, [slabLoc(slabNum), slabLoc(slabNum)], [1, size(ScanXn,2)], 'color', '#eb7f0c', 'LineWidth', 3);
        % else
        %     line(s3(3).axes, [1, size(ScanXn,1)], [slabLoc(slabNum), slabLoc(slabNum)], 'color', '#FFA500', 'LineWidth', 3);
        % end

        axis(s3(3).axes, 'image'); % Set aspect ratio to [1 1 1]
        axis(s3(3).axes, 'off');   % Turn off axis ticks and labels
    end

% Plots existing bands
    function plotExistingBands
        idx = find(~cellfun(@isempty,bandLocs(:,slabNum)));
        for i = 1:length(idx) % old: i = idx(1):idx(end)
            if slabNum >= 1 && slabNum <= 3 && all(bandLocs{idx(i),slabNum}(1:end,3) > SectionRange(1)) && all(bandLocs{idx(i),slabNum}(1:end,3) <= SectionRange(end))
                plot(s3(4).axis(1), bandLocs{idx(i),slabNum}(:,1),bandLocs{idx(i),slabNum}(:,3)-(SectionRange(1)-1),'-om','LineWidth',2); hold on
                text(s3(4).axis(1), bandLocs{idx(i),slabNum}(1,1)-15, bandLocs{idx(i),slabNum}(1,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',12,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'magenta'); hold on
            elseif slabNum >= 4 && slabNum <= 6 && all(bandLocs{idx(i),slabNum}(1:end,3) > SectionRange(1)) && all(bandLocs{idx(i),slabNum}(1:end,3) <= SectionRange(end))
                plot(s3(4).axis(1), bandLocs{idx(i),slabNum}(:,2),bandLocs{idx(i),slabNum}(:,3)-(SectionRange(1)-1),'-om','LineWidth',2); hold on
                text(s3(4).axis(1), bandLocs{idx(i),slabNum}(1,2)-15, bandLocs{idx(i),slabNum}(1,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',12,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'magenta'); hold on
            end
        end
    end

% Plots existing stress bands
    function plotExistingStressBands
        idx = find(~cellfun(@isempty,stressBands(:,slabNum)));
        for i = 1:length(idx) % old: i = idx(1):idx(end)
            if slabNum >= 1 && slabNum <= 3 && all(stressBands{idx(i),slabNum}(1:end,3) > SectionRange(1)) && all(stressBands{idx(i),slabNum}(1:end,3) <= SectionRange(end))
                plot(s3(4).axis(1), stressBands{idx(i),slabNum}(:,1),stressBands{idx(i),slabNum}(:,3)-(SectionRange(1)-1),'-*c','LineWidth',2.5); hold on
                text(s3(4).axis(1), stressBands{idx(i),slabNum}(1,1)-15, stressBands{idx(i),slabNum}(1,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',12,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'cyan'); hold on
            elseif slabNum >= 4 && slabNum <= 6 && all(stressBands{idx(i),slabNum}(1:end,3) > SectionRange(1)) && all(stressBands{idx(i),slabNum}(1:end,3) <= SectionRange(end))
                plot(s3(4).axis(1), stressBands{idx(i),slabNum}(:,2),stressBands{idx(i),slabNum}(:,3)-(SectionRange(1)-1),'-*c','LineWidth',2.5); hold on
                text(s3(4).axis(1), stressBands{idx(i),slabNum}(1,2)-15, stressBands{idx(i),slabNum}(1,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',12,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'cyan'); hold on
            end
        end
    end

% Plots locations of other slab bands
    % function plotOtherSlabBands
    %     allnum = [1:6];
    %     otherSlabs = allnum(allnum ~= slabNum);
    %     for j = 1:length(otherSlabs)
    %         idx = find(~cellfun(@isempty,bandLocs(:,otherSlabs(j))));
    %         colorOpts = ['w';'r';'c';'g';'y';'c'];
    %         %staggerOpts = [-1;0;1;-1;0;1];
    %         for i = 1:length(idx) % old: i = idx(1):idx(end)
    %             if otherSlabs(j) >= 1 && otherSlabs(j) <= 3
    %                 text(s3(4).axis(1), bandLocs{idx(i),otherSlabs(j)}(end,1)+6, bandLocs{idx(i),otherSlabs(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', colorOpts(j)); hold on
    %             elseif otherSlabs(j) >= 4 && otherSlabs(j) <= 6
    %                 text(s3(4).axis(1), bandLocs{idx(i),otherSlabs(j)}(end,2)+6, bandLocs{idx(i),otherSlabs(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', colorOpts(j)); hold on
    %             end
    %         end
    %     end
    % end


    function plotOtherSlabBands
        allnum = [1:6];

        % Identify only intersecting slabs
        if slabNum >= 1 && slabNum <= 3
            otherSlabs = 4:6; % Intersecting slabs hold X fixed
        else
            otherSlabs = 1:3; % Intersecting slabs hold Y fixed
        end

        sameSide = allnum(~ismember(allnum,[slabNum, otherSlabs]));

        colorOpts = ['w'; 'r'; 'c'; 'g'; 'y'; 'm']; % Colors for different slabs

        hold(s3(4).axis(1), 'on'); % Hold plot for multiple points

        % plot righttmost points in sameSide
        for j = 1:length(sameSide)
            idx = find(~cellfun(@isempty,bandLocs(:,sameSide(j))));
            colorOpts = ['w';'r';'c';'g';'y';'m'];
          
            for i = 1:length(idx) % old: i = idx(1):idx(end)
                if sameSide(j) >= 1 && sameSide(j) <= 3 % && all(bandLocs{idx(1),sameSide(j)}(:,3)>SectionRange(1)) && all(bandLocs{idx(1),sameSide(j)}(:,3)<SectionRange(end))
                    text(s3(4).axis(1), bandLocs{idx(i),sameSide(j)}(end,1)+6, bandLocs{idx(i),sameSide(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', colorOpts(sameSide(j))); hold on
                elseif sameSide(j) >= 4 && sameSide(j) <= 6 % && all(bandLocs{idx(1),sameSide(j)}(:,3)>SectionRange(1)) && all(bandLocs{idx(1),sameSide(j)}(:,3)<SectionRange(end))
                    text(s3(4).axis(1), bandLocs{idx(i),sameSide(j)}(end,2)+6, bandLocs{idx(i),sameSide(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', colorOpts(sameSide(j))); hold on
                end
            end
        end

        % plot intersecting points in OtherSlabs
        for j = 1:length(otherSlabs)
            slabCheck = otherSlabs(j);
            idx = find(~cellfun(@isempty, bandLocs(:, slabCheck))); % Find valid bands

            for i = 1:length(idx)
                % Extract band data *only when needed*
                bandPoints = bandLocs{idx(i), slabCheck};

                if isempty(bandPoints) || size(bandPoints, 1) < 2
                    continue; % Skip if not enough points for interpolation
                end

                % Interpolation logic
                if slabNum >= 1 && slabNum <= 3 % Viewing slabs 1-3, intersecting with 4-6
                    fixedX = slabLoc(slabNum); % X location of the current slab

                    if min(bandPoints(:,2)) <= fixedX && max(bandPoints(:,2)) >= fixedX && all(bandPoints(:,3) <= SectionRange(end)) && all(bandPoints(:,3) >= SectionRange(1))
                        zInterp = interp1(bandPoints(:,2), bandPoints(:,3), fixedX, 'linear', 'extrap');
                        %yInterp = interp1(bandPoints(:,1), bandPoints(:,2), fixedX, 'linear', 'extrap');
                        scatter(s3(4).axis(1), bandPoints(1,1), zInterp - (SectionRange(1) - 1), ...
                            70, 'hexagram', 'MarkerFaceColor', colorOpts(slabCheck), 'MarkerEdgeColor', 'k');
                        text(s3(4).axis(1), bandPoints(1,1)+10, zInterp - (SectionRange(1) - 1)-10, ...
                            int2str(idx(i)), 'FontSize', 10, 'Color', colorOpts(slabCheck), ...
                            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                    end

                elseif slabNum >= 4 && slabNum <= 6 % Viewing slabs 4-6, intersecting with 1-3
                    fixedY = slabLoc(slabNum); % Y location of the current slab

                    if min(bandPoints(:,1)) <= fixedY && max(bandPoints(:,1)) >= fixedY && all(bandPoints(:,3) <= SectionRange(end)) && all(bandPoints(:,3) >= SectionRange(1))
                        zInterp = interp1(bandPoints(:,1), bandPoints(:,3), fixedY, 'linear', 'extrap');
                        scatter(s3(4).axis(1), bandPoints(1,2), zInterp - (SectionRange(1) - 1), ...
                            70, 'hexagram', 'MarkerFaceColor', colorOpts(slabCheck), 'MarkerEdgeColor', 'k');
                        text(s3(4).axis(1), bandPoints(1,2)+10, zInterp - (SectionRange(1) - 1)-10, ...
                            int2str(idx(i)), 'FontSize', 10, 'Color', colorOpts(slabCheck), ...
                            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                    end
                end
            end
        end

        hold(s3(4).axis(1), 'off'); % Release hold
    end


% % Plots locations of other stress bands
%     function plotOtherStressBands
%         allnum = [1:6];
%         otherSlabs = allnum(allnum ~= slabNum);
%         for j = 1:length(otherSlabs)
%             idx = find(~cellfun(@isempty,stressBands(:,otherSlabs(j))));
%             for i = 1:length(idx) % old: i = idx(1):idx(end)
%                 if otherSlabs(j) >= 1 && otherSlabs(j) <= 3 && all(stressBands{idx(1),otherSlabs(j)}(:,3)>SectionRange(1)) % && all(stressBands{idx(1),otherSlabs(j)}(:,3)<SectionRange(end))
%                     text(s3(4).axis(1), stressBands{idx(i),otherSlabs(j)}(1,1)-6, stressBands{idx(i),otherSlabs(j)}(1,3)-(SectionRange(1)-1),['*', int2str(idx(i)),'*'],'FontSize',12, 'HorizontalAlignment', 'left', 'Color', 'cyan'); hold on
%                 elseif otherSlabs(j) >= 4 && otherSlabs(j) <= 6 && all(stressBands{idx(1),otherSlabs(j)}(:,3)>SectionRange(1)) % && all(stressBands{idx(1),otherSlabs(j)}(:,3)<SectionRange(end))
%                     text(s3(4).axis(1), stressBands{idx(i),otherSlabs(j)}(1,2)-6, stressBands{idx(i),otherSlabs(j)}(1,3)-(SectionRange(1)-1),['*', int2str(idx(i)),'*'],'FontSize',12, 'HorizontalAlignment', 'left', 'Color', 'cyan'); hold on
%                 end
%             end
%         end
%     end

    % Plots locations of other stress bands
    function plotOtherStressBands
        allnum = [1:6];

        % Identify only intersecting slabs
        if slabNum >= 1 && slabNum <= 3
            otherSlabs = 4:6; % Intersecting slabs hold X fixed
        else
            otherSlabs = 1:3; % Intersecting slabs hold Y fixed
        end

        sameSide = allnum(~ismember(allnum,[slabNum, otherSlabs]));
        hold(s3(4).axis(1), 'on'); % Hold plot for multiple points

        % plot righttmost points in sameSide
        for j = 1:length(sameSide)
            idx = find(~cellfun(@isempty,stressBands(:,sameSide(j))));
          
            for i = 1:length(idx) % old: i = idx(1):idx(end)
                if sameSide(j) >= 1 && sameSide(j) <= 3 % && all(stressBands{idx(1),sameSide(j)}(:,3)>SectionRange(1)) && all(stressBands{idx(1),sameSide(j)}(:,3)<SectionRange(end))
                    text(s3(4).axis(1), stressBands{idx(i),sameSide(j)}(end,1)+6, stressBands{idx(i),sameSide(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', 'c'); hold on
                elseif sameSide(j) >= 4 && sameSide(j) <= 6 % && all(stressBands{idx(1),sameSide(j)}(:,3)>SectionRange(1)) && all(stressBands{idx(1),sameSide(j)}(:,3)<SectionRange(end))
                    text(s3(4).axis(1), stressBands{idx(i),sameSide(j)}(end,2)+6, stressBands{idx(i),sameSide(j)}(end,3)-(SectionRange(1)-1),int2str(idx(i)),'FontSize',10, 'HorizontalAlignment', 'left', 'Color', 'c'); hold on
                end
            end
        end

        % plot intersecting points in OtherSlabs
        for j = 1:length(otherSlabs)
            slabCheck = otherSlabs(j);
            idx = find(~cellfun(@isempty, stressBands(:, slabCheck))); % Find valid bands

            for i = 1:length(idx)
                % Extract band data *only when needed*
                bandPoints = stressBands{idx(i), slabCheck};

                if isempty(bandPoints) || size(bandPoints, 1) < 2
                    continue; % Skip if not enough points for interpolation
                end

                % Interpolation logic
                if slabNum >= 1 && slabNum <= 3 % Viewing slabs 1-3, intersecting with 4-6
                    fixedX = slabLoc(slabNum); % X location of the current slab

                    if min(bandPoints(:,2)) <= fixedX && max(bandPoints(:,2)) >= fixedX && all(bandPoints(:,3) <= SectionRange(end)) && all(bandPoints(:,3) >= SectionRange(1))
                        zInterp = interp1(bandPoints(:,2), bandPoints(:,3), fixedX, 'linear', 'extrap');
                        %yInterp = interp1(bandPoints(:,1), bandPoints(:,2), fixedX, 'linear', 'extrap');
                        scatter(s3(4).axis(1), bandPoints(1,1), zInterp - (SectionRange(1) - 1), ...
                            70, 'diamond', 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'b');
                        text(s3(4).axis(1), bandPoints(1,1)+10, zInterp - (SectionRange(1) - 1)-10, ...
                            int2str(idx(i)), 'FontSize', 10, 'Color', 'b', ...
                            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                    end

                elseif slabNum >= 4 && slabNum <= 6 % Viewing slabs 4-6, intersecting with 1-3
                    fixedY = slabLoc(slabNum); % Y location of the current slab

                    if min(bandPoints(:,1)) <= fixedY && max(bandPoints(:,1)) >= fixedY && all(bandPoints(:,3) <= SectionRange(end)) && all(bandPoints(:,3) >= SectionRange(1))
                        zInterp = interp1(bandPoints(:,1), bandPoints(:,3), fixedY, 'linear', 'extrap');
                        scatter(s3(4).axis(1), bandPoints(1,2), zInterp - (SectionRange(1) - 1), ...
                            70, 'diamond', 'MarkerFaceColor', 'c', 'MarkerEdgeColor', 'b');
                        text(s3(4).axis(1), bandPoints(1,2)+10, zInterp - (SectionRange(1) - 1)-10, ...
                            int2str(idx(i)), 'FontSize', 10, 'Color', 'b', ...
                            'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                    end
                end
            end
        end

        hold(s3(4).axis(1), 'off'); % Release hold
    end


% Chooses core filter
    function [h2] = chooseCoreFilter(hpxS)
        %   Designed for Majuro Porites scans
        %   At the moment, filter is based on scan resolution (hpxS)
        %   ** add options for different species when you get there **

        if hpxS < 0.1 % < 100 microns (ex. 96 um)
            h2 = fspecial('disk',3);
        end

        if hpxS > 0.1 % > 100 microns (ex. 184.4 um)
            h2 = fspecial('gaussian',2,15);
        end

    end
end
