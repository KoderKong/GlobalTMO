clear
close all
file = 'hallway2';
Xjk = readbin(file,6);
Xjk = imredim(Xjk,[160 240]); % HQVGA format
[rows,cols,pages] = size(Xjk);
load CISmodels logDPS
Ts = 1/(30*rows*cols); % Sampling period (s)
sbin = 4; % Bits to discard / interpolate
hmax = ceil((rows*cols/sqrt(12))/pow2(logDPS.stde,8-sbin));
[yin,cin] = simin(logDPS,Xjk,Ts,sbin);
cmax = rows*cols;
bitc = ceil(log2(cmax));
Amin = round(pow2(256,bitc)/cmax);
Amax = round(pow2(256,bitc)/hmax);
bitA = ceil(log2(Amax));
sim LXXIsys % Li's method, w/o div, w/o LPF, with interp
hout.Data = hout.Data(:);
assert(iscolumn(TTout.Data))
wwout.Data = wwout.Data(:);
wout.Data = wout.Data(:);
simout(logDPS,Xjk,sbin,hout,TTout,yin,wwout,wout)

function Xjk = readbin(file,pages)
file = strcat(file,'.bin');
[fid,msg] = fopen(file,'r');
if fid == -1
    error(msg)
end
Xjk = fread(fid,[1280*720 pages],'*single');
fclose(fid);
Xjk = reshape(Xjk,[1280 720 pages]);
Xjk = permute(Xjk,[2 1 3]);
end

function [yin,cin] = simin(CISobj,Xjk,Ts,sbin)
[rows,cols,pages] = size(Xjk);
Yjk = zeros(rows,cols,pages,'uint16');
rng default % Reset CISobj
for k = 1:pages
    Yjk(:,:,k) = image(CISobj,Xjk(:,:,k));
end
Yjk = permute(Yjk,[2 1 3]);
Tjk = (0:numel(Yjk)-1)'*Ts;
yin = timeseries(Yjk(:),Tjk,'Name','yin');
Cj = uint16(0:pow2(16-sbin)-1)';
assert(sbin >= 3)
Cj = bitshift(Cj,3);
Cj = flip(Cj); % Negative gain
C0 = Cj(end);
Cj = [C0; bitor(Cj,0x0002)];
Cjk = repmat(Cj,1,pages);
assert(numel(Cj) <= rows*cols)
Cjk(numel(Cj)+1:rows*cols,:) = C0;
bits = mod(uint16(1:pages),0x0002);
bits(3:pages) = bitor(bits(3:pages),0x0004);
Cjk = bitor(Cjk,bits);
Cjk = fi(Cjk,0,19-sbin,0);
cin = timeseries(Cjk(:),Tjk,'Name','cin');
end

function simout(CISobj,Xjk,sbin,hout,TTout,yin,wwout,wout)
dotdot('SIMOUT',10)
[M,N,P] = size(Xjk);
TMOobj = TMO2021(16-sbin,'invert-interp',8,...
    [],[M N],pow2(CISobj.stde,-sbin),'lut');
rng default % Reset CISobj
MN = M*N;
for k = 1:P
    dotdot(true)
    Xj = Xjk(:,:,k);
    Yj = image(CISobj,Xj);
    Wj = process(TMOobj,Yj,sbin);
    if k < P
        sceneHist(TMOobj.pmf,k-1,MN,sbin,hout)
    end
    if k > 2
        toneFunc(TMOobj.map,k-1,MN,sbin,TTout)
    end
    if k > 2 && k < P-1
        globalMap(TMOobj.map,k-1,MN,sbin,yin,wwout)
    end
    if k > 3 && k < P
        interpLin(Wj,k-1,MN,wout)
    end
end
dotdot(false)
end

function sceneHist(pmf_,fn,cmax,sbin,hout)
n = (fn+1)*cmax;
nbin = pow2(16-sbin);
pmf = hout.Data(n+3:n+nbin+2);
pmf = flip(pmf(:)); % Reverse readout
assert(isequal(pmf_,pmf))
end

function toneFunc(map_,fn,cmax,sbin,TTout)
n = fn*cmax;
nbin = pow2(16-sbin);
data = flip(TTout.Data(n+8:n+nbin+7)); % 'invert'
map = {uint8(bitand(data,0x00FF));
    uint8(bitshift(bitand(data,0xFF00),-8))};
assert(isequal(map_,map{1}))
assert(isequal(map_([2:end end]),map{2}))
end

function globalMap(map_,fn,cmax,sbin,yin,wwout)
n = (fn+1)*cmax;
Yj = reshape(yin.Data(n+1:n+cmax),240,160)';
Wj_ = map_(double(bitshift(Yj,-sbin))+1);
WWj = reshape(wwout.Data(n+8:n+cmax+7),240,160)';
LSBs = @(Data) uint8(bitand(Data,0x00FF));
assert(isequal(Wj_,LSBs(WWj)))
end

function interpLin(Wj_,fn,cmax,wout)
n = fn*cmax;
Wj = reshape(wout.Data(n+11:n+cmax+10),240,160)';
assert(isequal(Wj_,Wj))
end
