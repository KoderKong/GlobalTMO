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
sim LXFIsys % Li's method, w/o div, with LPF, with interp
hin.Data = hin.Data(:);
hout.Data = hout.Data(:);
ttout.Data = ttout.Data(:);
wwout.Data = wwout.Data(:);
wout.Data = wout.Data(:);
simout(logDPS,Xjk,sbin,hin,hout,ttout,yin,wwout,wout)
pdfout('topScope',[7.5 7.5],cin,yin,wout)
hin.Name = 'hin';
hout.Name = 'hout';
ttout.Name = 'ttout';
wwout.Name = 'wwout';
wout.Name = 'wout';
% xlsxout('TMOsim_LXFI',cin,yin,hin,hout,ttout,wwout,wout);

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

function simout(CISobj,Xjk,sbin,hin,hout,ttout,yin,wwout,wout)
dotdot('SIMOUT',10)
[M,N,P] = size(Xjk);
TMOobj = TMO2025(16-sbin,'invert-interp',8,...
    1,[M N],pow2(CISobj.stde,-sbin),'lut');
rng default % Reset CISobj
MN = M*N;
for k = 1:P
    dotdot(true)
    Xj = Xjk(:,:,k);
    Yj = image(CISobj,Xj);
    Wj = process(TMOobj,Yj,sbin); %#ok<NASGU>
    if k < P
        sceneHist(TMOobj.pmf(:,1),k-1,MN,sbin,hin)
        percvHist(TMOobj.pmf(:,2),k-1,MN,sbin,hout)
    end
    if k > 2
        % toneFunc(TMOobj.map,k-1,MN,sbin,ttout)
    end
    if k > 2 && k < P-1
        % globalMap(TMOobj.map,k-1,MN,sbin,yin,wwout)
    end
    if k > 3 && k < P
        % interpLin(Wj,k-1,MN,wout)
    end
end
dotdot(false)
end

function sceneHist(pmf_,fn,cmax,sbin,hin)
n = (fn+1)*cmax;
nbin = pow2(16-sbin);
pmf = hin.Data(n+3:n+nbin+2);
pmf = flip(pmf(:)); % Reverse readout
assert(isequal(pmf_,pmf))
end

function percvHist(pmf_,fn,cmax,sbin,hout)
n = (fn+1)*cmax;
nbin = pow2(16-sbin);
pmf = hout.Data(n+6:n+nbin+5);
pmf = flip(pmf(:)); % Reverse readout
assert(isequal(pmf_,pmf))
end

function toneFunc(map_,fn,cmax,sbin,ttout)
n = fn*cmax;
nbin = pow2(16-sbin);
data = flip(ttout.Data(n+9:n+nbin+8)); % 'invert'
map = {uint8(bitand(data,0x00FF));
    uint8(bitshift(bitand(data,0xFF00),-8))};
assert(isequal(map_,map{1}))
assert(isequal(map_([2:end end]),map{2}))
end

function globalMap(map_,fn,cmax,sbin,yin,wwout)
n = (fn+1)*cmax;
Yj = reshape(yin.Data(n+1:n+cmax),240,160)';
Wj_ = map_(double(bitshift(Yj,-sbin))+1);
WWj = reshape(wwout.Data(n+9:n+cmax+8),240,160)';
LSBs = @(Data) uint8(bitand(Data,0x00FF));
assert(isequal(Wj_,LSBs(WWj)))
end

function interpLin(Wj_,fn,cmax,wout)
n = fn*cmax;
Wj = reshape(wout.Data(n+12:n+cmax+11),240,160)';
assert(isequal(Wj_,Wj))
end

function pdfout(file,dims,cin,yin,wout)
caddr = floor(pow2(cin.Data,-3));
cmode = mod(cin.Data,uint32(8));
subplot(4,1,1)
plot(cin.Time,caddr,'b-')
ylabel('cin MSBs')
subplot(4,1,2)
plot(cin.Time,cmode,'b-')
ylabel('cin LSBs')
subplot(4,1,3)
plot(yin.Time,yin.Data,'b-')
ylabel('yin')
subplot(4,1,4)
plot(wout.Time,wout.Data,'b-')
ylabel('wout')
xlabel('Sample Time (s)')
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end

function xlsxout(file,varargin)
nrows = numel(varargin{1}.Time);
ncols = numel(varargin);
head = cell(1,ncols+1);
body = cell(nrows,ncols+1);
for k = 1:ncols
    head{k+1} = varargin{k}.Name;
    body(:,k+1) = num2cell(double(varargin{k}.Data));
    assert(isequal(varargin{k}.Time,varargin{1}.Time))
end
head{1} = 'time';
body(:,1) = num2cell(double(varargin{1}.Time));
writecell([head; body],strcat(file,'.xlsx'))
end
