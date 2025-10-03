% function MSE = minSig(Sigma, peaklocs, peakvals, centers,counts)
%     sigma0 = repmat(Sigma,1,numel(peaklocs));
%     b0 = [peaklocs./sum(peakvals).*sum(counts)
%         log(peaklocs)-sigma0.^2;
%         %repmat(sigma0,1,length(peaklocs))];
%         sigma0];
%     b0 = reshape(b0,[],1);
%     options = statset('RobustWgtFun',[]);
%     [~,~,~,~,MSE] = nlinfit(centers',counts',@(b,x)nlognfit(b,x),b0,options);
% end

function MSE = minSig(Sigmas, peaklocs, peakvals, centers, counts)
    b0 = [peakvals./sum(peakvals).*sum(counts)
          log(peaklocs) - Sigmas.^2;
          Sigmas];
    b0 = reshape(b0,[],1);
    options = statset('RobustWgtFun',[]);
    [~,~,~,~,MSE] = nlinfit(centers', counts', @(b,x)nlognfit(b,x), b0, options);
end