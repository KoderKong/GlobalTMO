classdef TMO2025 < handle
    properties (SetAccess = protected)
        bity % Word length of pixel response (MSBs)
        type % Response type ('normal' or 'invert')
        bitw % Word length after the tone mapping
        elpf % Enable low-pass filter countdown
        pmax % Ceiling for PMF (histogram bins)
        div % Variables to implement division
        pmf % Probability mass functions (PMFs)
        map % Look-up table for tone mapping
    end
    methods
        function TMO = TMO2025(bity,type,bitw,elpf,dims,stde,mode)
            TMO.bity = bity;
            TMO.type = lower(type);
            TMO.bitw = bitw;
            if nargin >= 4
                if isscalar(elpf)
                    TMO.elpf = elpf-1;
                else
                    TMO.elpf = [];
                end
                if nargin >= 5
                    n = prod(dims);
                    num = n/sqrt(12);
                    den = pow2(stde,bitw);
                    TMO.pmax = ceil(num/den);
                    if nargin >= 7
                        nodiv(TMO,mode,n)
                    end
                end
            end
            bins = pow2(bity);
            if isscalar(TMO.elpf)
                TMO.pmf = zeros(bins,2);
            else
                TMO.pmf = zeros(bins,1);
            end
            TMO.map = zeros(bins,2,'uint8');
        end
        function Wj = process(TMO,Yj,sbin)
            Yj_ = bitshift(Yj,-sbin); % MSBs
            [~,hist] = tmopmf(Yj_,TMO.bity);
            lookup = TMO.map(:,2);
            update(TMO,hist)
            lookup = tmointerp(lookup,sbin);
            Wj = lookup(double(Yj)+1);
        end
    end
    methods (Access = protected)
        function nodiv(TMO,mode,n)
            wref = pow2(TMO.bitw);
            if strcmp(mode,'lut')
                wmax = wref/2+1:2*wref-1;
                lut = round(pow2(wref./wmax,TMO.bitw));
            else
                lut = [];
            end
            cmax = pow2(TMO.pmax,TMO.bity);
            cmax = min(n,cmax);
            bitc = ceil(log2(n));
            wref2 = pow2(wref,bitc);
            Amin = round(wref2/cmax);
            Amax = round(wref2/TMO.pmax);
            TMO.div = struct('lut',lut,'bitc',bitc,...
                'wmax',wref/2,'A',Amin,'Amin',Amin,'Amax',Amax);
        end
        function update(TMO,hist)
            TMO.pmf(:,1) = hist; % Scene
            if isscalar(TMO.elpf)
                if TMO.elpf > 0
                    TMO.elpf = TMO.elpf-1;
                else
                    hist = TMO.pmf*[20; 236];
                    hist = floor(pow2(hist,-8));
                end
                TMO.pmf(:,2) = hist; % Perceived
            end
            if isscalar(TMO.pmax)
                bin = hist > TMO.pmax;
                hist(bin) = TMO.pmax; % Modified
            end
            TMO.map(:,2) = TMO.map(:,1);
            [TMO.map(:,1),TMO.div] = tmoheq(hist,...
                TMO.type,TMO.bitw,TMO.div);
        end
    end
end
