clear
close all
file = 'hallway2';
Xjk = readbin(file);
option = menu('TMO Simulate','HQVGA','VGA','HD');
switch option
    case 1
        dims = [160 240]; % HQVGA format
    case 2
        dims = [480 640]; % VGA format
    case 3
        dims = [720 1280]; % HD format
    otherwise
        error('Invalid selection.')
end
Xjk = imredim(Xjk,dims);
type = {'HEFX2','LXFX2','LXFX8','LXFI8'};
sbin = {2,2,8,8}; % Wordlength reduction
load CISmodels logDPS
for k = 1:numel(type)
    vars = writeavi(type{k},sbin{k},file,Xjk,logDPS);
    writemat(type{k},file,vars{:})
end
writebin(type{end},sbin{end},file,Xjk,logDPS)

function Xjk = readbin(file)
file = strcat(file,'.bin');
[fid,msg] = fopen(file,'r');
if fid == -1
    error(msg)
end
Xjk = fread(fid,'*single');
fclose(fid);
frames = numel(Xjk)/(1280*720);
Xjk = reshape(Xjk,[1280 720 frames]);
Xjk = permute(Xjk,[2 1 3]);
end

function vars = writeavi(type,sbin,file,Xjk,CISobj)
[m,n,p] = size(Xjk);
TMOobj = operator(type,sbin,[m n],CISobj.stde);
if isscalar(TMOobj)
    pmf = zeros([p size(TMOobj.pmf)]);
    map = zeros(p,size(TMOobj.pmf,1));
end
head = sprintf('Creating %s video:',type);
dotdot(head,30)
file = strcat(file,type);
video = VideoWriter(file,'Grayscale AVI');
open(video)
rng('default') % Reset CISobj
for k = 1:p
    Xj = Xjk(:,:,k);
    Yj = image(CISobj,Xj);
    if isscalar(TMOobj)
        Wj = process(TMOobj,Yj,sbin);
        pmf(k,:,:) = TMOobj.pmf;
        map(k,:) = TMOobj.map;
    else
        Wj = tonemap(CISobj,Yj);
    end
    writeVideo(video,Wj)
    dotdot(true)
end
close(video)
dotdot(false)
if isscalar(TMOobj)
    vars = {TMOobj.pmax,pmf,map};
else
    vars = {};
end
end

function writemat(type,file,varargin)
if nargin > 2
    vars = {'pmax','pmf','map'};
    for k = 1:numel(varargin)
        eval(sprintf('%s%s = varargin{%d};',vars{k},type,k))
    end
    vars = strcat(vars,'*');
    try
        save(file,vars{:},'-append')
    catch
        save(file,vars{:})
    end
end
end

function writebin(type,sbin,file,Xjk,CISobj)
[m,n,p] = size(Xjk);
TMOobj = operator(type,sbin,[m n],CISobj.stde);
if isscalar(TMOobj)
    head = sprintf('Creating %s binaries:',type);
    dotdot(head,30)
    fid = openall(file,{'Yj','Wj'});
    rng('default') % Reset CISobj
    for k = 1:p
        Xj = Xjk(:,:,k);
        Yj = image(CISobj,Xj);
        fwrite(fid(1),Yj',class(Yj));
        Wj = process(TMOobj,Yj,sbin);
        fwrite(fid(2),Wj',class(Wj));
        dotdot(true)
    end
    fclose('all');
    dotdot(false)
end
end

function TMOobj = operator(type,sbin,dims,stde)
if numel(type) > 4
    type = type(1:4);
end
stde = pow2(stde,-sbin);
switch type
    case 'sRGB' % Photometric sRGB method
        TMOobj = [];
    case 'HEXX' % Histogram equalization, w/o LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8);
    case 'HEFX' % Histogram equalization, with LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8,2);
    case 'LDXX' % Li's method, with div, w/o LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8,[],dims,stde);
    case 'LDFX' % Li's method, with div, with LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8,2,dims,stde);
    case 'LXXX' % Li's method, w/o div, w/o LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8,[],dims,stde,'lut');
    case 'LXFX' % Li's method, w/o div, with LPF, w/o interp
        TMOobj = TMO2021(16-sbin,'invert',8,2,dims,stde,'lut');
    case 'HEXI' % Histogram equalization, w/o LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8);
    case 'HEFI' % Histogram equalization, with LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8,1);
    case 'LDXI' % Li's method, with div, w/o LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8,[],dims,stde);
    case 'LDFI' % Li's method, with div, with LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8,1,dims,stde);
    case 'LXXI' % Li's method, w/o div, w/o LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8,[],dims,stde,'lut');
    case 'LXFI' % Li's method, w/o div, with LPF, with interp
        TMOobj = TMO2025(16-sbin,'invert-interp',8,1,dims,stde,'lut');
end
end

function fid = openall(file,suffix)
fid = zeros(size(suffix));
for no = 1:numel(suffix)
    name = strcat(file,suffix{no},'.bin');
    [fid(no),msg] = fopen(name,'w');
    if fid(no) == -1
        fclose('all');
        error(msg)
    end
end
end
