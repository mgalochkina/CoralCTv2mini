%% Function to do whole core filtering by slice

function IsCore = CoreFilter(Slice,Distribution)
    
    % Create histogram of Slice
    [counts,bins] = histcounts(Slice);
    centers = bins(1:end-1)+mean(diff(bins));

    % Evaluate the saved distribution:
    pdf = lognpdf(centers,Distribution(2),Distribution(3));
    [pdfmax,pdfmaxid] = max(pdf);

    % Normalize pdf to counts in this slice:
    pdf = pdf./pdfmax.*counts(pdfmaxid);

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
    ao = ~bwareaopen(~bim68,round(sum(~bim68(:))/10),4);

    % second area open - artifacts outside the 1-sd smaller than 1/100 area identified
    ao = bwareaopen(ao,round(sum(ao(:))/100),4);  

    % calculate distances from 1-sd mask:
    d = bwdist(ao);

    % final bim is bim68  + bim95 within X distance of bim68:
    d(~bim95 & ~ao) = Inf;
    bim = d<2;
    IsCore = bim;
end