%% Function to do whole core filtering by slice
% edited to filter out any low density areas that might be considered core

function IsCore = CoreFilter2(Slice,Distribution, metadata, densitySample)
    
    % Create histogram of Slice
    [counts,bins] = histcounts(Slice);
    centers = bins(1:end-1)+mean(diff(bins));

    % Evaluate the saved distribution:
    pdf = lognpdf(centers,Distribution(2),Distribution(3));
    factor = counts./pdf;
    %[pdfmax,pdfmaxid] = max(pdf);

    % Normalize pdf to counts in this slice:
    %pdf = pdf./pdfmax.*counts(pdfmaxid);
    pdf = pdf*median(factor,'omitmissing');
    % Percent of counts that can be attributed to pdf:
    pCore = 1-(counts-pdf)./counts;
    pCore(pCore>1) = 1; % if fewer detected than expected, assign all to coral.

    % Create probability map of slice (whether it is coral):
    pSlice = zeros(size(Slice));
    for k = 1:length(bins)-1
        pSlice = pSlice + pCore(k).*(Slice>=bins(k) & Slice<bins(k+1));
    end

    % binarize at 1-sd and 2-sd level:
    bim95 = pSlice>0.05;
    bim68 = pSlice>0.32;

    % first area open - artifacts inside the 1-sd smaller than 1/10 area identified
    ao = ~bwareaopen(~bim68,round(sum(~bim68(:))/50),4);

    % second area open - artifacts outside the 1-sd smaller than 1/100 area identified
    ao = bwareaopen(ao,round(sum(ao(:))/100),4);  

    % calculate distances from 1-sd mask:
    d = bwdist(ao);

    % final bim is bim68  + bim95 within X distance of bim68:
    d(~bim95 & ~ao) = Inf;
    bim = d<2;

    % determine BW boundaries of objects
    [tempB] = bwboundaries(bim, 'holes'); 

    % Remove any small boundaries
    B = {}; ctr = 1;
    for i = 1:length(tempB)
        if size(tempB{i},1) > 100
            B{ctr,1} = tempB{i};
            ctr = ctr+1;
        end
    end

    if isempty(B)
        IsCore = false(size(bim));
    else
        % Determine whether any boundaries are within another (i.e. holes)
        isWithin = false(length(B), length(B));
    
        for i = 1:length(B)
            for j = 1:length(B)
                if i == j
                    isWithin(i,j) = 0;
                else
                    isWithin(i,j) = all(inpolygon(B{i}(:,1),B{i}(:,2),B{j}(:,1),B{j}(:,2)));
                end
            end
        end
    
        % set up IsCore
        tempMat = false(size(bim,1), size(bim,2), length(B));
        temp = false(size(bim));
    
        % check volume of boundaries
        for k = 1:length(B)
            volmask = false(size(bim));
            % find volume within polygon
            volmask(poly2mask(B{k}(:,2), B{k}(:,1), size(bim,1), size(bim,2))) = true;
            % convert to real greyscale and sample mean 'density' of the polygon
            dens = mean(Slice(volmask == 1)*metadata.RescaleSlope + metadata.RescaleIntercept);
            % only save the pixels if the polygon density > 40% of mean core density
            if dens > densitySample*0.4
               temp  = volmask;
            end
    
            % remove any overlap
            if any(isWithin(:,k))
                idx = find(isWithin(:,k));
                for n = 1:length(idx)
                    vmask = poly2mask(B{idx(n)}(:,2), B{idx(n)}(:,1), size(bim,1), size(bim,2));
                    temp(vmask) = false;
                end
            end
            tempMat(:,:,k) = temp;
        end
    
        % add up overlap
        coreMat = bwmorph(sum(tempMat,3),"spur",1000);
    
        IsCore = logical(coreMat);
    end
end