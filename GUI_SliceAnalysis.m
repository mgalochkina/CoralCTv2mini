function [s7,sn] = GUI_SliceAnalysis(UI,uigrid,mfile)
% created 1/18/25 - Mariya
% 4/13/25 - changed lowpass filtering to gaussian filtering
% edited 4/23/25 - fixed bandCrossing/ReconDims issue
% edited 4/28/25 - added a "done computing slices" window
% edited 5/2/25 - fixed z-score cropping issue
% edited 5/5/25 - changed around xrange and yrange to deal with slice
% last edited 10/5/25 - for mini version

% Screen 7 - Estimates Stress Band year from user-selected stress bands
% selected bands

%% Set default parameters
PixelDistance = 5; % mm distance from point (default is 5 pix)
% for loading data
metadata = mfile.metadata;
ReconDims = mfile.ReconDims;
Xdims = [size(ReconDims.X,2), size(ReconDims.Y,2), size(ReconDims.Z,2)];
%hpxS = metadata.PixelSpacing; % mm/vox

% for picking out what is and isn't coral
CoralPixelDistribution = mfile.CoralPixelDistribution;
densitySample = mfile.densitySample;
DensityConversion = mfile.DensityConversion;
DCSlope = DensityConversion.RegressionParameters(2,1); DCIntercept = DensityConversion.RegressionParameters(1,1);

%Read data from middle of core
ScanXn = double(mfile.Scan(ReconDims.X,ReconDims.Y,ceil(length(ReconDims.Z)/2)))*metadata.RescaleSlope + metadata.RescaleIntercept;

slices = []; sliceCoords = [];
sliceNum = 1;
densMin = []; densMax = []; depthMin = []; depthMax = [];
collectionYear = 2023; editBandYear = 1;
AnnualBandDepth = [];
sbThresh = 2;
lowpassDens = []; zScore = []; unfiltzScore = []; depthAx = [];
est_annualBandGrowth = []; Fc = [];
sliceZscore = cell(1,9); sliceStressBand = cell(1,9);

% initialize summary table
colNames = {'Band', 'Depth','Est_Year','Likelihood'};
data = {[],[],[],[]};
summaryTable = cell2table(data,'VariableNames',colNames);
BlueLine = []; RedLine = [];
SBsummarytable = [];
SBstats = [];

% load in bandLocs
if isprop(mfile, 'bandLocs')
    bandLocs = mfile.bandLocs;
    %totBand = height(bandLocs);
    %band = cell(totBand,1);
    bandSurf = [];
    bandCross = [];
else
    message = ["No saved user bands detected","Consider picking bands before proceeding"];
    uialert(UI,message,"Warning","Icon","Warning")
end

% load in stress band locs
if isprop(mfile, 'stressBands')
    stressBands = mfile.stressBands;
    %totSB = height(stressBands);
    %sb = cell(totSB,1);
    sbSurf = [];
    sbCross = [];
end



%% Panel 1: Select Probe Diameter
s7(1).panel = uipanel(uigrid,'Title','1. Select Probe Diameter (in pixels)');
s7(1).panel.Layout.Row = [3 10];
s7(1).panel.Layout.Column = [3 22];

% Select probe diameter
s7(1).grid = uigridlayout(s7(1).panel,[25 25]);
s7(1).label(1) = uilabel(s7(1).grid);
s7(1).label(1).Text = 'Diameter (pix)';
s7(1).label(1).FontSize = 13;
s7(1).label(1).Layout.Column = [1 11];
s7(1).label(1).Layout.Row = [1 4];

% set probe diameter
s7(1).field(1) = uieditfield(s7(1).grid,"numeric","Limits",[3 25],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",PixelDistance);
s7(1).field(1).Layout.Column = [12 16];
s7(1).field(1).Layout.Row = [1 4];

% Apply probe diameter to plotting
s7(1).button(1) = uibutton(s7(1).grid);
s7(1).button(1).Text = 'Preview';
s7(1).button(1).Layout.Column = [19 25];
s7(1).button(1).Layout.Row = [1 4];
s7(1).button(1).FontSize = 13;

% Sample core probe


%% Panel 2: Plot Probe diameter
s7(2).panel = uipanel(uigrid,'Title','2. View Probe Diameter');
s7(2).panel.Layout.Row = [11 41];
s7(2).panel.Layout.Column = [3 22];
s7(2).grid = uigridlayout(s7(2).panel,[30 32]);
s7(2).axes = uiaxes(s7(2).grid);
s7(2).axes.Layout.Row = [1 24];  % Make it span all rows
s7(2).axes.Layout.Column = [1 26];  % Make it span all columns

s7(2).button(1) = uibutton(s7(2).grid);
s7(2).button(1).Enable = 'on';
s7(2).button(1).Text = 'Calculate density slices';
s7(2).button(1).Layout.Column = [2 28];
s7(2).button(1).Layout.Row = [24 27];
s7(2).button(1).FontSize = 13;

%% Panel 3: Examine Slices
s7(3).panel = uipanel(uigrid,'Title','3. Examine Slices');
s7(3).panel.Layout.Row = [42 80];
s7(3).panel.Layout.Column = [3 22];
s7(3).grid = uigridlayout(s7(3).panel,[30 50]);
% s7(3).axis(1) = axes(s7(3).grid);

% set which slice to look at
s7(3).label(1) = uilabel(s7(3).grid);
s7(3).label(1).Text = 'Select slice';
s7(3).label(1).FontWeight = 'bold';
s7(3).label(1).FontSize = 12;
s7(3).label(1).Layout.Column = [1 8];
s7(3).label(1).Layout.Row = [1 3];

s7(3).dropdown(1) = uidropdown(s7(3).grid);
s7(3).dropdown(1).Items = [{'Slice 1','Slice 2','Slice 3', ...
    'Slice 4','Slice 5','Slice 6' ...
    ,'Slice 7','Slice 8','Slice 9'}];
s7(3).dropdown(1).Layout.Column = [9 16];
s7(3).dropdown(1).Layout.Row = [1 3];

s7(3).button(1) = uibutton(s7(3).grid);
s7(3).button(1).Enable = 'on';
s7(3).button(1).Text = 'Plot slice';
s7(3).button(1).Layout.Column = [17 28];
s7(3).button(1).Layout.Row = [1 5];
s7(3).button(1).FontSize = 13;

% plot location of user-selected bands
s7(3).cbx(1) = uicheckbox(s7(3).grid,"Text","Plot user bands");
s7(3).cbx(1).Layout.Column = [1 15];
s7(3).cbx(1).Layout.Row = [3 6];

s7(3).line(1) = uilabel(s7(3).grid);
s7(3).line(1).Text = "____________________________________"; % Fake line
s7(3).line(1).FontSize = 12; 
s7(3).line(1).HorizontalAlignment = 'center';
s7(3).line(1).Layout.Column = [1 28]; % Span the panel width
s7(3).line(1).Layout.Row = [5 6]; % Place right below the checkbox

% enter core collection year
s7(3).label(2) = uilabel(s7(3).grid);
s7(3).label(2).Text = 'Core collection year';
s7(3).label(2).FontWeight = 'bold';
s7(3).label(2).FontSize = 12;
s7(3).label(2).Layout.Column = [1 16];
s7(3).label(2).Layout.Row = [7 9];

s7(3).field(1) = uieditfield(s7(3).grid,"numeric","Value",collectionYear);
s7(3).field(1).Layout.Column = [17 28];
s7(3).field(1).Layout.Row = [7 9];

% Threshold for stress band definition
s7(3).label(3) = uilabel(s7(3).grid);
s7(3).label(3).Text = 'Stress band threshold (σ)';
s7(3).label(3).FontWeight = 'bold';
s7(3).label(3).FontSize = 12;
s7(3).label(3).Layout.Column = [1 19];
s7(3).label(3).Layout.Row = [10 12];

s7(3).label(4) = uilabel(s7(3).grid);
s7(3).label(4).Text = '(Recommended: 2 sigma)';
s7(3).label(4).FontSize = 12;
s7(3).label(4).Layout.Column = [1 16];
s7(3).label(4).Layout.Row = [12 13];

s7(3).field(2) = uieditfield(s7(3).grid,"numeric","Limits",[1.5 3],"LowerLimitInclusive","on","UpperLimitInclusive","on","Value",sbThresh);
s7(3).field(2).Layout.Column = [20 28];
s7(3).field(2).Layout.Row = [11 13];

% instructions for cropping
s7(3).label(5) = uilabel(s7(3).grid);
s7(3).label(5).Text = '** Make sure you have cropped any low/high density edges at the top (blue slider) and bottom (red slider) of core **';
s7(3).label(5).WordWrap = 'on';
s7(3).label(5).FontSize = 13;
s7(3).label(5).FontAngle = 'italic';
s7(3).label(5).Layout.Column = [1 29];
s7(3).label(5).Layout.Row = [15 19];
s7(3).label(5).HorizontalAlignment = 'center';

% plot band years
s7(3).cbx(2) = uicheckbox(s7(3).grid,"Text","Label band years");
s7(3).cbx(2).Layout.Column = [1 13];
s7(3).cbx(2).Layout.Row = [20 22];

% plot unfiltered z-score (not recommended)
s7(3).cbx(3) = uicheckbox(s7(3).grid,"Text",["Plot unfiltered z-score"]);
%s7(3).cbx(5).WordWrap = 'on';
s7(3).cbx(3).Layout.Column = [1 15];
s7(3).cbx(3).Layout.Row = [23 25];

s7(3).label(6) = uilabel(s7(3).grid, "Text", "(not recommended!)");
s7(3).label(6).FontSize = 12;
s7(3).label(6).Layout.Column = [2 13];
s7(3).label(6).Layout.Row = [25 26]; % Positioned below checkbox

% button for plotting
s7(3).button(2) = uibutton(s7(3).grid);
s7(3).button(2).Enable = 'on';
s7(3).button(2).Text = 'Plot slice z-score';
s7(3).button(2).FontWeight = 'bold';
s7(3).button(2).Layout.Column = [16 28];
s7(3).button(2).Layout.Row = [20 25];
s7(3).button(2).FontSize = 13;
%% Panel 4: Plot mean band extension
s7(4).panel = uipanel(uigrid,'Title','4. Plot Slice Density');
s7(4).panel.Layout.Row = [3 28];
s7(4).panel.Layout.Column = [23 100];
s7(4).grid = uigridlayout(s7(4).panel,[10, 100]);
%s7(4).axis(1) = axes(s7(4).grid);
s7(4).axis(1) = uiaxes(s7(4).grid);
s7(4).axis(1).Layout.Row = [1 10];  % Span most of the panel
s7(4).axis(1).Layout.Column = [1 100]; % Span all columns

%% Panel 5: Plot Z-score
s7(5).panel = uipanel(uigrid,'Title','5. Plot Slice Z-Scored Density');
s7(5).panel.Layout.Row = [29 56];
s7(5).panel.Layout.Column = [23 100];
s7(5).grid = uigridlayout(s7(5).panel,[10, 100]);
s7(5).axis(1) = uiaxes(s7(5).grid);
s7(5).axis(1).Layout.Row = [1 10];  % Span most of the panel
s7(5).axis(1).Layout.Column = [1 100]; % Span all columns

%% Panel 6: Estimate stress band likelihood
s7(6).panel = uipanel(uigrid,'Title','6. Determine Stress Band Likelihood');
s7(6).panel.Layout.Row = [57 82];
s7(6).panel.Layout.Column = [23 60];
s7(6).grid = uigridlayout(s7(6).panel,[20 50]);

% plot likely stress bands
s7(6).button(1) = uibutton(s7(6).grid);
s7(6).button(1).Enable = 'on';
s7(6).button(1).Text = 'Estimate likely stress bands';
s7(6).button(1).WordWrap = 'on';
s7(6).button(1).Layout.Column = [1 18];
s7(6).button(1).Layout.Row = [1 5];
s7(6).button(1).FontSize = 13;

% edit table
% s7(6).label(1) = uilabel(s7(6).grid);
% s7(6).label(1).Text = 'Edit estimated stress band year';
% s7(6).label(1).WordWrap = 'on';
% s7(6).label(1).FontWeight = 'bold';
% s7(6).label(1).FontSize = 12;
% s7(6).label(1).Layout.Column = [1 20];
% s7(6).label(1).Layout.Row = [6 8];
% 
% s7(6).label(2) = uilabel(s7(6).grid);
% s7(6).label(2).Text = 'Band #';
% s7(6).label(2).FontSize = 12;
% s7(6).label(2).Layout.Column = [1 6];
% s7(6).label(2).Layout.Row = [8 10];
% 
% s7(6).field(1) = uieditfield(s7(6).grid,"numeric","Value",editBandYear);
% s7(6).field(1).Layout.Column = [6 10];
% s7(6).field(1).Layout.Row = [8 10];

% description of SB likelihood
s7(6).label(1) = uilabel(s7(6).grid);
s7(6).label(1).Text = 'Stress Band Likelihood:';
s7(6).label(1).FontWeight = 'bold';
s7(6).label(1).FontSize = 13;
s7(6).label(1).Layout.Column = [24 49];
s7(6).label(1).Layout.Row = [1 3];

s7(6).label(2) = uilabel(s7(6).grid);
s7(6).label(2).Text = '(1) most likely  (2) semi-likely  (3) unlikely';
s7(6).label(2).FontSize = 12;
s7(6).label(2).Layout.Column = [24 49];
s7(6).label(2).Layout.Row = [3 5];


% summary table
s7(6).table = uitable(s7(6).grid);
s7(6).table.Layout.Column = [22 49];
s7(6).table.Layout.Row = [5 20];
s7(6).table.Data = summaryTable;
%s7(6).table.ColumnWidth = {'fit', 'fit', 'fit', 'fit'}; 
s7(6).table.ColumnWidth = {'fit'  'fit'  'auto'  'fit'}; 
style = uistyle("HorizontalAlignment", "center");
addStyle(s7(6).table, style);

% export slice data
% s7(6).button(2) = uibutton(s7(6).grid);
% s7(6).button(2).Enable = 'off';
% s7(6).button(2).Text = 'Export slice/z-score data';
% s7(6).button(2).FontWeight = 'bold';
% s7(6).button(2).WordWrap = 'on';
% s7(6).button(2).Layout.Column = [1 18];
% s7(6).button(2).Layout.Row = [11 14];
% s7(6).button(2).FontSize = 13;

% export stress band likelihood
s7(6).button(3) = uibutton(s7(6).grid);
s7(6).button(3).Enable = 'off';
s7(6).button(3).Text = 'Export stress band data';
s7(6).button(3).FontWeight = 'bold';
s7(6).button(3).WordWrap = 'on';
s7(6).button(3).Layout.Column = [1 18];
s7(6).button(3).Layout.Row = [15 19];
s7(6).button(3).FontSize = 13;

%% Panel 7: Finish
s7(7).panel = uipanel(uigrid,'Title','7. Export Stress Band Analysis');
s7(7).panel.Layout.Row = [57 82];
s7(7).panel.Layout.Column = [61 100];
s7(7).grid = uigridlayout(s7(7).panel,[22 50]);

s7(7).label(1) = uilabel(s7(7).grid);
s7(7).label(1).Text = 'Slices analyzed:';
s7(7).label(1).FontWeight = 'bold';
s7(7).label(1).FontSize = 13;
s7(7).label(1).Layout.Column = [1 10];
s7(7).label(1).Layout.Row = [1 3];

% slices analyzed
s7(7).cbx(1) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(1).Layout.Column = [1 2]; s7(7).cbx(1).Layout.Row = [4 6]; s7(7).cbx(1).Enable = "off"; 
s7(7).lbl(1) = uilabel(s7(7).grid, "Text", "Slice 1");
s7(7).lbl(1).Layout.Column = [3 7]; s7(7).lbl(1).Layout.Row = [4 6];

s7(7).cbx(2) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(2).Layout.Column = [8 9]; s7(7).cbx(2).Layout.Row = [4 6]; s7(7).cbx(2).Enable = "off"; 
s7(7).lbl(2) = uilabel(s7(7).grid, "Text", "Slice 2");
s7(7).lbl(2).Layout.Column = [10 14]; s7(7).lbl(2).Layout.Row = [4 6];

s7(7).cbx(3) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(3).Layout.Column = [15 16]; s7(7).cbx(3).Layout.Row = [4 6]; s7(7).cbx(3).Enable = "off"; 
s7(7).lbl(3) = uilabel(s7(7).grid, "Text", "Slice 3");
s7(7).lbl(3).Layout.Column = [17 21]; s7(7).lbl(3).Layout.Row = [4 6];

s7(7).cbx(4) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(4).Layout.Column = [1 2]; s7(7).cbx(4).Layout.Row = [7 9]; s7(7).cbx(4).Enable = "off"; 
s7(7).lbl(4) = uilabel(s7(7).grid, "Text", "Slice 4");
s7(7).lbl(4).Layout.Column = [3 7]; s7(7).lbl(4).Layout.Row = [7 9];

s7(7).cbx(5) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(5).Layout.Column = [8 9]; s7(7).cbx(5).Layout.Row = [7 9]; s7(7).cbx(5).Enable = "off"; 
s7(7).lbl(5) = uilabel(s7(7).grid, "Text", "Slice 5");
s7(7).lbl(5).Layout.Column = [10 14]; s7(7).lbl(5).Layout.Row = [7 9];

s7(7).cbx(6) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(6).Layout.Column = [15 16]; s7(7).cbx(6).Layout.Row = [7 9]; s7(7).cbx(6).Enable = "off"; 
s7(7).lbl(6) = uilabel(s7(7).grid, "Text", "Slice 6");
s7(7).lbl(6).Layout.Column = [17 21]; s7(7).lbl(6).Layout.Row = [7 9];

s7(7).cbx(7) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(7).Layout.Column = [1 2]; s7(7).cbx(7).Layout.Row = [10 12]; s7(7).cbx(7).Enable = "off"; 
s7(7).lbl(7) = uilabel(s7(7).grid, "Text", "Slice 7");
s7(7).lbl(7).Layout.Column = [3 7]; s7(7).lbl(7).Layout.Row = [10 12];

s7(7).cbx(8) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(8).Layout.Column = [8 9]; s7(7).cbx(8).Layout.Row = [10 12]; s7(7).cbx(8).Enable = "off"; 
s7(7).lbl(8) = uilabel(s7(7).grid, "Text", "Slice 8");
s7(7).lbl(8).Layout.Column = [10 14]; s7(7).lbl(8).Layout.Row = [10 12];

s7(7).cbx(9) = uicheckbox(s7(7).grid,"Text"," "); 
s7(7).cbx(9).Layout.Column = [15 16]; s7(7).cbx(9).Layout.Row = [10 12]; s7(7).cbx(9).Enable = "off"; 
s7(7).lbl(9) = uilabel(s7(7).grid, "Text", "Slice 9");
s7(7).lbl(9).Layout.Column = [17 21]; s7(7).lbl(9).Layout.Row = [10 12];

s7(7).label(2) = uilabel(s7(7).grid);
s7(7).label(2).Text = '(Click "Export Stress Band Data" to check off analyzed slices)';
s7(7).label(2).WordWrap = 'on';
s7(7).label(2).Layout.Column = [1 21];
s7(7).label(2).Layout.Row = [13 16];

s7(7).button(1) = uibutton(s7(7).grid);
s7(7).button(1).Text = 'Done with all slices';
s7(7).button(1).FontWeight = 'bold';
s7(7).button(1).WordWrap = 'on';
s7(7).button(1).Layout.Column = [1 20];
s7(7).button(1).Layout.Row = [17 21];
s7(7).button(1).FontSize = 13;

% summary table
s7(7).table = uitable(s7(7).grid);
s7(7).table.Layout.Column = [22 49];
s7(7).table.Layout.Row = [1 16];
s7(7).table.Data = SBstats;
%s7(7).table.ColumnWidth = {'fit'  'fit'  'auto'  'fit'}; 
%style = uistyle("HorizontalAlignment", "center");
%addStyle(s7(7).table, style);

% finish button
s7(7).button(2) = uibutton(s7(7).grid,'state');
s7(7).button(2).Enable = 'off';
s7(7).button(2).Text = 'Check stress bands';
s7(7).button(2).FontWeight = 'bold';
s7(7).button(2).WordWrap = 'on';
s7(7).button(2).Layout.Column = [30 49];
s7(7).button(2).Layout.Row = [17 21];
s7(7).button(2).FontSize = 13;
s7(7).button(2).BackgroundColor = [0.929 0.462 0.385];


%% Initialize button call backs and screen variables:
UpdateCallbacks;

% wait for user interactions
waitfor(s7(7).button(2),'Value',true)

% save bandlocs to matfile
%mfile.BandInfo = BandInfo;
%mfile.bandSurf = bandSurf;
%save(mfile.Properties.Source, '-append','BandInfo','bandSurf');

% if resumed, continue to next scene:
clf(UI)
sn = 8;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateCallbacks
        % Panel 1 - Set Genus, Collection year, analyze
        s7(1).button(1).ButtonPushedFcn = {@chooseProbeDiameter};
        s7(2).button(1).ButtonPushedFcn = {@calculateSlices};
        s7(3).button(1).ButtonPushedFcn = {@plotSliceDens};
        s7(3).button(2).ButtonPushedFcn = {@plotZscore};
        s7(6).button(1).ButtonPushedFcn = {@estimateStressBands};
        %s7(6).button(2).ButtonPushedFcn = {@exportZscore};
        s7(6).button(3).ButtonPushedFcn = {@exportStressBand};
        s7(7).button(1).ButtonPushedFcn = {@checkIfFinished};

        % Panel 5 - Export data as .xlsx file
        % s7(5).button(1).ButtonPushedFcn = {@exportSummaryTbl};

    end

    function chooseProbeDiameter(src,event)

        % allow user to begin IDing bands
        %s7(1).button(2).Enable = 'on';

        % parse probe diameter
        PixelDistance = ceil(s7(1).field(1).Value); % round in case of accidental decimal input

        % determine 9 coordinates of slices
        sliceCoords = sliceLocRaw();
        mfile.sliceCoords = sliceCoords;

        % variableInfo = who(mfile);
        % if ismember('bandLocs',variableInfo) && ~isempty(mfile.bandLocs) % if bands are already chosen
        %     sliceCoords = sliceLoc(bandLocs);
        % else
        %   sliceCoords = sliceLocRaw();
        %end

        plotPixelRadius(sliceCoords)

        UpdateCallbacks;

    end

    function calculateSlices(src,event)
        % check if slices already exist
        if isprop(mfile, 'slices') && ~isempty(mfile.slices)
            % Ask if want to use old slices or new slices
            slices = mfile.slices;
            msg = 'Existing slices detected. Use or create new?';
            title = 'Slices Detected';
            uiconfirm(UI, msg, title, 'Options', {'Use Existing Slices', 'Create New Slices'}, ...
                'DefaultOption', 1, 'CancelOption', 1, 'CloseFcn', @dlgcallback);
            % make the density slice button unpressable
            s7(2).button(1).Enable = 'off';

            if isprop(mfile, 'sliceCoords')
                sliceCoords = mfile.sliceCoords;

                % interpolate band surfaces if bands exist
                if isprop(mfile, 'bandLocs')
                    bandSurf = bandSurfaceInterp(bandLocs, Xdims);
                    bandCross = findBandCrossing(sliceCoords, bandSurf);
                end

                if isprop(mfile, 'stressBands')
                    sbSurf = bandSurfaceInterp(stressBands, Xdims);
                    sbCross = findBandCrossing(sliceCoords,sbSurf);
                    for i = 1:3
                        for j = 1:3
                            sbCross{i,j}(1,:) = [];
                        end
                    end
                end

            else
                uialert(UI,'No slice coordinates found. Recompute slices',"Warning","Icon","Warning")
            end
        else
            % no existing slices, compute new ones
            computeNewSlices();
        end


        % Nested function to compute new slices
        function computeNewSlices()
            % Disable the density slice button
            s7(2).button(1).Enable = 'off';

            % Compute slices
            slices = coreSlice(sliceCoords, PixelDistance);
            save(mfile.Properties.Source, '-append','slices'); mfile.slices = slices;
            save(mfile.Properties.Source, '-append','sliceCoords'); mfile.sliceCoords = sliceCoords;

            % interpolate band surfaces if bands exist
            if isprop(mfile, 'bandLocs')
                bandSurf = bandSurfaceInterp(bandLocs, Xdims);
                bandCross = findBandCrossing(sliceCoords, bandSurf);
            end

            if isprop(mfile, 'stressBands')
                sbSurf = bandSurfaceInterp(stressBands, Xdims);
                sbCross = findBandCrossing(sliceCoords,sbSurf);
                for i = 1:3
                    for j = 1:3
                        sbCross{i,j}(1,:) = [];
                    end
                end
            end

             % Display status notification
             uialert(UI,'Done computing slices','Slicing Status','Icon','success');

            % Update callbacks or perform any necessary follow-up
            UpdateCallbacks();
        end

        UpdateCallbacks;

        % Dialogue callback:
        function dlgcallback(src,event)
            %if event.SelectedOption == "Create New Slices"
            if strcmp(event.SelectedOption, "Create New Slices")
                % clear existing slices
                mfile.slices = [];

                % compute slices
                computeNewSlices();
            end
        end
    end

    function plotSliceDens(src, event)
        % determine which slice is being examined
        sliceNum = str2double(extractAfter(s7(3).dropdown.Value, 'Slice '));

        % clear the axis before updating
        if isfield(s7(4), 'axis') && isvalid(s7(4).axis(1))
            cla(s7(4).axis(1), 'reset');
        else
            s7(4).axis(1) = axes(s7(4).grid);
        end

        % compute density min and max
        densMin = min(slices{sliceNum}(:,2));
        densMax = max(slices{sliceNum}(:,2));
        depthMin = min(slices{sliceNum}(:,1));
        depthMax = max(slices{sliceNum}(:,1));

        % compute lowpass filtering on data
        %idx = ~isnan(slices{sliceNum}(1:end,2));
        idx = find(slices{sliceNum}(:,1) >= depthMin + 15 & slices{sliceNum}(:,1) <= depthMax - 15 & ~isnan(slices{sliceNum}(1:end,2)));

        % Old code
        % if exist("bandCross") && ~isempty(bandCross)
        %     est_annualBandGrowth = median(diff(bandCross{sliceNum}));
        % else
        %     est_annualBandGrowth = 12; % really arbitrary
        % end
        % Fc = 1/(est_annualBandGrowth*25); % 5 is a random factor!!
        % 
        % lowpassDens = filt1('lp',slices{sliceNum}(idx,2),'fc',Fc);

        % new code: gaussian filtering
        smoothingWindow = length(slices{sliceNum}(idx,1))/5;
        lowpassDens = smoothdata(slices{sliceNum}(idx,2), 'gaussian', smoothingWindow);

        plot(s7(4).axis(1), slices{sliceNum}(1:end,1), slices{sliceNum}(1:end,2),'k','LineWidth',1);
        hold(s7(4).axis(1), 'on');
        plot(s7(4).axis(1), slices{sliceNum}(idx,1), lowpassDens,'LineWidth',2);
        xlabel(s7(4).axis(1),['Depth Downcore (mm)']);
        xlim(s7(4).axis(1),[slices{sliceNum}(1,1) slices{sliceNum}(end,1)])
        ylabel(s7(4).axis(1),['Density (g/cm^3)']);
        title(s7(4).axis(1),['Slice #', int2str(sliceNum)])

        if s7(3).cbx(1).Value == 1 % user wants to plot bands
            if isempty(bandCross)
                message = ["No saved user bands detected"];
                uialert(UI,message,"Warning","Icon","Warning")
            elseif ~isempty(bandCross)
                for i = 1:length(bandCross{sliceNum})
                    xline(s7(4).axis(1),bandCross{sliceNum}(i),':b','LineWidth',0.75)
                end
                if exist("sbCross") && ~isempty(sbCross)
                    for j = 1:length(sbCross{sliceNum})
                        xline(s7(4).axis(1),sbCross{sliceNum}(j),':', 'Color','#eb65c3','LineWidth',3); hold(s7(4).axis(1),'on');
                    end
                end
            end
        end
        %grid(s7(4).axis(1), 'off')


        SliderLines;
    end


    function plotZscore(src, event)
        % determine indices of NaNs to be removed
        %idx = ~isnan(slices{sliceNum}(1:end,2));
        %sliceData = slices{sliceNum}(idx,:); % remove NaNs
        sbThresh = s7(3).field(2).Value;
        sliceData = slices{sliceNum};

        % clear the axis before updating
        if isfield(s7(5), 'axis') && isvalid(s7(5).axis(1))
            cla(s7(5).axis(1), 'reset');
        else
            s7(5).axis(1) = axes(s7(5).grid);
        end

        % find position of cropping slider lines
        depthLim(1) = BlueLine.Position(1);
        depthLim(2) = RedLine.Position(1);

        % find depth limit within plot
        depthIdx = find(sliceData(:,1)>=depthLim(1) & sliceData(:,1)<=depthLim(2));
        depthAx = sliceData(depthIdx,1);

        % compute Z-score
        computeZScore(depthIdx)

        if s7(3).cbx(3).Value == 0 % plot original Z-score
            plot(s7(5).axis(1), depthAx, zScore,'k','LineWidth',1);
            hold(s7(5).axis(1), 'on'); 

            % Loop through each segment (pair of consecutive points)
            for i = 1:length(zScore)-1
                x1 = depthAx(i);  y1 = zScore(i);
                x2 = depthAx(i+1); y2 = zScore(i+1);

                % If both points are above sbThresh, plot full segment in red
                if y1 >= sbThresh && y2 >= sbThresh
                    plot(s7(5).axis(1), [x1, x2], [y1, y2], 'r', 'LineWidth', 1.2);

                    % If one point is above and the other below, find intersection
                elseif (y1 < sbThresh && y2 >= sbThresh) || (y1 >= sbThresh && y2 < sbThresh)
                    % Compute intersection with sbThresh
                    xIntersect = x1 + (x2 - x1) * (sbThresh - y1) / (y2 - y1);
                    yIntersect = sbThresh; % Always at sbThresh

                    % Plot lower part in black
                    if y1 < sbThresh
                        plot(s7(5).axis(1), [x1, xIntersect], [y1, yIntersect], 'k', 'LineWidth', 1);
                        plot(s7(5).axis(1), [xIntersect, x2], [yIntersect, y2], 'r', 'LineWidth', 1.2);
                    else
                        plot(s7(5).axis(1), [x1, xIntersect], [y1, yIntersect], 'r', 'LineWidth', 1.2);
                        plot(s7(5).axis(1), [xIntersect, x2], [yIntersect, y2], 'k', 'LineWidth', 1);
                    end
                end
            end
            title(s7(5).axis(1),['Slice #', int2str(sliceNum), ' Filtered Z-Score'])

        elseif s7(3).cbx(3).Value == 1 % plot unfiltered Z-score
            uialert(UI,'Plotting unfiltered Z-Score is not recommended',"Warning","Icon","Warning")
            plot(s7(5).axis(1), depthAx, unfiltzScore,'k','LineWidth',1);
            title(s7(5).axis(1),['Slice #', int2str(sliceNum), ' Unfiltered Z-Score']);
            hold(s7(5).axis(1), 'on');
            % Loop through each segment (pair of consecutive points)
            for i = 1:length(unfiltzScore)-1
                x1 = depthAx(i);  y1 = unfiltzScore(i);
                x2 = depthAx(i+1); y2 = unfiltzScore(i+1);

                % If both points are above sbThresh, plot full segment in red
                if y1 >= sbThresh && y2 >= sbThresh
                    plot(s7(5).axis(1), [x1, x2], [y1, y2], 'r', 'LineWidth', 1.2);

                    % If one point is above and the other below, find intersection
                elseif (y1 < sbThresh && y2 >= sbThresh) || (y1 >= sbThresh && y2 < sbThresh)
                    % Compute intersection with sbThresh
                    xIntersect = x1 + (x2 - x1) * (sbThresh - y1) / (y2 - y1);
                    yIntersect = sbThresh; % Always at sbThresh

                    % Plot lower part in black
                    if y1 < sbThresh
                        plot(s7(5).axis(1), [x1, xIntersect], [y1, yIntersect], 'k', 'LineWidth', 1);
                        plot(s7(5).axis(1), [xIntersect, x2], [yIntersect, y2], 'r', 'LineWidth', 1.2);
                    else
                        plot(s7(5).axis(1), [x1, xIntersect], [y1, yIntersect], 'r', 'LineWidth', 1.2);
                        plot(s7(5).axis(1), [xIntersect, x2], [yIntersect, y2], 'k', 'LineWidth', 1);
                    end
                end
            end
        end

        hold(s7(5).axis(1), 'on');
        yline(s7(5).axis(1),0,'-k')
        yline(s7(5).axis(1),sbThresh,'-r')
        if ~isempty(bandCross)
            for i = 1:length(bandCross{sliceNum})
                xline(s7(5).axis(1),bandCross{sliceNum}(i),':b','LineWidth',0.75)
            end
        end

        if exist("sbCross") && ~isempty(sbCross)
            for j = 1:length(sbCross{sliceNum})
                xline(s7(5).axis(1),sbCross{sliceNum}(j),':', 'Color','#eb65c3','LineWidth',3)
            end
        end

        % plot band years (if selected)
        if s7(3).cbx(2).Value == 1 % label band years
            collectionYear = s7(3).field(1).Value;
            zScoreMin = min(zScore);
            count = 1;
            for k = 1:length(bandCross{sliceNum})
                text(s7(5).axis(1),bandCross{sliceNum}(k,1),zScoreMin*1.05,int2str(collectionYear-count+1),'FontSize',11)
                count = count + 1;
            end
        end
        xlabel(s7(5).axis(1),'Cropped Depth Downcore (mm)');
        xlim(s7(5).axis(1),depthLim)
        ylabel(s7(5).axis(1),['Z-Score (σ)']);

        % turn off slice computing buttons
        s7(1).button(1).Enable = 'off';
        s7(2).button(1).Enable = 'off';
    end

    function estimateStressBands(src,event)
        % Initialize storage for segment statistics
        segmentWidths = [];
        maxHeights = [];
        integratedAreas = [];
        segmentDepthMidpoint = [];
        inSegment = false;
        startIdx = NaN;
        sbThresh = s7(3).field(2).Value;

        % Loop through each segment (pair of consecutive points)
        for i = 1:length(zScore)-1
            x1 = depthAx(i);  y1 = zScore(i);
            x2 = depthAx(i+1); y2 = zScore(i+1);

            % Check if the segment crosses sbThresh
            if y1 >= sbThresh && y2 >= sbThresh  % Entire segment above threshold
                if ~inSegment
                    startIdx = i; % Start new segment
                    inSegment = true;
                end

            elseif (y1 < sbThresh && y2 >= sbThresh) || (y1 >= sbThresh && y2 < sbThresh)
                % Compute intersection with sbThresh
                xIntersect = x1 + (x2 - x1) * (sbThresh - y1) / (y2 - y1);
                yIntersect = sbThresh;

                if y1 < sbThresh % Entering a segment
                    startIdx = i; % Mark the start
                    inSegment = true;
                else % Exiting a segment
                    % Extract segment data
                    if isnan(startIdx)
                        startIdx = 1;
                    end
                    segmentDepths = depthAx(startIdx:i); % X values
                    segmentHeights = zScore(startIdx:i) - sbThresh; % Y values above sbThresh

                    % Append interpolated exit point
                    segmentDepths = [segmentDepths; xIntersect];
                    segmentHeights = [segmentHeights; yIntersect - sbThresh];

                    % Store segment statistics
                    segmentWidths(end+1,1) = max(segmentDepths) - min(segmentDepths);
                    maxHeights(end+1,1) = max(segmentHeights);
                    integratedAreas(end+1,1) = trapz(segmentDepths, segmentHeights); % Trapezoidal integration
                    segmentDepthMidpoint(end+1,1) = mean(segmentDepths); % Compute midpoint

                    % Reset tracking
                    inSegment = false;
                end
            end
        end

        % If the last segment didn't close, close it manually
        if inSegment
            segmentDepths = depthAx(startIdx:end);
            segmentHeights = zScore(startIdx:end) - sbThresh;

            segmentWidths(end+1,1) = max(segmentDepths) - min(segmentDepths);
            maxHeights(end+1,1) = max(segmentHeights);
            integratedAreas(end+1,1) = trapz(segmentDepths, segmentHeights);
            segmentDepthMidpoint(end+1,1) = mean(segmentDepths); % Compute midpoint
        end

        varNames = ["StressBand", "Depth", "Width", "MaxHeight", "Area"];
        SBsummarytable = table('Size', [0 5], 'VariableTypes', ["double", "double", "double", "double", "double"], 'VariableNames', varNames);

        % Initialize counters
        count = 1;
        i = 1; % Start index

        while i <= length(segmentDepthMidpoint)
            % Initialize merged peak properties
            mergedDepths = segmentDepthMidpoint(i);
            mergedWidths = segmentWidths(i);
            mergedMaxHeight = maxHeights(i);
            mergedArea = integratedAreas(i);
            numMerged = 1; % Track how many peaks are merged

            % Keep merging while the next peak is within 1.5 mm
            while i + numMerged <= length(segmentDepthMidpoint) && ...
                    segmentDepthMidpoint(i + numMerged) - segmentDepthMidpoint(i + numMerged - 1) <= 1.5
                % Update merged values
                mergedDepths = [mergedDepths, segmentDepthMidpoint(i + numMerged)];
                mergedWidths = mergedWidths + segmentWidths(i + numMerged);
                mergedMaxHeight = max(mergedMaxHeight, maxHeights(i + numMerged));
                mergedArea = mergedArea + integratedAreas(i + numMerged);
                numMerged = numMerged + 1;
            end

            % Compute final merged depth as the average of all merged midpoints
            finalMergedDepth = mean(mergedDepths);

            % Store merged segment in table
            SBsummarytable.Depth(count) = finalMergedDepth;
            SBsummarytable.Width(count) = mergedWidths;
            SBsummarytable.MaxHeight(count) = mergedMaxHeight;
            SBsummarytable.Area(count) = mergedArea;

            % Move to the next unmerged peak
            i = i + numMerged;
            count = count + 1;
        end

        % Remove rows where Area < 0.005
        SBsummarytable(SBsummarytable.Area < 0.005, :) = [];

        % Remove rows where Max Height < 0.2 and Max Width < 0.2
        SBsummarytable(SBsummarytable.MaxHeight < 0.25 & SBsummarytable.Width < 0.25, :) = [];

        SBsummarytable.StressBand = [1:height(SBsummarytable)]';

        % estimate peak likelihood
        stressBandLikelihood

        % Plot likely stress bands on section 5
        plotStressBands

        % turn on export buttons
        %s7(6).button(2).Enable = 'on';
        s7(6).button(3).Enable = 'on';

    end

    function exportStressBand(src, event)
        % check if zScore has data
        if isempty(sliceZscore{sliceNum})
            message = ["No Z-Score saved for this slice","Plot slice Z-score to continue"];
            uialert(UI,message,"No Z-Score saved","Icon","error")
        elseif isempty(sliceStressBand{sliceNum})
            message = ["No stress bands saved for this slice","Estimate stress bands to continue"];
            uialert(UI,message,"No stress bands saved","Icon","error")
        else
            % set up table
            T = array2table(slices{sliceNum}, 'VariableNames',{'Depth Downcore','Density (g/cm3)'});
            lengthDiff = size(slices{sliceNum}, 1) - length(depthAx);
            T.depthAx = [depthAx; NaN(lengthDiff,1)];
            T.ZScore = [zScore; NaN(lengthDiff,1)];
            T.unfilteredZScore = [unfiltzScore; NaN(lengthDiff,1)];

            % determine what year each depth corresponds to
            count = 1;
            temp = zeros(size(depthAx));
            for i = 1:length(depthAx)
                while count < size(AnnualBandDepth, 1) && depthAx(i) > AnnualBandDepth(count, 2)
                    count = count + 1;
                end
                temp(i, 1) = AnnualBandDepth(count, 1)+1;
            end
            T.estYear = [temp; NaN(lengthDiff,1)];

            % change variable names
            T.Properties.VariableNames = {'Depth Downcore (mm)','Density (g/cm3)','Cropped Depth (mm)','Z-Score','Unfiltered Z-Score', 'Estimated Year'};

            % export summary table as csv
            [filename, filepath] = uiputfile('*.xlsx', 'Save z-score summary table');
            FileName = fullfile(filepath, filename);
            writetable(T, FileName,'Sheet',['Slice ', num2str(sliceNum)],'Range','A1');
            writetable(sliceStressBand{sliceNum},FileName,'Sheet',['Slice ', num2str(sliceNum)],'Range','I1');
            mfile.sliceZscore = sliceZscore;
            s7(7).cbx(sliceNum).Value = true;
            mfile.sliceStressBand = sliceStressBand;
        end

    end

    % function exportStressBand(src, event)        
    %     % check if zScore has data
    %     if isempty(sliceStressBand{sliceNum})
    %         message = ["No stress bands saved for this slice","Estimate stress bands to continue"];
    %         uialert(UI,message,"No stress bands saved","Icon","error")
    %     else
    %         [filename, filepath] = uiputfile('*.xlsx', 'Save estimated stress band summary table');
    %         FileName = fullfile(filepath, filename);
    %         writetable(sliceStressBand{sliceNum},FileName,'Sheet',['Slice ', num2str(sliceNum)],'Range','I1');
    % 
    %         s7(7).cbx(sliceNum).Value = true;
    %         mfile.sliceStressBand = sliceStressBand;
    %     end
    % 
    % 
    % end


    function checkIfFinished(src,event)
        idx = false;
        for i = 1:9
            if isempty(sliceStressBand{i})
                idx = true;
            end
        end

        if idx == false
            s7(7).button(2).Enable = 'on'; 
            message = ["All 9 slices have been analyzed and saved.","", "If you would like to check slices, click 'Check stress bands'"];
            uialert(UI,message,"Analysis complete","Icon","success")
            
            collateSBstats;
            s7(7).table.Data = SBstats;

            [filename, filepath] = uiputfile('*.xlsx', 'Save final stress band summary table');
            FileName = fullfile(filepath, filename);
            writetable(SBstats,FileName,'Sheet',['Summary Statistics'],'Range','A1');

            
        elseif idx == true
            message = ["Not all 9 slices have been analyzed for stress bands.","", "Please estimate stress bands in all slices and export stress band data"];
            uialert(UI,message,"Missing slices","Icon","warning")
        end
    end

%% %%%%%%%%%%%%% OTHER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function plotPixelRadius(sliceCoords)
        % Plot slice through the middle of the scan
        imagesc(s7(2).axes, ScanXn); hold on
        hold(s7(2).axes, 'on');
        colormap(s7(2).axes, 'bone');
        s7(2).axes.YDir = 'normal'; s7(2).axes.XDir = 'normal';
        axis(s7(2).axes, 'image');  % Make aspect ratio 1:1
        s7(2).axes.XTick = [];  s7(2).axes.YTick = []; %remove ticks

        % plot 9 points
        for i = 1:3
            for j = 1:3
                pgon = polyshape([sliceCoords{i,j}(:,1)-PixelDistance sliceCoords{i,j}(:,1)-PixelDistance sliceCoords{i,j}(:,1)+PixelDistance sliceCoords{i,j}(:,1)+PixelDistance],[sliceCoords{i,j}(:,2)+PixelDistance sliceCoords{i,j}(:,2)-PixelDistance sliceCoords{i,j}(:,2)-PixelDistance sliceCoords{i,j}(:,2)+PixelDistance]);
                plot(s7(2).axes,pgon,'FaceColor','w','FaceAlpha',0.7)
                scatter(s7(2).axes, sliceCoords{i,j}(:,1),sliceCoords{i,j}(:,2),30,'r','filled','MarkerEdgeColor','k');
            end
        end

    end


% function sliceCoords = sliceLoc(bandLocs)
%     % works if bands have been picked already
%     % determine coords for the 9 x-sections
%     temp = zeros(2,3);
%     for i = 1:width(bandLocs)
%         if i <4
%             temp(2,i) = bandLocs{1,i}(1,2); % x-cut
%         else
%             temp(1,i-3) = bandLocs{1,i}(1,1); % y-cut
%         end
%     end
%     temp = sort(temp,2); % sort rows in ascending order
%
%     % set up 9 x-section coords
%     [X, Y] = meshgrid(temp(1,:), temp(2,:)); clear temp
%     temp = [X(:) Y(:)];
%
%     % reshape into a cell
%     sliceCoords = cell(3,3);
%     for i = 1:3
%         for j = 1:3
%             index = (i - 1) * 3 + j;
%             sliceCoords{i, j} = temp(index, :);
%         end
%     end
% end

    function sliceCoords = sliceLocRaw()
        % works if no bands were picked yet
        % choose core filter
        if  metadata.PixelSpacing < 0.1 % < 100 microns (ex. 96 um)
            h2 = fspecial('disk',3);
        elseif  metadata.PixelSpacing > 0.1 % > 100 microns (ex. 184.4 um)
            h2 = fspecial('gaussian',2,15);
        end

        % set up slab positions: sample core for general location within image
        samp = floor(median(ReconDims.Z)); % sample middle of ReconDims.Z
        Xsamp = double(mfile.Scan(ReconDims.X,ReconDims.Y,samp)).*metadata.RescaleSlope + metadata.RescaleIntercept;
        filteredXcore(:,:) = imsharpen(imfilter(Xsamp, h2, 'replicate'));

        % determine where coral is in the image
        level = graythresh(filteredXcore);
        coralSamp = imbinarize(filteredXcore,level);
        coralSamp = bwareaopen(coralSamp, 50); % remove small noise
        
        [r,c] = find(coralSamp);

        % select top/bottom/left/rightmost points of the core in the sampled slice
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
        temp(2,1:3) = [round((center(2)+topMost(2))/2) center(2) round((center(2)+bottomMost(2))/2)]; % horizontal cuts
        temp(1,1:3) = [round((center(1)+leftMost(1))/2) center(1) round((center(1)+rightMost(1))/2)]; % vertical cuts

        % set up 9 x-section coords
        [X, Y] = meshgrid(temp(1,:), temp(2,:)); clear temp
        temp = [X(:) Y(:)];

        % reshape into a cell
        sliceCoords = cell(3,3);
        for i = 1:3
            for j = 1:3
                index = (i - 1) * 3 + j;
                sliceCoords{i, j} = temp(index, :);
            end
        end
    end

    function slices = coreSlice(sliceCoords, PixelDistance)
        slices = cell(3,3);
        Scan = mfile.Scan(ReconDims.X, ReconDims.Y, ReconDims.Z);

        % preallocate memory for efficiency
        for i = 1:3
            for j = 1:3
                slices{i,j} = zeros(length(ReconDims.Z), 2);
            end
        end

        % Precompute x and y ranges
        xRanges = cell(3,3);
        yRanges = cell(3,3);
        for i = 1:3
            for j = 1:3
                xRanges{i,j} = max(1, sliceCoords{i,j}(1) - PixelDistance) : min(size(Scan,1), sliceCoords{i,j}(1) + PixelDistance);
                yRanges{i,j} = max(1, sliceCoords{i,j}(2) - PixelDistance) : min(size(Scan,2), sliceCoords{i,j}(2) + PixelDistance);
                slices{i,j} = zeros(length(ReconDims.Z), 2);
            end
        end

        % create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Calculating density slices');

        for count = 1:length(ReconDims.Z)
            %k = ReconDims.Z(count);

            % Update progress bar periodically
            if mod(count, 10) == 0 || count == length(ReconDims.Z)
                pbar.Value = count / length(ReconDims.Z);
            end

            % Apply conversions:
            Slice = double(Scan(:,:,count));

            % Compute Z-coordinate of core
            z = ReconDims.Z(count) * metadata.PixelZSpacing;

            % Apply CoreFilter to determine what is core in each slice
            IsCore = CoreFilter2(Slice,CoralPixelDistribution, metadata, densitySample);

            for i = 1:3
                for j = 1:3
                    % Define x and y range
                    xrange = xRanges{i,j};
                    yrange = yRanges{i,j};

                    % --- COMPUTE MEAN OF BOX
                    % Extract part of Slice and check if each pixel is identified (IsCore)
                    SliceBox = (Slice(yrange,xrange)*metadata.RescaleSlope + metadata.RescaleIntercept).*logical(IsCore(yrange, xrange));

                    % Compute mean, with density conversion, save to variable
                    slices{i,j}(count,1) = z; % save z-coord
                    slices{i,j}(count,2) = mean(nonzeros(SliceBox))*DCSlope + DCIntercept;


                end
            end
        end
        close(pbar)
    end

    function bandSurf = bandSurfaceInterp(bandLocs,Xdims)
        % BANDSURFACEINTERP interpolates band through core
        totBand = height(bandLocs);

        % Create grid
        xv = linspace(0, Xdims(1), Xdims(1));
        yv = linspace(0, Xdims(2), Xdims(2));
        [X, Y] = meshgrid(xv, yv);

        % make cell with each band location
        band = cell(totBand,1);
        for bandNum = 1:totBand
            band{bandNum,1} = cat(1, bandLocs{bandNum, :});
        end

        % do rough interpolation
        for bandNum = 1:totBand
            Z{bandNum,1} = (griddata(band{bandNum}(:,1),band{bandNum}(:,2),band{bandNum}(:,3),X,Y,'cubic'))';
        end

        bandSurf = Z;

        for bandNum = 1:totBand
            %perform interpolation
            nanMask = isnan(Z{bandNum});
            [~,idx] = bwdist(~nanMask,'euclidean');
            nearestIdx = cell(size(Z{bandNum}));

            for i = 1:size(nearestIdx,1)
                for j = 1:size(nearestIdx,2)
                    [row,col] = ind2sub(size(idx), idx(i,j));
                    if nanMask(i,j) == 1
                        bandSurf{bandNum}(i,j) = Z{bandNum}(row,col);
                    end
                end
            end
        end
    end

    function bandCross = findBandCrossing(sliceCoords,bandSurface)
    % determine where band crosses each individual slice
        numSlices = length(ReconDims.Z);
        numBands = length(bandSurface);

        % Precompute x and y ranges
        xRanges = cell(3,3);
        yRanges = cell(3,3);
        for i = 1:3
            for j = 1:3
                % xRanges{i,j} = (sliceCoords{i,j}(1) - PixelDistance - ReconDims.X(1)): (sliceCoords{i,j}(1) + PixelDistance - ReconDims.X(1));
                % yRanges{i,j} = (sliceCoords{i,j}(2) - PixelDistance - ReconDims.Y(1)): (sliceCoords{i,j}(2) + PixelDistance - ReconDims.Y(1));
                xRanges{i,j} = (sliceCoords{i,j}(1) - PixelDistance): (sliceCoords{i,j}(1) + PixelDistance);
                yRanges{i,j} = (sliceCoords{i,j}(2) - PixelDistance): (sliceCoords{i,j}(2) + PixelDistance);
            end
        end

        % preallocate memory
        bandCross = cell(3,3);
        bc = zeros(numBands, 1);

        for count = 1:numSlices
            for i = 1:3
                for j = 1:3
                    % Define x and y range
                    xrange = xRanges{i,j};
                    yrange = yRanges{i,j};

                    % Compute mean bandcrossing surface
                    for a = 1:numBands
                        temp = bandSurface{a}(yrange,xrange);
                        bc(a,1) = mean(temp(:)) * metadata.PixelZSpacing;
                    end

                    % set the first band to be the top of the core
                    firstBandIdx = find(~isnan(slices{i,j}(:,2)), 1);
                    bandCross{i,j} = [slices{i,j}(firstBandIdx,1); bc];
                end
            end
        end
    end

    function SliderLines
        % Draw Blue line onto the slider image:
        BlueLine = images.roi.Line(s7(4).axis(1));
        BlueLine.Position = [depthMin+15 densMin-.5; depthMin+15 densMax+.5];
        BlueLine.Selected = false;
        BlueLine.InteractionsAllowed = 'Translate';
        BlueLine.Tag = 'Blue';
        BlueLine.Color = 'b';
        %addlistener(BlueLine,'ROIMoved',@LineMove);

        % Draw Red line onto the slider image:
        RedLine = images.roi.Line(s7(4).axis(1));
        RedLine.Position = [depthMax-15 densMin-.5; depthMax-15 densMax+.5];
        RedLine.Selected = false;
        RedLine.InteractionsAllowed = 'Translate';
        RedLine.Tag = 'Red';
        RedLine.Color = 'r';
        %addlistener(RedLine,'ROIMoved',@LineMove);

        % Initialize Plots:
        %PlotMovers('Blue','b',BlueLine.Position);
        %PlotMovers('Red','r',RedLine.Position);

        % Callback function for moving ROI
        % function LineMove(src,event)
        %     % Update mover plots
        %     %PlotMovers(src.Tag,src.Color,event.CurrentPosition)
        %     % Reset both lines
        %     BlueLine.Selected = false;
        %     RedLine.Selected = false;
        % end
    end

    function computeZScore(depthIdx)
    % computes Z score after detrending density
        % determine indices of NaNs to be removed
        idx = find(~isnan(slices{sliceNum}(1:end,2)));
        depthIdx = intersect(idx, depthIdx);
        sliceDens = slices{sliceNum}(depthIdx,2);
        depthAx = slices{sliceNum}(depthIdx,1);
        %lowpassDens = filt1('lp',slices{sliceNum}(depthIdx,2),'fc',Fc);
        smoothingWindow = length(depthAx)/5;
        lowpassDens = smoothdata(sliceDens, 'gaussian', smoothingWindow);

        % remove the lowpass trend
        densDiff = sliceDens - lowpassDens;

        % compute Z-score (filtered)
        zScore = (densDiff - mean(densDiff,'omitnan'))./std(densDiff,'omitnan');

        % compute Z-score (unfiltered)
        unfiltzScore = (sliceDens - mean(sliceDens,'omitnan'))./std(sliceDens,'omitnan');

        % save slice z-score
        sliceZscore{sliceNum} = [depthAx zScore];
    end

    function plotStressBands
        for i = 1:height(SBsummarytable)
            scatter(s7(5).axis(1),SBsummarytable.Depth(i),SBsummarytable.MaxHeight(i)+2.4,100,'vr','filled'); hold(s7(5).axis(1), 'on');
            text(s7(5).axis(1),SBsummarytable.Depth(i)+2,SBsummarytable.MaxHeight(i)+2.4,int2str(SBsummarytable.StressBand(i)));
        end
    end

    function stressBandLikelihood
        % add estimated band year
        temp = zeros(height(SBsummarytable),1);
        if isprop(mfile, 'bandLocs')
            % determine annual band depths
            collectionYear = s7(3).field(1).Value;
            AnnualBandDepth = [[collectionYear:-1:(collectionYear - length(bandCross{sliceNum}) + 1)]' bandCross{sliceNum}];
            
            for i = 1:height(SBsummarytable)
                [~, idx] = min(abs(AnnualBandDepth(:,2) - SBsummarytable.Depth(i)));
                temp(i,1) = AnnualBandDepth(idx,1); % assign year
            end
        else
            temp(:,1) = NaN(height(SBsummarytable),1);
        end
        SBsummarytable.EstYear = temp; 

        % check that no year has multiple stress bands
        processedYears = [];
        newTable = table();

        i = 1;
        while i <= height(SBsummarytable)
            currYear = SBsummarytable.EstYear(i);

            % If this year was already processed, skip it
            if ismember(currYear, processedYears)
                i = i + 1;
                continue;
            end
            % Find all rows with the same year
            idx = SBsummarytable.EstYear == currYear;
            subset = SBsummarytable(idx, :);
            
            % Compute new values based on largest area band
            [~,finalIdx] = max(subset.Area);
            newDepth = subset.Depth(finalIdx);        % Average depth
            newWidth = subset.Width(finalIdx);         % Summed width
            newMaxHeight = subset.MaxHeight(finalIdx); % Maximum height
            newArea = subset.Area(finalIdx);           % Summed area
            newEstYear = currYear;                % Keep the year

            % Append to the new table
            newRow = table(newDepth, newWidth, newMaxHeight, newArea, newEstYear, ...
                'VariableNames', {'Depth', 'Width', 'MaxHeight', 'Area', 'EstYear'});
            newTable = [newTable; newRow];

            % Mark the year as processed
            processedYears = [processedYears; currYear];
            i = i + 1;
        end

        newTable.StressBand = (1:height(newTable))';

        % Reorder columns
        newTable = newTable(:, {'StressBand', 'Depth', 'Width', 'MaxHeight', 'Area', 'EstYear'});

        % Assign back to SBsummarytable
        SBsummarytable = newTable;

        SBsummarytable.Likelihood = zeros(height(SBsummarytable),1);

        % compute stress band likelihood
        for i = 1:height(SBsummarytable)
            % set default to semi-likely
            SBsummarytable.Likelihood(i) = 2;

            % check if any detected bands are close to a user-identified stress band
            if exist("sbCross")
                isClose = any(sbCross{sliceNum} - SBsummarytable.Depth(i) <= 1); % threshold is 1 mm
            else
                isClose = 0;
            end

            % check how many of the highly-likely criteria are true
            numTrue_highlyLikely = (SBsummarytable.MaxHeight(i) >= 1) + (SBsummarytable.Width(i) >= 1) + (SBsummarytable.Area(i) >= 0.5);
            numTrue_unlikely = (SBsummarytable.MaxHeight(i) <= 0.2) + (SBsummarytable.Width(i) <= 0.5) + (SBsummarytable.Area(i) <= 0.3);

            % loop through conditions
            if numTrue_highlyLikely >=2 % at least 2 of 3 conditions are met
                SBsummarytable.Likelihood(i) = 1; % set to highly likely
            elseif numTrue_highlyLikely == 1 & isClose == 1 % one condition is met and is close to user band
                SBsummarytable.Likelihood(i) = 1; % set to highly likely
            elseif numTrue_unlikely >=2 % at least 2 of 3 conditions are met
                SBsummarytable.Likelihood(i) = 3; % set to unlikely
            elseif numTrue_unlikely >=2 & isClose == 1 % at least 2 of 3 conditions are met BUT is close to user band
                SBsummarytable.Likelihood(i) = 2; % set back to semi-likely
            end
        end

        % update the UI table
        summaryTable = table();  % delete table
        data = [];
        data(:,1) = SBsummarytable.StressBand;
        data(:,2) = SBsummarytable.Depth;
        data(:,3) = SBsummarytable.EstYear;
        data(:,4) = SBsummarytable.Likelihood;
        
        summaryTable = array2table(data,'VariableNames',colNames);
        s7(6).table.Data = summaryTable;
        
        % save to output file
        sliceStressBand{sliceNum} = SBsummarytable;
    end


    function collateSBstats
        % initialize variables
        uniqueYear = sliceStressBand{1}.EstYear;
        totSlices = ones(size(uniqueYear));
        sumWeight = sliceStressBand{1}.Likelihood;
        saveWeight = cell(size(uniqueYear));  % Initialize as cell array
        saveWeight(:) = {[]};  % Ensure all cells start empty
        for k = 1:length(uniqueYear)
            saveWeight{k,1} = sliceStressBand{1}.Likelihood(k);
        end

        % loop through remaining slices
        for i = 2:9
            temp = sliceStressBand{i};
            for j = 1:height(temp)
                idx = find(uniqueYear == temp.EstYear(j), 1); % Find index of existing year
                if ~isempty(idx) % Year is already in uniqueYear
                    totSlices(idx) = totSlices(idx) + 1;
                    sumWeight(idx) = sumWeight(idx) + temp.Likelihood(j);
                    saveWeight{idx} = [saveWeight{idx}, temp.Likelihood(j)]; % Append value
                else % Year is unique, add a new entry
                    uniqueYear(end+1,1) = temp.EstYear(j);
                    totSlices(end+1,1) = 1;
                    sumWeight(end+1,1) = temp.Likelihood(j);
                    saveWeight{end+1,1} = temp.Likelihood(j); % Create new cell entry
                end
            end
        end

        % sort by year descending order
        [tempdata(:,1), sortIdx] = sort(uniqueYear,'descend');
        tempdata(:,2) = totSlices(sortIdx);
        tempdata(:,3) = sumWeight(sortIdx);
        meantemp = tempdata(:,3)./tempdata(:,2); % mean sum
        tempdata(:,4) = meantemp(sortIdx);
        medData = cellfun(@median, saveWeight);
        tempdata(:,5) = medData(sortIdx);

        SBstats = table('Size',[height(tempdata) 5],'VariableTypes',["double","string","double","double","double"],'VariableNames', {'Year', 'Likelihood','NumSlices','MedianWeight','MeanWeight'});

        for i = 1:height(tempdata)
            SBstats.Year(i) = tempdata(i,1);
            SBstats.NumSlices(i) = tempdata(i,2);
            SBstats.MedianWeight(i) = tempdata(i,5);
            SBstats.MeanWeight(i) = tempdata(i,4);

            % check how many of the criteria are met for:
            if tempdata(i,2) <= 3 % less than 2 slices
                SBstats.Likelihood(i) = "Not a stress band";
            elseif tempdata(i,2) >= 6 && (tempdata(i,5) <= 2 && tempdata(i,5)>1) || tempdata(i,5) == 1 && tempdata(i,2)==5
                SBstats.Likelihood(i) = "Possible";
            elseif tempdata(i,2) >= 6 && tempdata(i,5) == 1
                SBstats.Likelihood(i) = "**Highly Likely**";
            else
                SBstats.Likelihood(i) = "Unlikely";
            end
        end


    end
end

