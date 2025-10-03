function [sn,mfile] = GUI_LoadData(UI,uigrid)
% created 12/14/23 - Mariya
% edited 1/3/24 - accounts for ReconDims
% last edited 10/3/25 - for mini version

    % Screen 1 - Import images, load scans, view slices for completeness
    
    % Panel 1 - load/import data
    s1(1).panel = uipanel(uigrid,'Title','1. Load Options');
    s1(1).panel.Layout.Row = [3 25];
    s1(1).panel.Layout.Column = [3 25];
    
    s1(1).grid = uigridlayout(s1(1).panel,[20 10]);
    s1(1).label(1) = uilabel(s1(1).grid);
    s1(1).label(1).Text = 'Image files that have not been imported to CoralCT must be converted to a MATLAB data structure. Select files to import here.';
    s1(1).label(1).Layout.Column = [1 10];
    s1(1).label(1).Layout.Row = [1 6];
    s1(1).label(1).WordWrap = 'on';
    
    s1(1).button(1) = uibutton(s1(1).grid);
    s1(1).button(1).Text = 'Import Image Folder';
    s1(1).button(1).Layout.Column = [1 9];
    s1(1).button(1).Layout.Row = [6 9];
    
    s1(1).label(2) = uilabel(s1(1).grid);
    s1(1).label(2).Text = 'Cores that have already been imported and reconstructed as a .mat file can be accessed here.';
    s1(1).label(2).Layout.Column = [1 10];
    s1(1).label(2).Layout.Row = [11 15];
    s1(1).label(2).WordWrap = 'on';
    
    s1(1).button(2) = uibutton(s1(1).grid);
    s1(1).button(2).Text = 'Load Existing .mat Reconstruction';
    s1(1).button(2).Layout.Column = [1 9];
    s1(1).button(2).Layout.Row = [15 18];
      
    % Panel 2 - Adjustments to core & save/resave
    s1(2).panel = uipanel(uigrid,'Title','2. Adjust & Save');
    s1(2).panel.Layout.Row = [30 55];
    s1(2).panel.Layout.Column = [3 25];
    
    s1(2).grid = uigridlayout(s1(2).panel,[10 10]);
    s1(2).button(1) = uibutton(s1(2).grid);
    s1(2).button(1).Text = 'Flip Core';
    s1(2).button(1).FontSize = 14;
    s1(2).button(1).Layout.Column = [1 5];
    s1(2).button(1).Layout.Row = [2 3];
    
    s1(2).button(2) = uibutton(s1(2).grid,'state');
    s1(2).button(2).Text = 'Crop Core';
    s1(2).button(2).FontSize = 14;
    s1(2).button(2).Layout.Column = [6 10];
    s1(2).button(2).Layout.Row = [2 3];
    
    s1(2).label(1) = uilabel(s1(2).grid);
    s1(2).label(1).Text = 'If you want to update the .mat file or write a new file based on the adjusted images:';
    s1(2).label(1).FontSize = 14;
    s1(2).label(1).Layout.Column = [1 10];
    s1(2).label(1).Layout.Row = [4 6];
    s1(2).label(1).WordWrap = 'on';
    
    s1(2).button(3) = uibutton(s1(2).grid);
    s1(2).button(3).Text = 'Export Reconstruction';
    s1(2).button(3).FontSize = 14;
    s1(2).button(3).Layout.Column = [1 10];
    s1(2).button(3).Layout.Row = [7 8];
    
    % Panel 3 - Analyze
    s1(3).panel = uipanel(uigrid,'Title','3. Analyze reconstruction');
    s1(3).panel.Layout.Row = [60 75];
    s1(3).panel.Layout.Column = [3 25];
    s1(3).panel.FontSize = 16;
    s1(3).grid = uigridlayout(s1(3).panel,[10 10]);

    s1(3).button(1) = uibutton(s1(3).grid);
    s1(3).button(1).Text = 'Tag as standard';
    s1(3).button(1).FontSize = 18;
    s1(3).button(1).Layout.Column = [1 5];
    s1(3).button(1).Layout.Row = [4 7];
    s1(3).button(1).BackgroundColor = 'r';
    s1(3).button(1).FontColor = 'w';

    s1(3).button(2) = uibutton(s1(3).grid,'state');
    s1(3).button(2).Text = 'Analyze';
    s1(3).button(2).FontSize = 18;
    s1(3).button(2).Layout.Column = [6 10];
    s1(3).button(2).Layout.Row = [4 7];
    s1(3).button(2).BackgroundColor = 'r';
    s1(3).button(2).FontColor = 'w';

    % Panel 4 - X Cut
    s1(4).panel = uipanel(uigrid,'Title','X-Section');
    s1(4).panel.Layout.Row = [3 75];
    s1(4).panel.Layout.Column = [30 60];

    % Panel 5 - Y Cut
    s1(5).panel = uipanel(uigrid,'Title','Y-Section');
    s1(5).panel.Layout.Row = [3 75];
    s1(5).panel.Layout.Column = [65 95];
    
    % initialize persistent variables;
    isflipped = false;
    mfile = [];
    ReconDims = [];
    metadata = [];
    roi1 = [];
    roi2 = [];
    scanDims = [];
    filename = []; FileName = [];
    CoreFilter = fspecial('gaussian',10,1);

    % Initialize callbacks
    UpdateCallbacks;    

    % wait for user interactions
    waitfor(s1(3).button(2),'Value',true)

    % if no reconstruction is made, use entire scan dimensions to set
    % ReconDims
    if isempty(ReconDims)
        ReconDims.X = 1:size(mfile.Scan,1);
        ReconDims.Y = 1:size(mfile.Scan,2);
        ReconDims.Z = 1:size(mfile.Scan,3);
        mfile.ReconDims = ReconDims;
        metadata.Width = length(ReconDims.X);
        metadata.Height = length(ReconDims.Y);
    end

    % save final metadata to file
    mfile.metadata = metadata;

    save(mfile.Properties.Source, '-append','metadata','ReconDims');

    % if resumed, continue to next scene:
    clf(UI)
    sn = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%% BUTTON FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Function to define/update callbacks
    function UpdateCallbacks
        s1(1).button(1).ButtonPushedFcn = {@ChooseData};
        s1(1).button(2).ButtonPushedFcn = {@ReadMatFile};
        s1(2).button(1).ButtonPushedFcn = {@FlipCore};
        s1(2).button(2).ValueChangedFcn = {@CropCore};
        s1(2).button(3).ButtonPushedFcn = {@AppendReconstruction};
        s1(3).button(1).ButtonPushedFcn = {@TagStandard};
    end

    % Function to pick images, and decide which format they are:
    function ChooseData(src,event)
        % Choose directory containing core
        [inpath] = uigetdir('Select folder containing core CT scans');
        drawnow; figure(UI)

        % Delete existing plots
        if exist('s1(4).axis(1)','var')
            %cla(s1(4).axis(1),'reset'); cla(s1(5).axis(1),'reset');
            delete(s1(4).axis(1)); delete(s1(5).axis(1));
        end

        % Scan for possible filetypes, return if non identified.
        try
        scans = {dir([inpath '/**/*.IMA']), ...
                 dir([inpath '/**/*.dcm']), ...
                 dir([inpath '/**/*.tif'])};
        catch
            return
        end

        % Load slices based on filetype
        if ~isempty(scans{1})
            read_dicom3_v2(scans{1});
        elseif ~isempty(scans{2})
            read_dicom3_v2(scans{2});
        elseif ~isempty(scans{3})
            read_tif(scans{3});
        end
        
        % Assign CoreID
        SaveCoreID

        % Assign Scan Date
        %SaveScanDate

        % Plot core cross sections:
        PlotData

        % Update Callbacks:
        UpdateCallbacks
    end

    % Function to read core saved to existing mat file
    function ReadMatFile(src,event)
        [filename, filepath] = uigetfile('*.mat', 'Load .mat file reconstruction');
        drawnow; figure(UI)
        FileName = fullfile(filepath, filename);
        mfile = matfile(FileName,'Writable',true);
        % ReconDims = mfile.ReconDims;
        metadata = mfile.metadata;

        % Detect if Recon exists:
        variableInfo = who(mfile);

        if ismember('ReconDims',variableInfo) && ~isempty(mfile.ReconDims)
            % Ask if want to use old recon, or create new recon:
            ReconDims = mfile.ReconDims;
            msg = 'Existing Reconstruction detected. Use or create new?';
            title = 'Recon Detected';
            uiconfirm(UI,msg,title,'Options',{'Use Existing Recon','Create New Recon'}, ...
            'DefaultOption',1,'CancelOption',1,'CloseFcn',@dlgcallback);

        elseif~ismember('Recon',variableInfo)
            ReconDims.X = 1:size(mfile.Scan,1);
            ReconDims.Y = 1:size(mfile.Scan,2);
            ReconDims.Z = 1:size(mfile.Scan,3);
            mfile.ReconDims = ReconDims;
            metadata.Width = length(ReconDims.X);
            metadata.Height = length(ReconDims.Y);

        end

        % Plot core cross sections:
        PlotData

        % Update Callbacks:
        UpdateCallbacks

        % Dialogue callback:
        function dlgcallback(src,event)
            if event.SelectedOption == "Create New Recon"
                mfile.ReconDims = [];
            end
        end
    end

    % Function to crop core from image
    function CropCore(src,event)

        % Update callback function:
        s1(2).button(2).Value = true;
        s1(2).button(2).Text = 'Finish Cropping';
        s1(2).button(2).BackgroundColor = '#edc3af';
        s1(2).button(2).ValueChangedFcn = '';

        % First Crop
        s1(4).axis(1).Box = 'On';
        s1(4).axis(1).XColor = 'r'; s1(4).axis(1).YColor = 'r';
        s1(4).axis(1).LineWidth = 10;
        roi1 = drawrectangle(s1(4).axis(1),'color','r');
        s1(4).axis(1).XColor = 'k'; s1(4).axis(1).YColor = 'k';
        s1(4).axis(1).LineWidth = 1;        

        % Second Crop
        s1(5).axis(1).Box = 'On';
        s1(5).axis(1).XColor = 'r'; s1(5).axis(1).YColor = 'r';
        s1(5).axis(1).LineWidth = 10;
        roi2 = drawrectangle(s1(5).axis(1),'color','r');
        s1(5).axis(1).XColor = 'k'; s1(4).axis(1).YColor = 'k';
        s1(5).axis(1).LineWidth = 1;

        s1(2).button(2).ValueChangedFcn = {@StopCrop,roi1,roi2};
    end

    function StopCrop(src,event,roi1,roi2)

        % Assign X and Z:
        corners1 = roi1.Vertices;
        corners2 = roi2.Vertices;
        ReconDims.X = [round(corners2(1,1)):floor(corners2(4,1))];
        ReconDims.Y = [round(corners1(1,1)):floor(corners1(4,1))];
        ReconDims.Z = [min(floor(corners1(1,2)),floor(corners2(1,2))):max(floor(corners1(2,2)),floor(corners2(2,2)))];
        
        % make sure that ReconDims don't exceed actual matrix dimensions
        if ReconDims.X(end) > scanDims(1)
            ReconDims.X(ReconDims.X>scanDims(1)) = [];
        elseif ReconDims.Y(end) > scanDims(2)
            ReconDims.Y(ReconDims.Y>scanDims(2)) = [];
        elseif ReconDims.Z(end) > scanDims(3)
            ReconDims.Z(ReconDims.Z>scanDims(3)) = [];
        end

        % Grey out rectangles:
        rectangle(s1(4).axis(1),'Position',roi1.Position,'EdgeColor',[160 160 160]./255,'LineWidth',1);
        rectangle(s1(5).axis(1),'Position',roi2.Position,'EdgeColor',[160 160 160]./255,'LineWidth',1);
        delete(roi1); delete(roi2);

        % return button text
        s1(2).button(2).Text = 'Crop Core';

        % reset button callbacks
        UpdateCallbacks
    end

    % Function to flip core image
    function FlipCore(src,event)
        
        isflipped = ~isflipped;

        % Replot data:
        PlotData

        % Update Callbacks:
        UpdateCallbacks
    end

    % Function to write edited core back to existing mat file
    function AppendReconstruction(src,event)
       
        % flip and crop file with progress bar
        d = uiprogressdlg(UI,'Title','Saving Reconstruction','Indeterminate','on');
            if isflipped == true
                % Append flipped indices
                fullSize = size(matfile.Scan);
                ReconDims.Z = ReconDims.Z-fullSize(3);
            end
            
            %  Save reconstruction dimensions to file
            mfile.ReconDims = ReconDims;

            % Update Metadata
            metadata.Width = length(ReconDims.X);
            metadata.Height = length(ReconDims.Y);

        close (d)
        
        % Display status notification
        uialert(UI,'Export Successful','Export Status','Icon','success');

        % Plot core cross sections:
        delete(s1(4).axis(1)); delete(s1(5).axis(1));
        PlotData

        % Update Callbacks:
        UpdateCallbacks
    end

    % Function to tag a reconstruction as a standard. Adds to local standard directory
    function TagStandard(src,event)
        
        % Prompt to create or use existing directory
        msg = 'Save standard to new directory, or existing directory?';
        title = 'Choose Standard Directory';
        uiconfirm(UI,msg,title,'Options',{'Existing Directory','New Directory','Cancel'}, ...
        'DefaultOption',1,'CancelOption',3,'CloseFcn',@dlgcallback);
       
        % Dialogue callback:
        function dlgcallback(src,event)
            if event.SelectedOption == "Existing Directory"
                % Find standard directory. If none exists, create one:
                [filename, filepath] = uigetfile('*.mat', 'Choose standard directory');
                drawnow; figure(UI)
                FileName = fullfile(filepath, filename);
                mdir = matfile(FileName,'Writable',true);

                % Replace old row if it's a replicate:
                tbl = mdir.StandardInfo;
                SameCore = find(contains(tbl.CoreID, mfile.CoreID));
                SameDate = find(tbl.ScanDate == mfile.ScanDate);

                if any(intersect(SameCore,SameDate))
                    num = tbl.num(intersect(SameCore,SameDate));
                    tbl(intersect(SameCore,SameDate),:) = table(num,mfile.CoreID,mfile.ScanDate,string(mfile.Properties.Source),...
                        'VariableNames',["num","CoreID","ScanDate","Path"]);
                else
                    %Increment number column by 1, and save to that row
                    num = tbl.num(end)+1;
                    % tbl(num,:) = table(num,mfile.CoreID,mfile.ScanDate,string(mfile.Properties.Source),...
                    %     'VariableNames',["num","CoreID","ScanDate","Path"]);

                    if ismember('Density', tbl.Properties.VariableNames)
                        tbl(num,:) = table(num,mfile.CoreID,mfile.ScanDate,string(mfile.Properties.Source), NaN, NaN,...
                            'VariableNames',["num","CoreID","ScanDate","Path","Density","ScanMeans"]);
                    else
                       tbl(num,:) = table(num,mfile.CoreID,mfile.ScanDate,string(mfile.Properties.Source),...
                           'VariableNames',["num","CoreID","ScanDate","Path"]);
                    end
                end

                mdir.StandardInfo = tbl;

            elseif event.SelectedOption == "New Directory"
                % Find standard directory. If none exists, create one:
                [filename, filepath] = uiputfile('*.mat', 'Create standard directory');
                drawnow; figure(UI)
                FileName = fullfile(filepath, filename);
                mdir = matfile(FileName,'Writable',true);

                % Create table for standard name, date, path
                mdir.StandardInfo = table(1,mfile.CoreID,mfile.ScanDate,string(mfile.Properties.Source),...
                    'VariableNames',["num","CoreID","ScanDate","Path"]);
            end

            % Unanalyzed standards have to have recon and metadata updated:
            if isempty(ReconDims)
                ReconDims.X = 1:size(mfile.Scan,1);
                ReconDims.Y = 1:size(mfile.Scan,2);
                ReconDims.Z = 1:size(mfile.Scan,3);
                mfile.ReconDims = ReconDims;

                metadata.Width = length(ReconDims.X);
            end

            % Save final metadata to file
            mfile.metadata = metadata; 

            % zero our ReconDims again:
            ReconDims = [];
        end
    end



%%%%%%%%%%%%%%%%%%%%%%%%%%%% OTHER FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function read_tif(C)
        %READ_TIF Reads in CT scans in .tif file format
        
        % Create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Calculating scan positions');
        ppct = .03; % increment percent as decimal

        % check if incorrect small file present
        if any([C.bytes] < 10000)
            C(find([C.bytes]<10000)) = [];
        end

        % take in .tif metadata
        metadata = imfinfo([C(1).folder filesep C(1).name]);

        % delete unnecessary metadata fields
        allFields = fieldnames(metadata);
        metadata = rmfield(metadata, setdiff(allFields, {'FileModDate', 'ImageDescription','RowsPerStrip'}));

        % determine Voxel spacing
        coreInfo = dir(fullfile(C(1).folder,'*.txt')); % contains WholeCoreRecon.txt
        % make sure no erroneous file
        if size(coreInfo,1)>1
            coreInfo(1) = [];
        end

        if ~isempty(coreInfo) % if text file WholeCoreRecon.txt is found
            % read in X-Y pixel spacing
            voxelSize = regexp(fileread([C(1).folder filesep coreInfo.name]),'Calculated Voxel size = (\d+\.?\d+)', 'tokens');
            metadata.PixelSpacing = str2double(voxelSize{1}{1});
            % calculate Z pixel spacing
            sliceNum = regexp(fileread([C(1).folder filesep coreInfo.name]),'Last Slice = (\d+)', 'tokens'); % of slices
            scanLength = regexp(fileread([C(1).folder filesep coreInfo.name]),'Section Length = (\d+\.?\d+)', 'tokens'); % length of core (cm)
            metadata.PixelZSpacing = str2double(scanLength{1,1})/str2double(sliceNum{1,1})*10;
        else % if no .txt files are found, ask user for manual input
            input = inputdlg({'Enter X-Y pixel spacing (in mm):','Enter Z pixel spacing (in mm):'}, ...
                'Manually enter pixel spacing', [1 40],{'0.184', '0.184'});
            metadata.PixelSpacing = str2double(input{1,1});
            metadata.PixelZSpacing = str2double(input{2,1});
        end

        % Extract the slope and intercept value using regular expressions
        slopeMatch = regexp(metadata.ImageDescription, 'slope = ([+-]?\d+\.?\d+E[+-]?\d+)', 'tokens'); 
        intMatch = regexp(metadata.ImageDescription, 'offset = ([+-]?\d+\.?\d+E[+-]?\d+)', 'tokens'); 
        
        % Convert the extracted value to a double variable
        metadata.RescaleSlope = str2double(slopeMatch{1}{1}); metadata.RescaleIntercept = str2double(intMatch{1}{1});
        
        % Pre-allocate .mat file name
        [filename, filepath] = uiputfile('*.mat', 'Save scan as .mat file');
        FileName = fullfile(filepath, filename);
        drawnow; figure(UI);

        % Create file by saving metadata in this format
        savefast(FileName,'metadata');

        % Write slices to .mat file in same location
        mfile = matfile(FileName,'Writable',true);

        % check size (added 1/4/23 to account for bundled cores)
        tempSize = size(imread([C(1).folder filesep C(1).name]));
        
        % Preallocate Scan at unique ID 
        h5create(FileName, '/Scan', double([tempSize length(C)]),...
            'DataType', 'uint16');  % new
        % h5create(FileName, '/Scan', double([metadata.RowsPerStrip metadata.RowsPerStrip length(C)]),...
        %    'DataType', 'uint16');  % original      
        
        % populate matrix with unique slices
        for i1 = 1:length(C)
            % Rescale all the intensity values in the matrix so that the matrix
            % contains the original intensity values rather than the scaled values that
            % imread produces
            mfile.Scan(:,:,i1) = (imread([C(1).folder filesep C(i1).name]));
            

            % update progress bar
            pinc = floor(length(C)*ppct);
            if mod(i1,pinc) == 0
                pbar.Value = min(pbar.Value + ppct,1);
            elseif i1 == length(C)
                pbar.Value = 0;
                pbar.Message = 'Converting Scans';
            end

            % take density sample of core
            % if i1 == round(length(C)/2)
            %     h = fspecial('gaussian',10, 1); % create filter
            %     tempX = double(imread([C(1).folder filesep C(i1).name])).*metadata.RescaleSlope + metadata.RescaleIntercept;
            %     filteredXcore(:,:) = imfilter(tempX, h);
            %     level = graythresh(filteredXcore);
            %     coralSample = imbinarize(filteredXcore,level);
            %     mfile.densitySample = mean(tempX(coralSample==1));
            % end
        end

        % take density sample of core
        tempX = double(squeeze(mfile.Scan(round(size(mfile.Scan,1)/2),:,:))).*metadata.RescaleSlope + metadata.RescaleIntercept;
        filteredXcore(:,:) = imfilter(tempX, CoreFilter);
        level = graythresh(filteredXcore);
        coralSample = imbinarize(filteredXcore,level);
        mfile.densitySample = mean(tempX(coralSample==1));

        % Determine date of scan
        mfile.ScanDate = datetime(metadata.FileModDate, 'Format','dd-MMM-uuuu'); 

    end

    function read_dicom3_v2(C)

        % Create progress bar
        pbar = uiprogressdlg(UI,'Title','Please Wait','Message','Calculating scan positions');
        ppct = .03; % increment percent as decimal

        % load in all slice locations
        sliceLoc_temp = zeros(1,length(C)); % Pre-allocate sliceLoc
        for i1 = 1:length(C)
            DCMname = [C(i1).folder filesep C(i1).name];

            % read in slice location
            DCMname = fullfile(C(i1).folder, C(i1).name); % more robust than using filesep

            info = dicominfo(DCMname); % reads all metadata

            % Extract SliceLocation safely
            if isfield(info, 'SliceLocation')
                sliceLoc_temp(i1) = info.SliceLocation;
            else
                sliceLoc_temp(i1) = NaN; % or handle differently if field is missing
            end

            % update progress bar
            pinc = floor(length(C)*ppct);
            if mod(i1,pinc) == 0
                pbar.Value = min(pbar.Value + ppct,1);
            elseif i1 == length(C)
                pbar.Value = 0;
                pbar.Message = 'Converting Scans';
            end
        end

        % read xy dicom info:
        metadata = dicominfo(DCMname);
        [filename, filepath] = uiputfile('*.mat', 'Save scan as .mat file');
        FileName = fullfile(filepath, filename);
        drawnow; figure(UI)

        % Create file as v7.3 by saving metadata in this format:
        savefast(FileName,"metadata")

        % Write slices to .mat file in same location in order of sliceLoc
        mfile = matfile(FileName,'Writable',true);

        % find unique slice locations
        [sliceLoc_temp,idx] = unique(sliceLoc_temp,'stable');

        % Sort sliceLoc by convention in descending order:
        [mfile.sliceLoc,sortids] = sort(sliceLoc_temp,'descend');
        idx = idx(sortids);

        % If sliceLoc is homogenous (no missing core) save PixelZSpacing:
        metadata.PixelZSpacing = abs(mean(diff(mfile.sliceLoc)));
        
        % Save scan at unique ids:
        h5create(FileName, '/Scan', double([metadata.Height metadata.Width length(idx)]),...
            'DataType', 'uint16');

        for i2 = 1:length(idx)

            % read in file idx to row i2
            mfile.Scan(:,:,i2) = dicomread([C(idx(i2)).folder filesep C(idx(i2)).name]);

            % update progress bar
            pinc = floor(length(idx)*ppct);
            if mod(i2,pinc) == 0
                pbar.Value = min(pbar.Value + ppct,1);
            elseif i2 == length(idx)
                close(pbar)
            end

            % take density sample of core
            % if i2 == round(length(idx)/2)
            %     h = fspecial('gaussian',10,1);
            %     tempX = dicomread([C(idx(i2)).folder filesep C(idx(i2)).name]);
            %     filteredXcore(:,:) = imfilter(tempX, h);
            %     level = graythresh(filteredXcore);
            %     coralSample = imbinarize(filteredXcore,level);
            %     mfile.densitySample = mean(tempX(coralSample==1));
            % end

        end

        % take density sample of core
        tempX = double(squeeze(mfile.Scan(round(size(mfile.Scan,1)/2),:,:))).*metadata.RescaleSlope + metadata.RescaleIntercept;
        filteredXcore(:,:) = imfilter(tempX, CoreFilter);
        level = graythresh(filteredXcore);
        coralSample = imbinarize(filteredXcore,level);
        mfile.densitySample = mean(tempX(coralSample==1));
        
        % Append scan date and time to metadata in matlab datetime:
        time = strcat(metadata.AcquisitionDate(1:4),'-',metadata.AcquisitionDate(5:6),'-',metadata.AcquisitionDate(7:8));
        mfile.ScanDate = datetime(time,'InputFormat', 'uuuu-MM-dd');

    end

    % Function to save Core ID
    function SaveCoreID
        
        % Prompt user for name of core 
        prompt = {'Enter Core ID (ex. 1567)'};
        dlgtitle = 'Core ID';
        dims = [1 35];
        try
            definput = {metadata.SeriesDescription};
        catch
            definput = {''};
        end
        % Save as CoreID Variable
        mfile.CoreID = string(inputdlg(prompt,dlgtitle,dims,definput));

    end

    % function SaveScanDate
    % 
    %     % Prompt user for name of core 
    %     prompt = {'Enter Scan Date in this format (ex. 03-Jan-2024)'};
    %     dlgtitle = 'Scan Date';
    %     dims = [1 35];
    %     % try
    %     %     definput = {metadata.SeriesDescription};
    %     % catch
    %     %     definput = {''};
    %     % end
    %     % Save as CoreID Variable
    %     mfile.ScanDate = datenum(inputdlg(prompt,dlgtitle,dims,definput));
    % 
    % end

    % Function to plot slices through core
    function PlotData
        % Get dimensions and value ranges
        scanDims = size(mfile.Scan);
        
        if exist('s1(4).axis(1)','var')
            cla(s1(4).axis(1),'reset'); cla(s1(5).axis(1),'reset');
            delete(s1(4).axis(1)); delete(s1(5).axis(1));
        end

        % load in variable info
        variableInfo = who(mfile);

        % Define X-slice and Y-slice, depending on if ReconDims have been BOTH defined & saved to file:

        if ismember('ReconDims',variableInfo) && ~isempty(mfile.ReconDims)
            Xsec = squeeze(mfile.Scan(round(scanDims(1)/2),ReconDims.Y,ReconDims.Z))';
            Ysec = squeeze(mfile.Scan(ReconDims.X,round(scanDims(1)/2),ReconDims.Z))';
        else
            Xsec = squeeze(mfile.Scan(round(scanDims(1)/2),:,:))';
            Ysec = squeeze(mfile.Scan(:,round(scanDims(1)/2),:))';
        end
        

        % Plot dim1 slice to first graph 
        s1(4).axis(1) = axes(s1(4).panel);
        s1(4).axis(1).NextPlot = 'add';
        s1(4).axis(1).XTick = [];% s1(4).axis(1).YTick = [];
        if isflipped == false
            imagesc(s1(4).axis(1), Xsec);
        elseif isflipped == true
           imagesc(s1(4).axis(1), flipud(Xsec));
        end
        colormap(s1(4).axis(1),'bone')
        axis(s1(4).axis(1),'image')
        s1(4).axis(1).YDir = 'reverse';

        % Plot dim2 slice to second graph
        s1(5).axis(1) = axes(s1(5).panel);
        s1(5).axis(1).NextPlot = 'add';
        s1(5).axis(1).XTick = [];% s1(5).axis(1).YTick = [];
        if isflipped == false
            imagesc(s1(5).axis(1), Ysec);
        elseif isflipped == true
           imagesc(s1(5).axis(1), flipud(Ysec));
        end
        colormap(s1(5).axis(1),'bone')
        axis(s1(5).axis(1),'image')
        s1(5).axis(1).YDir = 'reverse';

    end

end


