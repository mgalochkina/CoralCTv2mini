
% Function used to construct n lognormal curves from peaks in dataset, for use with fit command

function y = nlognfit(b,x)

    %  Don't let fitting use values below 0:
    if any(b<=0)
        y =zeros(size(x));
    else
        %Parameters must come in in vector b (based on nlinfit). Reshape into nx3 where [a mu sigma];
        ParamMat = reshape(b,3,[])';
        sz = size(x);
        x = reshape(x,1,[]);
    
        logn = @(x,a,mu,s) a.*lognpdf(x,mu,s);
        % This example includes a for-loop and if statement
        % purely for example purposes.
        y = logn(x,ParamMat(:,1),ParamMat(:,2),ParamMat(:,3));
    
        y = sum(y,1);
    
        y = reshape(y,sz);
    end
end