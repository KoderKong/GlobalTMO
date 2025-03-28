function [Yj,Wj] = stmo(Yj,Y2L,wX)
if isscalar(Y2L)
    minY = min(Y2L.breaks);
    Yj(Yj < minY) = minY;
    maxY = max(Y2L.breaks);
    Yj(Yj > maxY) = maxY;
    Yj = double(Yj);
    Yj = ppval(Y2L,Yj); % Photometric correction
end
if nargout > 1
    if nargin < 3 || isempty(wX)
        mL = median(Yj(:));
        wL = mL-2.2*log(128/255);
    else
        wL = log(wX);
    end
    Yj = (Yj-wL)/2.2; % Gamma correction
    Yj(Yj > 0) = 0; % White saturation
    Wj = uint8(255*exp(Yj));
end
