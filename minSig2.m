function MSE = minSig(Sigmas, peaklocs, peakvals, centers, counts)
    b0 = [peakvals./sum(peakvals).*sum(counts)
          log(peaklocs) - Sigmas.^2;
          Sigmas];
    b0 = reshape(b0,[],1);
    options = statset('RobustWgtFun',[]);
    [~,~,~,~,MSE] = nlinfit(centers', counts', @(b,x)nlognfit(b,x), b0, options);
end
