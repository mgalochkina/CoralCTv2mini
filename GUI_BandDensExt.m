function [s4,sn] = GUI_BandDensExt(UI,uigrid,mfile)
% created 11/27/23 - Mariya
% last edited 10/5/25 for mini version

    % Screen 4 - Computes density and extension rate based on user's
    % selected bands

    %% Set default parameters
    % for loading data
    metadata = mfile.metadata;
    ReconDims = mfile.ReconDims;
    densitySample = mfile.densitySample;
    densCon = mfile.DensityConversion;
    HU2dens = [densCon.RegressionParameters(2,1) densCon.RegressionParameters(1,1)];
    bandLocs = mfile.bandLocs;
    totBand = height(bandLocs);
    band = cell(totBand,1);
    bandSurf = [];
    Xdims = [size(ReconDims.X,2), size(ReconDims.Y,2), size(ReconDims.Z,2)];
    genera = {'Porites','Montastrea','Siderastrea'}; % coral genus options
    h = []; % filter, depending on coral genera
    collectionYear = 2023;
    estBandYear = zeros(totBand,1);
    % for plotting
    center = bandLocs{1,4}(1,1); % for plotting
    centerCoralVol = cell(totBand,1);
    bandDens = zeros(totBand,1); % for storing band densities
    bandExt = zeros(totBand,1); % for storing band extention rate
    bandMidpoint = zeros(totBand,1); % for storing z-midpoint of band
    bandZcenter = zeros(totBand,1); % for storing z-midpoint of band (in mm)
    BandInfo = [];
    zIdx = []; 
    slabDraw = [];

    %% Panel 1: Process Band Density and Extension Rate
    s4(1).panel = uipanel(uigrid,'Title','1. Process Band Density/Extension');
    s4(1).panel.Layout.Row = [3 22];
    s4(1).panel.Layout.Column = [3 28];

    % Select coral genus
    s4(1).grid = uigridlayout(s4(1).panel,[20 10]);
    s4(1).label(1) = uilabel(s4(1).grid);
    s4(1).label(1).Text = 'Select coral genus';
    s4(1).label(1).FontSize = 14;
    s4(1).label(1).Layout.Column = [1 10];
    s4(1).label(1).Layout.Row = [1 3];

    s4(1).field(1) = uidropdown(s4(1).grid);
    s4(1).field(1).Items = genera;
    s4(1).field(1).FontSize = 14;
    s4(1).field(1).Layout.Column = [11 20];
    s4(1).field(1).Layout.Row = [1 3];

    % Lock in coral genus
    s4(1).button(1) = uibutton(s4(1).grid);
    s4(1).button(1).Text = 'Confirm coral genus';
    s4(1).button(1).Layout.Column = [2 18];
    s4(1).button(1).Layout.Row = [4 7];
    s4(1).button(1).FontSize = 14;

    % Identify core collection year
    s4(1).label(2) = uilabel(s4(1).grid);
    s4(1).label(2).Text = 'Core collection year';
    s4(1).label(2).FontSize = 14;
    s4(1).label(2).Layout.Column = [1 12];
    s4(1).label(2).Layout.Row = [9 11];

    s4(1).field(2) = uieditfield(s4(1).grid,"numeric","Value",collectionYear);
    s4(1).field(2).Layout.Column = [13 20];
    s4(1).field(2).Layout.Row = [9 11];

    % Analyze band density/extension
    s4(1).button(2) = uibutton(s4(1).grid);
    s4(1).button(2).Enable = 'off';
    s4(1).button(2).Text = 'Analyze density/extension';
    s4(1).button(2).Layout.Column = [2 18];
    s4(1).button(2).Layout.Row = [12 15];
    s4(1).button(2).FontSize = 14;    

    %% Panel 2: Plot User Selected Bands
    s4(2).panel = uipanel(uigrid,'Title','2. User Selected Bands');
    s4(2).panel.Layout.Row = [3 80];
    s4(2).panel.Layout.Column = [30 53];
    s4(2).grid = uigridlayout(s4(2).panel,[100 10]);
    s4(2).axis(1) = axes(s4(2).grid);

    %% Panel 3: Plot mean band density
    s4(3).panel = uipanel(uigrid,'Title','3. Mean Band Density');
    s4(3).panel.Layout.Row = [3 80];
    s4(3).panel.Layout.Column = [55 75];
    s4(3).grid = uigridlayout(s4(3).panel,[100 10]);
    s4(3).axis(1) = axes(s4(3).grid);

    %% Panel 4: Plot mean band extension
    s4(4).panel = uipanel(uigrid,'Title','4. Band Extension Rate');
    s4(4).panel.Layout.Row = [3 80];
    s4(4).panel.Layout.Column = [77 97];
    s4(4).grid = uigridlayout(s4(4).panel,[100 10]);
    s4(4).axis(1) = axes(s4(4).grid);

    %% Panel 5: Summary Table
    s4(5).panel = uipanel(uigrid,'Title','5. Summary Table');
    s4(5).panel.Layout.Row = [25 65];
    s4(5).panel.Layout.Column = [3 28];

    % summary data plot
    s4(5).grid = uigridlayout(s4(5).panel,[20 20]);
    s4(5).table(1) = uitable(s4(5).grid);
    s4(5).table.Layout.Column = [1 20];
    s4(5).table.Layout.Row = [1 17];
        colNames = {'Band #', ['Estimated ' newline 'Year'],['Mean ' newline 'Density ' newline '(g/cm^3)'],['Extension ' newline 'Rate ' newline '(mm/yr)']};
        data = {[], [],[],[]};
        t = cell2table(data,'VariableNames',colNames);
    s4(5).table.Data = t;

    % export data as xlsx file
    s4(5).button(1) = uibutton(s4(5).grid);
    s4(5).button(1).Enable = 'off';
    s4(5).button(1).Text = 'Export Data (.xlsx)';
    s4(5).button(1).Layout.Column = [2 18];
    s4(5).button(1).Layout.Row = [18 20];
    s4(5).button(1).FontSize = 14;    


    %% Panel 6: Finish
    s4(6).panel = uipanel(uigrid,'Title','6. Done Analyzing');
    s4(6).panel.Layout.Row = [67 80];
    s4(6).panel.Layout.Column = [3 28];

    % Finish button
    s4(6).grid = uigridlayout(s4(6).panel,[20 10]);
    s4(6).button(1) = uibutton(s4(6).grid,'state');
    s4(6).button(1).Enable = 'off';
    s4(6).button(1).Text = '--> Next';
    s4(6).button(1).Layout.Column = [2 18];
    s4(6).button(1).Layout.Row = [3 8];
    s4(6).button(1).FontSize = 16;   
    s4(6).button(1).FontWeight = 'bold';
    s4(6).button(1).BackgroundColor = [0.9294 0.4627 0.3804];
    

    %% Initialize button call backs and screen variables:
    UpdateCallbacks;

    % wait for user interactions
    waitfor(s4(6).button(1),'Value',true) 

    % save bandlocs to matfile
    mfile.BandInfo = BandInfo;
    mfile.bandSurf = bandSurf;
    save(mfile.Properties.Source, '-append','BandInfo','bandSurf');

    % if resumed, continue to next scene:
    clf(UI)
    sn = 5;

    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function UpdateCallbacks
        % Panel 1 - Set Genus, Collection year, analyze
        s4(1).button(1).ButtonPushedFcn = {@chooseCoreFilter};
        s4(1).button(2).ButtonPushedFcn = {@processUserBands};

        % Panel 5 - Export data as .xlsx file
        s4(5).button(1).ButtonPushedFcn = {@exportSummaryTbl};

    end

    function chooseCoreFilter(src,event)
        % make Choose Genera button unpressable
        s4(1).button(1).Enable = 'off';

        % allow user to begin IDing bands
        s4(1).button(2).Enable = 'on';

        % parse coral genera into relevant filter
        selectedOption = s4(1).field(1).Value;

        switch selectedOption
            case 'Porites'
                h = fspecial('gaussian',10, 1); % Porites filter
            case 'Montastrea'
                h = fspecial('gaussian',25,95); % Montastrea filter
            case 'Siderastrea'
                h = fspecial('gaussian',15, 12); % Sideratrea filter (from Tom's old code! untested)
        end
    end

    function processUserBands(src,event)
        % disable button once it's pressed
        s4(1).button(2).Enable = 'off';

        % set up grid
        % xv = linspace(0, Xdims(1), Xdims(1));
        % yv = linspace(0, Xdims(2), Xdims(2));
        xv = linspace(0, Xdims(1), Xdims(1));
        yv = linspace(0, Xdims(2), Xdims(2));
        [X,Y] = meshgrid(xv,yv);
        Z = cell(totBand,1);
        
        % Create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Processing User Bands');

        % make cell with each band location
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
        
        clear Z
        
        % compute mean density and mean extension rate
        for bandNum = 1:totBand
            % pick out topmost and bottommost cell (Z direction) in a given band
            if bandNum == 1
                %zIdx = (1:floor(max(band{1}(:,3))))+ReconDims.Z(1);
                zIdx = 1:floor(max(band{1}(:,3)));
            else
                %zIdx = (ceil(min(band{bandNum-1}(:,3)))+ReconDims.Z(1):floor(max(band{bandNum}(:,3)))+ReconDims.Z(1))'; 
                zIdx = (ceil(min(band{bandNum-1}(:,3))):floor(max(band{bandNum}(:,3))))';
            end

            % load in the section of core that contains the full band
            %Xsec = double(mfile.Scan(ReconDims.X, ReconDims.Y, ReconDims.Z(zIdx)))*metadata.RescaleSlope + metadata.RescaleIntercept;
            Xsec = double(mfile.Scan(ReconDims.X, ReconDims.Y, zIdx))*metadata.RescaleSlope + metadata.RescaleIntercept;

            % determine what is and isn't core in the scan section
            coralTrue = coralFinder(Xsec);

            % Check whether each gridbox is between the two surfaces
            withinSurfaces = false(size(Xsec));
            for row = 1:size(Xsec,1)
                for col = 1:size(Xsec,2)
                    for hgt = 1:size(Xsec,3)
                        if bandNum == 1
                            if zIdx(hgt) <= bandSurf{bandNum}(row,col)
                                withinSurfaces(row,col,hgt) = true;
                            end
                        else
                            if zIdx(hgt) > bandSurf{bandNum-1}(row,col) && zIdx(hgt) <= bandSurf{bandNum}(row,col)
                                withinSurfaces(row,col,hgt) = true;
                            end
                        end
                    end
                end
            end

            % update progress bar
            pbar.Value = bandNum/totBand;
            if bandNum == totBand
                close(pbar)
            end

            % determine volume of coral within bands
            coralVol = false(size(coralTrue));
            coralVol(coralTrue == 1 & withinSurfaces == 1) = 1;
            bnd = bwboundaries(squeeze(coralVol(center,:,:)));

            for g = length(bnd)
                centerCoralVol{bandNum,g} = bnd{g};
                centerCoralVol{bandNum,g}(:,2) = centerCoralVol{bandNum,g}(:,2)+zIdx(1);
            end

            % determine mean density of coral in a given band
            bandDens(bandNum,:) = mean(Xsec(coralVol==1))*HU2dens(1)+HU2dens(2);

            % determine mean extension rate
            extMat = sum(coralVol,3) * metadata.PixelZSpacing;
            extMat(extMat==0) = NaN; extMat(extMat<prctile(extMat(:),5))=NaN;

            bandExt(bandNum,:) = mean(extMat(:),'omitnan');

            % compute z-midpoint of band
            dimensions = size(coralVol);
            midpoints = zeros(dimensions(1), dimensions(2));

            for i = 1:dimensions(1)
                for j = 1:dimensions(2)
                    % Find indices where the value is 1 along the third dimension
                    indices = find(coralVol(i, j, :));

                    % Calculate the midpoint index
                    midpointIndex = round(mean(indices));

                    % Assign the midpoint index to the corresponding position
                    midpoints(i, j) = midpointIndex;
                end
            end

            bandZcenter(bandNum,:) = zIdx(round(mean(midpoints(:),'omitnan')));
            bandMidpoint(bandNum,:) = zIdx(round(mean(midpoints(:),'omitnan')))* metadata.PixelZSpacing;

        end

        plotSlab

        % estimate year of band

        collectionYear = s4(1).field(2).Value; 
        for i = 1:totBand
            estBandYear(i,1) = collectionYear - (i-1);
        end

        % put info into table
        bandNum = (1:totBand)';

        BandInfo = table(bandNum,estBandYear, bandZcenter, bandMidpoint, bandDens,bandExt);

        % update table with information
        data = [bandNum,estBandYear,bandDens,bandExt];
        t = array2table(data,'VariableNames',colNames);
        s4(5).table.Data = t;

        % turn on the export data + finish buttons
        s4(5).button(1).Enable = 'on';
        s4(6).button(1).Enable = 'on';

        UpdateCallbacks;
    end

    function exportSummaryTbl(src,event)
        % make Export Data button unpressable
        s4(5).button(1).Enable = 'off';

        % export summary table as CSV
        [filename, filepath] = uiputfile('*.xlsx', 'Save band summary table');
        FileName = fullfile(filepath, filename);
        writetable(s4(5).table.Data,FileName,'Sheet',1,'Range','A1');
    end

%% %%%%%%%%%%%%% OTHER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function plotSlab

        % pull out only the section for which bands have been IDed
        Xn = double(mfile.Scan(ReconDims.X,ReconDims.Y,(1:zIdx(end))))*metadata.RescaleSlope + metadata.RescaleIntercept;

        % select a 3mm thick slab from the center
        thick = round(3/metadata.PixelSpacing/2); % 3mm thick slab in pixels
        slabDraw = permute(squeeze(mean(Xn(center-thick:center+thick,:,:),1)),[2 1 3]);
        
        % clear the axis before updating
        if isfield(s4(2), 'axis') && isvalid(s4(2).axis(1))
            cla(s4(2).axis(1), 'reset');
        else
            s4(2).axis(1) = axes(s4(2).grid);
        end

        s4(2).axis.NextPlot = 'add';

        % plot the slab        
        hold(s4(2).axis(1),'on');
        imagesc(s4(2).axis(1),[1, size(Xn,2)*metadata.PixelSpacing], [1, size(Xn,3)*metadata.PixelZSpacing], slabDraw);
        s4(2).axis(1).YLabel.String = 'Distance Down Core (mm)';
        s4(2).axis(1).YLabel.FontSize = 14;
        s4(2).axis(1).Layout.Column = [1 10];
        s4(2).axis(1).Layout.Row = [1 70];
        s4(2).axis(1).XTick = [];
        colormap(s4(2).axis(1),'bone')
        ylim(s4(2).axis(1), [1 max(size(slabDraw,1))].*metadata.PixelSpacing(1))
        xlim(s4(2).axis(1), [1 max(size(slabDraw,2))].*metadata.PixelSpacing(1))
        s4(2).axis(1).YDir = 'Reverse';

        % plot the volume of core detected for each band
        colors = {'r';'y';'g';'b';'m';'c'};
        
        if size(centerCoralVol, 2) >= 2
            for i = 1:size(centerCoralVol, 1)
                % Check if the second column of the current cell is non-empty
                if ~isempty(centerCoralVol{i, 2})
                    % Swap the contents of the first and second columns
                    temp = centerCoralVol{i, 1};
                    centerCoralVol{i, 1} = centerCoralVol{i, 2};
                    centerCoralVol{i, 2} = temp;
                end
            end
        end

        for i = 1:totBand
            fill(s4(2).axis(1),centerCoralVol{i,1}(:,1)*metadata.PixelSpacing, centerCoralVol{i,1}(:,2)*metadata.PixelZSpacing,colors{mod(i,size(colors,1))+1},'FaceAlpha','0.1', 'EdgeColor','none');
        end

        % plot the user selected bands + band numbers
        for i = 1:totBand
            plot(s4(2).axis(1), bandLocs{i,4}(:,2)*metadata.PixelSpacing, bandLocs{i,4}(:,3)*metadata.PixelZSpacing,'-ow','LineWidth',2)
            text(s4(2).axis(1), (bandLocs{i,4}(1,2)-15)*metadata.PixelSpacing, (bandLocs{i,4}(1,3)-20)*metadata.PixelZSpacing,int2str(i),'FontSize',12,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'white');
        end

        plotBandDens
        plotBandExt

    end

    function plotBandDens

        % clear the axis before updating
        if isfield(s4(3), 'axis') && isvalid(s4(3).axis(1))
            cla(s4(3).axis(1), 'reset');
        else
            s4(3).axis(1) = axes(s4(3).grid);
        end

        s4(3).axis.NextPlot = 'add';

        hold(s4(3).axis(1),'on');
        s4(3).axis(1).Layout.Column = [1 10];
        s4(3).axis(1).Layout.Row = [1 70];
        s4(3).axis(1).FontSize = 12;
        s4(3).axis(1).YLabel.String = 'Distance Down Core (mm)';
        s4(3).axis(1).YLabel.FontSize = 14;
        s4(3).axis(1).XLabel.String = 'Mean Band Density (g/cm^{3})';
        s4(3).axis(1).XLabel.FontSize = 14;
        s4(3).axis(1).XGrid = 'on'; s4(3).axis(1).XMinorGrid = 'on';
        s4(3).axis(1).YGrid = 'on'; s4(3).axis(1).YMinorGrid = 'on';
        s4(3).axis(1).GridLineWidth = 0.5;
        b = plot(s4(3).axis, bandDens, bandMidpoint,'-o','LineWidth',2); hold on
        b.MarkerFaceColor = "#D95319"; b.MarkerSize = 10;
        b.Color = "#D95319";
        ylim(s4(3).axis(1), [1 max(size(slabDraw,1))].*metadata.PixelSpacing(1))
        xlim(s4(3).axis(1),[min(bandDens)*0.95 max(bandDens)*1.05])
        %s4(3).axis(1).XAxisLocation = 'Top';
        axis(s4(3).axis(1), 'ij');
        ylim(s4(2).axis(1), [1 max(size(slabDraw,1))].*metadata.PixelSpacing(1))

        for i = 1:totBand
            text(s4(3).axis(1), bandDens(i)-(max(bandDens)*1.05 - min(bandDens)*0.95)*0.07, bandMidpoint(i),int2str(i),'FontSize',14,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'k');
        end
        
    end

    function plotBandExt

        % clear the axis before updating
        if isfield(s4(4), 'axis') && isvalid(s4(4).axis(1))
            cla(s4(4).axis(1), 'reset');
        else
            s4(4).axis(1) = axes(s4(4).grid);
        end

        s4(4).axis.NextPlot = 'add';

        hold(s4(4).axis(1),'on');
        s4(4).axis(1).Layout.Column = [1 10];
        s4(4).axis(1).Layout.Row = [1 70];
        s4(4).axis(1).FontSize = 12;
        s4(4).axis(1).YLabel.String = 'Distance Down Core (mm)';
        s4(4).axis(1).YLabel.FontSize = 14;
        s4(4).axis(1).XLabel.String = 'Mean Band Extension (mm/yr)';
        s4(4).axis(1).XLabel.FontSize = 14;
        s4(4).axis(1).XGrid = 'on'; s4(4).axis(1).XMinorGrid = 'on';
        s4(4).axis(1).YGrid = 'on'; s4(4).axis(1).YMinorGrid = 'on';
        s4(4).axis(1).GridLineWidth = 0.5;
        b = plot(s4(4).axis, bandExt, bandMidpoint,'-o','LineWidth',2); hold on
        b.MarkerFaceColor = "#2a567d"; b.MarkerSize = 10;
        b.Color = "#2a567d";
        ylim(s4(4).axis(1), [1 max(size(slabDraw,1))].*metadata.PixelSpacing(1))
        xlim(s4(4).axis(1),[min(bandExt)*0.9 max(bandExt)*1.1])
        %s4(4).axis(1).XAxisLocation = 'Top';
        axis(s4(4).axis(1), 'ij');
        ylim(s4(2).axis(1), [1 max(size(slabDraw,1))].*metadata.PixelSpacing(1))

        for i = 1:totBand
            text(s4(4).axis(1), bandExt(i)-(max(bandExt)*1.1-min(bandExt)*0.9)*.07, bandMidpoint(i),int2str(i),'FontSize',14,'FontWeight', 'bold', 'HorizontalAlignment', 'right', 'Color', 'k');
        end

    end

     function coralTrue = coralFinder(X)
        % takes in previously sampled middle of core's density. This will prevent us from having to load
        % the whole core into memory. 
        
        coralTrue = logical(zeros(size(X)));
        layers = size(X,3);
        
        for i = 1:layers
            Xsamp = X(:,:,i); % sample core
            filteredXcore(:,:) = imfilter(X(:,:,i), h);
            %level = graythresh(filteredXcore);
            %coral(:,:,i) = imbinarize(filteredXcore,level);
            coralTrue(:,:,i) = imbinarize(filteredXcore,0.3); % this value seems to work
            dens = mean(Xsamp(coralTrue(:,:,i)==1)); % compute density of identified coral
        
            if dens < densitySample*0.2 % make sure you aren't capturing the random sampling halo as core
                coralTrue(:,:,i) = zeros(size(filteredXcore));
            end
        end
    
    end


end

