function [map,div] = tmoheq(pmf,type,bitw,div)
switch type
    case {'normal','normal-interp'}
        cdf = cumsum(pmf,'forward');
        pos = numel(cdf);
    case {'invert','invert-interp'}
        cdf = cumsum(pmf,'reverse');
        pos = 1;
    otherwise
        error('Unknown response type.')
end
if nargin < 3 || isempty(bitw)
    bitw = 8;
elseif bitw > 8
    error('Unsupported word length.')
end
if nargin < 4 || isempty(div)
    div = cdf(pos); % cmax
    wtmp = ceil(pow2(cdf,bitw)/div);
elseif isstruct(div)
    if isfield(div,'lut')
        div = update(div,bitw);
    end
    wtmp = ceil(pow2(div.A*cdf,-div.bitc));
    div.wmax = wtmp(pos);
else
    wtmp = ceil(pow2(cdf,bitw)/div);
    div = cdf(pos); % cmax
end
map = uint8(wtmp-1);

function div = update(div,bitw)
wref = pow2(bitw);
if div.wmax >= 2*wref
    ratio = pow2(bitw-1);
elseif div.wmax <= wref/2
    ratio = pow2(bitw+1);
else
    if isempty(div.lut)
        ratio = round(pow2(wref/div.wmax,bitw));
    else
        ratio = div.lut(div.wmax-wref/2);
    end
end
div.A = round(pow2(ratio*div.A,-bitw));
if div.A >= div.Amax
    div.A = div.Amax;
elseif div.A <= div.Amin
    div.A = div.Amin;
end
