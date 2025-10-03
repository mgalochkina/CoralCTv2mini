
function [sn,mfile] = GUI_StandardCurve(UI,uigrid,mfile)
% created 4/25/25 - Mariya
% last edited 10/3/25 for mini version
% deals with CoralPixelDistribution errors for Montastrea

    % Screen 2 - Standard curve and whole core density:

    ReconDims = mfile.ReconDims;
    Sigma = 0.1;

    % Panel 1 - load standards
    s2(1).panel = uipanel(uigrid,'Title','1. Load Standards');
    s2(1).panel.Layout.Row = [3 53];
    s2(1).panel.Layout.Column = [3 25];
    s2(1).panel.FontSize = 16;
    
    s2(1).grid = uigridlayout(s2(1).panel,[52 10]);
    s2(1).button(1) = uibutton(s2(1).grid);
    s2(1).button(1).Text = 'Load Standard Directory';
    s2(1).button(1).Layout.Column = [1 10];
    s2(1).button(1).Layout.Row = [1 4];
    
    s2(1).table(1) = uitable(s2(1).grid);
    s2(1).table.Layout.Column = [1 10];
    s2(1).table.Layout.Row = [5 16];
        vars = ["Standard name","Date","Density"];
        data = {[], [],[]};
        t = cell2table(data,'VariableNames',vars);
    s2(1).table.Data = t;

    % Panel 2 - Calibrate Core Detection
    s2(2).panel = uipanel(uigrid,'Title','2. Calibrate Core Detection');
    s2(2).panel.Layout.Row = [54 80];
    s2(2).panel.Layout.Column = [3 25];
    s2(2).panel.FontSize = 16;

    s2(2).grid = uigridlayout(s2(2).panel,[10 10]);

    s2(2).cbx(1) = uicheckbox(s2(2).grid,"Text","Montastrea core");
    s2(2).cbx(1).Layout.Column = [1 12];
    s2(2).cbx(1).Layout.Row = [7 8];

    s2(2).field(1) = uieditfield(s2(2).grid,'numeric','Value',Sigma,'Tag','fsize');
    s2(2).field(1).Layout.Column = [1 3];
    s2(2).field(1).Layout.Row = [9 10];

    s2(2).button(1) = uibutton(s2(2).grid);
    s2(2).button(1).Text = 'Set detection threshold';
    s2(2).button(1).Layout.Column = [4 10];
    s2(2).button(1).Layout.Row = [9 10];
    s2(2).button(1).FontSize = 14;

    % Panel 3 - forward/backward
    % s2(3).panel = uipanel(uigrid);
    % s2(3).panel.Layout.Row = [75 80];
    % s2(3).panel.Layout.Column = [3 25];
    % s2(3).panel.FontSize = 16;
    % s2(3).grid = uigridlayout(s2(3).panel,[10 10]);
    % 
    % s2(3).button(1) = uibutton(s2(3).grid,'state');
    % s2(3).button(1).Text = '<<Back';
    % s2(3).button(1).FontSize = 18;
    % s2(3).button(1).Layout.Column = [4 7];
    % s2(3).button(1).Layout.Row = [1 4];
    % s2(3).button(1).BackgroundColor = 'r';
    % s2(3).button(1).FontColor = 'w';

    % Panel 4 - Core X-Section
    s2(4).panel = uipanel(uigrid,'Title','4. Core X-Section');
    s2(4).panel.Layout.Row = [3 80];
    s2(4).panel.Layout.Column = [30 60];
    s2(4).panel.FontSize = 16;
    s2(4).grid = uigridlayout(s2(4).panel,[100 10]);

    s2(4).button(1) = uibutton(s2(4).grid,'state');
    %s2(4).button(1).Value = true;
    s2(4).button(1).Text = 'Identify Bands';    
    s2(4).button(1).Layout.Column = [2 9];
    s2(4).button(1).Layout.Row = [65 70];
    s2(4).button(1).FontSize = 16;
    s2(4).button(1).BackgroundColor = 'r';
    s2(4).button(1).FontColor = 'w';

    % Panel 5 - Whole core density plot
    s2(5).panel = uipanel(uigrid,'Title','5. Whole Core Density');
    s2(5).panel.Layout.Row = [3 80];
    s2(5).panel.Layout.Column = [65 90];
    s2(5).panel.FontSize = 16;
    s2(5).grid = uigridlayout(s2(5).panel,[100 10]);
    
    s2(5).button(1) = uibutton(s2(5).grid);
    s2(5).button(1).Text = 'Calculate Whole Core Density';
    s2(5).button(1).FontSize = 16;
    s2(5).button(1).Layout.Column = [2 9];
    s2(5).button(1).Layout.Row = [65 70];
    
    % Set font parameters in each panel:
    for i = 1:length(s2)
        try
        [s2(i).panel.FontSize] = deal(16);
        [s2(i).button(:).FontSize] = deal(14);
        %[s2(i).label(:).FontSize] = deal(14);
        [s2(i).label(:).WordWrap] = deal('on');
        catch; end
    end

    %%  Initialize persistent variables
    StandardsSub = [];
    WCD = [];
    metadata = mfile.metadata;
    CoralPixelDistribution = [];
    Xsec = []; Ysec = [];
    BoundaryHandle1 = []; BoundaryHandle2 = [];

    % Initialize Callbacks
    UpdateCallbacks

    % wait for user interactions (set default to back)
    %sn = 1;
    waitfor(s2(4).button(1),'Value',true)

    variableInfo = who(mfile);

    if ~ismember('CoralPixelDistribution',variableInfo) && isempty(CoralPixelDistribution)
        uialert(UI,'Detection Threshold not saved. Please set the detection threshold before proceeding.','Unsaved Detection Threshold')
        s2(4).button(1).Value = false;
    elseif ismember('CoralPixelDistribution',variableInfo) || ~isempty(CoralPixelDistribution)
        s2(4).button(1).Value = true;
        sn = 3;
        mfile.CoralPixelDistribution = CoralPixelDistribution;
        save(mfile.Properties.Source, '-append','CoralPixelDistribution');

        clf(UI)
    end



%% %%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Function to define/update callbacks
    function UpdateCallbacks
        s2(1).button(1).ButtonPushedFcn = {@ChooseStandards};
        s2(2).button(1).ButtonPushedFcn = {@GetCoralDistribution};
        %s2(4).button(1).ButtonPushedFcn = {@GoNext};
        s2(5).button(1).ButtonPushedFcn = {@WholeCoreDensity};

        s2(2).field(1).ValueChangedFcn = {@(numfld,event) numberChanged(s2(2).field(1))};
    end

    % Function to read in standard file and choose most relevant standards
    function ChooseStandards(src,event)

        % Find standard directory. If none exists, create one:
        [filename, filepath] = uigetfile('*.mat', 'Select master standard directory');
        drawnow; figure(UI)
        FileName = fullfile(filepath, filename);
        mdir = matfile(FileName,'Writable',true);

        % Compare standard list to date of scan in mfile:
        Standards = mdir.StandardInfo;
        stdRows = find(year(Standards.ScanDate)==year(mfile.ScanDate) & month(Standards.ScanDate)== ...
            month(mfile.ScanDate) & day(Standards.ScanDate)==day(mfile.ScanDate));
        if isempty(stdRows)
            uialert(UI,'No standards listed for the date of this scan. Using nearest.','missing standards')
            closestDate = Standards.ScanDate(knnsearch(datenum(Standards.ScanDate),datenum(mfile.ScanDate)));
            stdRows = find(Standards.ScanDate==closestDate);
            StandardsSub = Standards(stdRows,:);
        else
            StandardsSub = Standards(stdRows,:);
        end

        % Look up density values for standards:
        %StandardDensities = readmatrix('Standard_Densities_Original.xlsx');
        StandardDensities = [269 0.8095; 270 0.9927; 225 1.0887; 167 1.1655; 237 1.3550; ...
            220 1.2794; 214 1.3862; 221 1.5374; 235 1.3221];

        % Assign each measured density to the table if the standard has not been used before:
        isAssigned = false(size(StandardsSub,1));
        % for j = 1:size(StandardsSub,1)
        %     % If the Density variable has been added to the table (1st time only) AND Density is a NaN:
        %     if any(~isnan(Standards.Density))
        %         %if any("Density" == string(Standards.Properties.VariableNames))
        %         if StandardsSub.Density(j) == 0
        %             StandardsSub.Density(j) = StandardDensities(StandardDensities(:,1)==str2double(StandardsSub.CoreID(j)),2);
        %             isAssigned(j) = true;
        %         else
        %             % Density is already defined
        %         end
        %     else
        %         % First time setup - Density column has not yet been added to table.
        %         StandardsSub.Density(j) = StandardDensities(StandardDensities(:,1)==str2double(StandardsSub.CoreID(j)),2);
        %         isAssigned(j) = true;
        %     end
        % end

        for j = 1:size(StandardsSub, 1)
            if ~any(ismember(StandardsSub.Properties.VariableNames, 'Density')) || any(isnan(StandardsSub.Density))
                % First time setup - Density column has not yet been added to table.
                StandardsSub.Density(j) = StandardDensities(StandardDensities(:, 1) == str2double(StandardsSub.CoreID(j)), 2);
                isAssigned(j) = true;
            else
                % If the Density variable has been added to the table (1st time only) AND Density is a NaN:
                if ismember('Density', StandardsSub.Properties.VariableNames) && StandardsSub.Density(j) == 0
                    StandardsSub.Density(j) = StandardDensities(StandardDensities(:, 1) == str2double(StandardsSub.CoreID(j)), 2);
                    isAssigned(j) = true;
                else
                    % Density is already defined or Density column doesn't exist
                end
            end
        end

        % Update table to have info:
        s2(1).table.Data = StandardsSub;

        % Read Standard Scans:
        ids = find(isAssigned);
        ReadStandards(ids);

        % Save density and HU back to the directory file:
        Standards.Density(stdRows) = StandardsSub.Density;
        Standards.ScanMeans(stdRows) = StandardsSub.ScanMeans;        
        mdir.StandardInfo = Standards;

        % Plot standard curve:
        PlotStandards;

        % Plot Core based on standards:
        PlotCore;
    end

    % Function to parse go next behavior
    % function GoNext(src,event)
    % 
    %     variableInfo = who(mfile);
    % 
    %     % Prompt user to identify detection threshold if none exists
    %     if ismember('CoralPixelDistribution',variableInfo) && ~isempty(mfile.CoralPixelDistribution)
    %         s2(3).button(1).Value = true;
    %         sn = 3;
    %         mfile.CoralPixelDistribution = CoralPixelDistribution;
    %     else
    %         output = uiconfirm(UI,"Detection Threshold not saved. Save the current threshold?",'No Detection Threshold',"Options",["Save Current","Go Back"],'DefaultOption',1,'CancelOption',2);
    %     end
    % 
    %     switch output
    %         case "Save Current"
    %             % wait triggers based on value for button 3, use as dummy
    %             s2(3).button(1).Value = true;
    %             sn = 3;
    %             mfile.CoralPixelDistribution = CoralPixelDistribution;
    %         case "Go Back"
    %             return
    %     end
    % end

    % Function to read .mat files standards are stored in, and calculate whole-core HU
    function ReadStandards(ids)
        
        % Create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Loading Standards with no saved density');  

        for j = 1:length(ids)
            
            % Read matfile for each standard
            mstd = matfile(StandardsSub.Path(ids(j)));
            ReconDimsStd = mstd.ReconDims;
            metadatastd = mstd.metadata;
            Slice = []; FilteredSlice = []; isCoral = []; HU = []; level = [];

            voxSum = 0; HUSum = 0;

            for k = 1:size(mstd.Scan,3)

                Slice = double(mstd.Scan(ReconDimsStd.X,ReconDimsStd.Y,ReconDimsStd.Z(k)))*metadatastd.RescaleSlope + metadatastd.RescaleIntercept;

                % Filter each slice of core
                FilteredSlice(:,:) = imfilter(Slice, fspecial('gaussian',10, 1));
                level = graythresh(FilteredSlice);
                isCoral = imbinarize(FilteredSlice,level);
                HU = FilteredSlice(isCoral);

                voxSum = voxSum + sum(isCoral,'all');
                HUSum = HUSum + sum(HU,'all');
            end

            % Calculate scan mean HU value by dividing HUSum by voxSum:
            StandardsSub.ScanMeans(j,1) = HUSum/voxSum;

            % update progress bar
            pbar.Value = j/size(StandardsSub,1);
            if j == size(StandardsSub,1)
                close(pbar)
            end 
        end

        % Refresh Table:
        s2(1).table.Data = StandardsSub;
    end

    % Function to plot standards
    function PlotStandards
            
        % Plot standard curve
        s2(1).axis(1) = axes(s2(1).grid);
        s2(1).axis(1).YLabel.String = 'Intensity (HU)';
        s2(1).axis(1).XLabel.String = 'Density (g/cm^3)';
        s2(1).axis(1).Layout.Column = [1 10];
        s2(1).axis(1).Layout.Row = [21 42];
        hold(s2(1).axis(1),'on')

        % Plot standards
        plot(s2(1).axis(1),StandardsSub.Density,StandardsSub.ScanMeans,'ok')

        % Fit linear regression
        stats = regstats(StandardsSub.ScanMeans,StandardsSub.Density,'linear',{'rsquare','beta','covb'});
        % Calculate slope and intercept + uncertainty after inversion:
        stats.beta_inv = [(-stats.beta(1)/stats.beta(2)); 1/stats.beta(2)];
        stats.beta_invE = [(sqrt(stats.covb(1,1))/stats.beta(2)); 1/sqrt(stats.covb(2,2))]; % Check if this makes sense
       
        % Plot regression line (variables are swapped due to inversion):
        y = linspace(min(StandardsSub.ScanMeans).*0.8,max(StandardsSub.ScanMeans).*1.2,10);
        xhat = y.*stats.beta_inv(2)+stats.beta_inv(1);
        plot(s2(1).axis(1),xhat,y,'-r')
        hold(s2(1).axis(1),'off')

        % Save to core matfile: 
        DensityConversion.RegressionParameters = [stats.beta_inv stats.beta_invE];
        DensityConversion.StandardsUsed = StandardsSub.CoreID;
        mfile.DensityConversion = DensityConversion;
        save(mfile.Properties.Source, '-append','DensityConversion');

        % Display equation
        s2(1).subpanel(1) = uipanel(s2(1).grid);
        s2(1).subpanel(1).Layout.Row = [43 48];
        s2(1).subpanel(1).Layout.Column = [1 10];
            s2(1).subgrid(1) = uigridlayout(s2(1).subpanel(1),[2 10]);
            s2(1).sublabel(1) = uilabel(s2(1).subgrid(1));
            s2(1).sublabel(1).Text = ['Density (g/cm^3) = ',num2str(stats.beta_inv(2)),'* HU + ',num2str(stats.beta_inv(1))];
            s2(1).sublabel(1).FontSize = 14;
            s2(1).sublabel(1).Layout.Row = [1 2];
            s2(1).sublabel(1).Layout.Column = [1 10];

        % Put button to revise standards
        s2(1).button(2) = uibutton(s2(1).grid);
        s2(1).button(2).Text = 'Remove Standard...';
        s2(1).button(2).Layout.Column = [1 10];
        s2(1).button(2).Layout.Row = [17 20];
        s2(1).button(2).ButtonPushedFcn = {@RemoveStandard};
    end

    % Function to remove a standard from the curve
        function RemoveStandard(src,event)
    
            % Create second axis on top, copy over points (prohibits user from selecting line instead of points):
            s2(1).axis(2) = s2(1).axis(1);
            s2(1).axis(2).Color = 'none';
            points = copyobj(s2(1).axis(1).Children(2),s2(1).axis(2));
            points.MarkerEdgeColor = 'r';
            points.MarkerFaceColor = 'r';
    
            % Turn on select data in plot
            dcm = datacursormode(UI);
            %dcm = datacursormode(s2(1).axis(1));
            dcm.Enable = 'on';
            dcm.UpdateFcn = {@DeletePoints,points};
    
            % Once clicked, remove selection from Standards and run plot data again
            function StandardName = DeletePoints(~,info,points)
                % Find x in point data:
                x = info.Position(1);
                n = find(points.XData == x);
                StandardName = Standards.CoreID(n);
    
                selection = uiconfirm(UI,'Remove standard from curve?','Confirm Deletion','Icon','warning');
                switch selection
                    case 'OK'
                        dcm.Enable = 'off';
                        % Remove standard from persistent variable:
                        Standards(n,:) = [];
                        % Update UI table to have standards:
                        s2(1).table.Data = Standards;
                        % Re-plot:
                        PlotStandards
                        delete(s2(1).axis(2))
                    case 'Cancel'
                        delete(s2(1).axis(2))
                        return
                end
            end
        end

    % Function to plot slices through core
    function PlotCore
        
        DensityConversion = mfile.DensityConversion;

        % Extract X-slice:
        Xsec = double(squeeze(mfile.Scan(round(median(ReconDims.X)),ReconDims.Y,ReconDims.Z)))';
        XsecD = Xsec.*metadata.RescaleSlope + metadata.RescaleIntercept;

        % Apply conversions:
        XsecD = XsecD.*DensityConversion.RegressionParameters(2,1) + DensityConversion.RegressionParameters(1,1);
        
        % Plot X-slice:
        s2(4).axis(1) = axes(s2(4).grid);   
        hold(s2(4).axis(1),'on')
        s2(4).axis(1).YLabel.String = 'Distance Down Image (mm)';
        s2(4).axis(1).YLabel.FontSize = 12;
        s2(4).axis(1).Layout.Column = [1 5];
        s2(4).axis(1).Layout.Row = [1 70];
        s2(4).axis(1).XTick = [];
        imXsec = repmat(mat2gray(XsecD),[1 1 3]);
        image(s2(4).axis(1),'XData',ReconDims.Y.*metadata.PixelSpacing(1),'YData',ReconDims.Z*metadata.PixelZSpacing(1),'CData',imXsec)
%         imshow(s2(4).axis(1),ReconDims.Y.*metadata.PixelSpacing(1), ReconDims.Z*metadata.PixelZSpacing(1),rgbxsec); hold on 
%         imagesc(s2(4).axis(1), ReconDims.Y.*metadata.PixelSpacing(1), ReconDims.Z*metadata.PixelZSpacing(1), Xsec);
%         colormap(s2(4).axis(1),'bone')
%         c = colorbar(s2(4).axis(1));
%         c.Label.String = 'Density (g/cm^3)';
        xlim(s2(4).axis(1), [min(ReconDims.Y) max(ReconDims.Y)].*metadata.PixelSpacing(1))
        axis(s2(4).axis(1),'image')
        s2(4).axis(1).YDir = 'Reverse';
        hold(s2(4).axis(1),'off')

        % Extract Y-slice:
        Ysec = double(squeeze(mfile.Scan(ReconDims.X,round(median(ReconDims.Y)),ReconDims.Z)))';
        YsecD = Ysec.*metadata.RescaleSlope + metadata.RescaleIntercept;

        % Apply conversions:
        YsecD = YsecD.*DensityConversion.RegressionParameters(2,1) + DensityConversion.RegressionParameters(1,1);
        
        % Plot Y-slice:
        s2(4).axis(2) = axes(s2(4).grid);   
        hold(s2(4).axis(2),'on')
        s2(4).axis(2).YLabel.FontSize = 12;
        s2(4).axis(2).Layout.Column = [6 10];
        s2(4).axis(2).Layout.Row = [1 70];
        s2(4).axis(2).XTick = [];
        s2(4).axis(2).YTick = [];
        imYsec = repmat(mat2gray(YsecD),[1 1 3]);
        image(s2(4).axis(2),'XData',ReconDims.Y.*metadata.PixelSpacing(1),'YData',ReconDims.Z*metadata.PixelZSpacing(1),'CData',imYsec)
        xlim(s2(4).axis(2), [min(ReconDims.Y) max(ReconDims.Y)].*metadata.PixelSpacing(1))
        axis(s2(4).axis(2),'image')
        s2(4).axis(2).YDir = 'Reverse';
        hold(s2(4).axis(2),'off')
    end

    function GetCoralDistribution(src,event)
        
        % Read Core chuncks, save distribution:
        ChunkEdges = ReconDims.Z(1)-1:100:ReconDims.Z(end);
        for k = 1:length(ChunkEdges)-1
            %Chunk = mfile.Scan(ReconDims.X,ReconDims.Y,ReconDims.Z(ChunkEdges(k)+1:ChunkEdges(k+1)));
            Chunk = mfile.Scan(ReconDims.X,ReconDims.Y,(ChunkEdges(k)+1:ChunkEdges(k+1)));
            if k == 1
                % Allow bins to be set in first iteration
                [~,bins] = histcounts(mfile.Scan(:,floor(size(mfile.Scan,2)/2),:),120);
                [counts] = histcounts(Chunk(:),bins);
            else
                [tempcounts] = histcounts(Chunk(:),bins);
                counts = counts+tempcounts;
            end
        end

        % Get bin centers:
        centers = bins(2:end)-mean(diff(bins))/2;

        % remove any bin with more than 10% of the counts (these are empty space)
        ids = counts/sum(counts) < 0.1;
        counts = interp1(centers(ids),counts(ids),centers);

        % remove counts with NaNs
        ids = isnan(counts);
        counts(ids) = []; centers(ids) = [];

        % normalize counts
        counts_norm = counts / max(counts);

        % Create Plot:
        if ~isempty(s2(2).axis)
            delete(s2(2).axis(1))
        end

        s2(2).axis(1) = axes(s2(2).grid);
        hold(s2(1).axis(1),'off')
        s2(2).axis(1).Layout.Column = [1 10];
        s2(2).axis(1).Layout.Row = [1 6];
        s2(2).axis(1);

        % Plot histogram of counts:
        b  = bar(s2(2).axis(1),centers,counts_norm,'hist'); hold(s2(2).axis(1),'on')
        b.EdgeColor = 'None';
        b.FaceColor = [200 200 200]./255;
        s2(2).axis(1).YTick = [];
        s2(2).axis(1).XLim = [0 max(centers)];
        s2(2).axis(1).YLim = [0 max(counts_norm).*1.1];

        % Set counts in first bin to 1 for peak identification:
        %counts(1) = 1;
        
        %Peaks must be at least 3 bins apart, and 1/1000 the number of total pixels:
        [peakvals,peaklocs] = findpeaks(counts_norm,centers,...%'MinPeakDistance',mean(diff(bins)).*3,...
                                                       'MinPeakHeight',sum(counts_norm)./1e3,...
                                                       'MinPeakProminence',sum(counts_norm)./1e4);

        % function MSE = minSig(Sigma)
        %     sigma0 = repmat(Sigma,1,numel(peaklocs));
        %     b0 = [peakvals./sum(peakvals).*sum(counts_norm)
        %           log(peaklocs)-sigma0.^2;
        %           %repmat(sigma0,1,length(peaklocs))];
        %           sigma0];
        %     b0 = reshape(b0,[],1);
        %     options = statset('RobustWgtFun',[]);
        %     [beta,R,J,COVB,MSE] = nlinfit(centers',counts_norm',@(b,x)nlognfit(b,x),b0,options);
        % end
        % 
        % function MSE = minSig2(Sigma)
        %     b0 = [peakvals./sum(peakvals).*sum(counts_norm)
        %         log(peaklocs) - Sigma.^2;
        %         Sigma];
        %     b0 = reshape(b0,[],1);
        %     options = statset('RobustWgtFun',[]);
        %     [beta,R,J,COVB,MSE] = nlinfit(centers', counts_norm', @(b,x)nlognfit(b,x), b0, options);
        % end

        % find best starting value:
        if s2(2).cbx(1).Value == 1 % Montastrea core
            Sigma0 = Sigma * ones(1, numel(peaklocs));
            %Sigma = fminsearch(@minSig2,Sigma0);
            Sigma = fminsearch(@(Sigma) minSig2(Sigma, peaklocs, peakvals, centers, counts_norm), Sigma0);
            sigma0 = Sigma(:);  % ensure column vector

            b0 = [ (peakvals(:)./sum(peakvals).*sum(counts_norm))      % amplitude
                (log(peaklocs(:)) - sigma0.^2)                 % mu
                sigma0 ];
        else
            %Sigma = fminsearch(@minSig,Sigma);
            Sigma = fminsearch(@(Sigma) minSig(Sigma, peaklocs, peakvals, centers,counts_norm), Sigma);

            sigma0 = repmat(Sigma,1,numel(peaklocs));
            b0 = [peakvals./sum(peakvals).*sum(counts_norm)
                log(peaklocs)-sigma0.^2;
                %repmat(sigma0,1,length(peaklocs))];
                sigma0];
        end

        b0 = reshape(b0,[],1);
        options = statset('RobustWgtFun',[]);
        [beta,R,J,COVB,MSE] = nlinfit(centers',counts_norm',@(b,x)nlognfit(b,x),b0,options);
        beta = reshape(beta,3,[]);

        y=[];
        for k=1:numel(peaklocs)
            y(:,k) = nlognfit(beta(:,k),centers');
            p(k) = plot(s2(2).axis(1),centers,y(:,k),'linewidth',1);
        end

        % Find right most peak by default (could change to user defined later):
        fitpeaklocs = exp(beta(2,:)-beta(3,:).^2);
        [~,id] = min(abs(fitpeaklocs-peaklocs(end)));

        % Reset plot height based on id'd peak:
        s2(2).axis(1).YLim = [0 peakvals(end).*1.5];

        % Based on the model, the standard deviation is s = c/sqrt(2) for each gaussian:
        CoralPixelDistribution = beta(:,id);
        
        % Plot theshold boundary
        PlotBoundary;

        UpdateCallbacks;
    end

    function WholeCoreDensity(src,event)

        DensityConversion = mfile.DensityConversion;

        % Plot core density to second graph
        s2(5).axis(1) = axes(s2(5).grid);
        s2(5).axis(1).YLabel.String = 'Distance Down Image (mm)';
        s2(5).axis(1).YLabel.FontSize = 12;
        s2(5).axis(1).XLabel.String = 'Density (g/cm^3)';
        s2(5).axis(1).XLabel.FontSize = 12;
        s2(5).axis(1).Layout.Column = [1 10];
        s2(5).axis(1).Layout.Row = [1 70];
        s2(5).axis(1).XAxisLocation = 'Top';
        s2(5).axis(1).YDir = 'Reverse';
        hold(s2(5).axis(1),'on')

        drawnow

        WCD = zeros(size(ReconDims.Z,2),2);

        % Create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Calculating whole core density');

        count = 1;
        for j = ReconDims.Z(1):ReconDims.Z(end)
            % Apply conversions:
            Slice = double(mfile.Scan(ReconDims.X,ReconDims.Y,j));


            %ppct = 0.05;


            % Apply CoreFilter to determine what is core in each slice
            %IsCore = CoreFilter(Slice,CoralPixelDistribution);
            IsCore = CoreFilter2(Slice,CoralPixelDistribution, mfile.metadata, mfile.densitySample);


            SliceMean = mean(Slice(IsCore),'all')*metadata.RescaleSlope + metadata.RescaleIntercept;
            % update progress bar
            pbar.Value = count/length(ReconDims.Z);
            if j == ReconDims.Z(end)
                close(pbar)
            end 

            % pinc = floor(size(ReconDims.Z,2)*ppct);
            % if mod(count,pinc) == 0
            %     pbar.Value = min(pbar.Value + ppct,1);
            % elseif j == ReconDims.Z(end)
            %     close(pbar)
            % end

            % parse to WCD
            WCD(count,1) = ReconDims.Z(count) * metadata.PixelZSpacing;
            WCD(count,2) = SliceMean*DensityConversion.RegressionParameters(2,1) + DensityConversion.RegressionParameters(1,1);
            count = count+1;


        end

        plot(s2(5).axis(1),WCD(:,2),WCD(:,1))
        ylim(s2(5).axis(1), [min(ReconDims.Z) max(ReconDims.Z)].*metadata.PixelZSpacing(1))
        s2(5).axis(1).XGrid = 'on'; s2(5).axis(1).XMinorGrid = 'on';
        s2(5).axis(1).YGrid = 'on'; s2(5).axis(1).YMinorGrid = 'on';
        hold(s2(5).axis(1),'off')

        % Save HCD to core:
        mfile.WholeCoreDensity = WCD;
        save(mfile.Properties.Source, '-append','WCD');
        mfile.CoralPixelDistribution = CoralPixelDistribution;
        
        % Run Export Function
        ExportWCD
    end

    function PlotBoundary

        % remove boundary if it already has been displayed:
        if isgraphics(BoundaryHandle1)
            delete(BoundaryHandle1)
            delete(BoundaryHandle2)
        end

        % use bwmorph to show edges of binarized core:
        BoundaryX = bwmorph(CoreFilter(Xsec,CoralPixelDistribution),'remove');
        BoundaryY = bwmorph(CoreFilter(Ysec,CoralPixelDistribution),'remove');

        hold(s2(4).axis(1),'on')
        BoundaryHandle1 = imagesc(s2(4).axis(1),'XData',ReconDims.Y.*metadata.PixelSpacing(1),'YData',ReconDims.Z*metadata.PixelZSpacing(1),'CData',BoundaryX);
        BoundaryHandle1.AlphaData = BoundaryX;
        hold(s2(4).axis(1),'off')

        hold(s2(4).axis(2),'on')
        BoundaryHandle2 = imagesc(s2(4).axis(2),'XData',ReconDims.Y.*metadata.PixelSpacing(1),'YData',ReconDims.Z*metadata.PixelZSpacing(1),'CData',BoundaryY);
        BoundaryHandle2.AlphaData = BoundaryY;
        hold(s2(4).axis(2),'off')
    end

    function ExportWCD

        % make table
        colNames = {'Distance downcore (mm)', 'WCD (g/cm^3)'};
        tbl = array2table(WCD,'VariableNames',colNames);

        % export summary table as CSV
        [filename, filepath] = uiputfile('*.xlsx', 'Save WCD table');
        FileName = fullfile(filepath, filename);
        writetable(tbl,FileName,'Sheet',1,'Range','A1');

    end

    function numberChanged(numfld)

        % Update numbers if changed
        Sigma = numfld.Value;
    end

end
