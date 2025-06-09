clear
close all
file = 'hallway2';
time = 2:2:10;
fnum = 8*30+1;
option = menu('TMO Visuals','HQVGA','VGA','HD');
switch option
    case 1
        font = 12; % Size for HQVGA format
    case 2
        font = 32; % Size for VGA format
    case 3
        font = 48; % Size for HD format
    otherwise
        error('Invalid selection.')
end
type = {'HEFX2','Hist. Eq. (sbin=2)','(a)';
    'LXFX2','TMO 2021 (sbin=2)','(B)';
    'LXFX8','TMO 2021 (sbin=8)','(c)';
    'LXFI8','TMO 2025 (sbin=8)','(d)'};
makeVideo(type,file,font,fnum)
makeImage(type,file,time,[8 8])
makeGraph(type([1 3 4],:),file,fnum,[6 4])

function makeVideo(type,file,font,fnum)
num = size(type,1);
m = floor(sqrt(num));
n = floor(num/m);
head = sprintf('Creating %d-by-%d video:',m,n);
dotdot(head,30)
vwrite = VideoWriter(file);
open(vwrite)
files = strcat(file,type(:,1),'.avi');
vread = cellfun(@VideoReader,files,'UniformOutput',false);
hasFrames = @(vread) cellfun(@hasFrame,vread);
readFrames = @(vread) cellfun(@readFrame,vread,'UniformOutput',false);
while all(hasFrames(vread))
    dotdot(true)
    fnum = fnum-1;
    frame = readFrames(vread);
    for k = 1:num
        text = sprintf('%s %s',lower(type{k,3}),type{k,2});
        frame{k} = insertText(frame{k},[1 1],text,...
            'Font','Arial','FontSize',font);
    end
    frame = reshape(frame,n,m)';
    frame = cell2mat(frame);
    if fnum == 0
        imwrite(frame,strcat(file,'.png'))
    end
    writeVideo(vwrite,frame)
end
dotdot(false)
close(vwrite)
end

function makeImage(type,file,time,dims)
m = size(type,1);
n = numel(time);
[frame,fom] = getFrame(type,file,time);
zoom = imread(strcat(file,'.png'));
[nr,nc,~] = size(zoom);
frame = imresize(frame,[NaN nc]);
frame = repmat(frame,1,1,3);
[rows,cols,~] = size(frame);
xstep = cols/n;
ystep = rows/m;
x = round(xstep/2:xstep:cols);
y = nr+round(ystep/2:ystep:rows);
imshow([zoom; frame])
addMerit(x+round(xstep/2),y+round(ystep/2),fom)
xticks(x)
xticklabels(time)
xlabel('Time (s)')
yticks(y)
yticklabels(lower(type(:,3)))
axis on
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end

function addMerit(x,y,fom)
[m,n] = size(fom);
isref = fom == 1;
for i = 1:m
    for j = 1:n
        if isref(i,j)
            label = 'ref. ';
        else
            label = sprintf('%4.2f ',fom(i,j));
        end
        text(x(j),y(i),label,'FontName','Arial','FontSize',8,...
            'Color','y','Horizontal','right','Vertical','bottom')
    end
end
assert(all(sum(isref,1) == 1))
end

function makeGraph(type,file,fnum,dims)
[pmax,pmf,map,sbin] = getVars(type(:,1),file);
pmf = tmorepmat(pmf,sbin(3),2);
hist = {sprintf('Scene Hist. (sbin=%d)',sbin(3));
    sprintf('Percv. Hist. (sbin=%d)',sbin(3));
    sprintf('Contr. Limit (sbin=%d)',sbin(3))};
p = size(pmf,1);
nz = any(pmf(:,:,2) > 0);
a = find(nz,1,'first');
b = find(nz,1,'last');
ends = [a-1 b-1];
bins = ends(1):ends(2);
lmax = min(max(pmf(:,:,2),[],2));
rmax = max(cellfun(@(T) max(T(:)),map));
dotdot('Creating graph animation:',30)
file = strcat(file,'Var');
video = VideoWriter(file);
open(video)
for k = 1:p
    dotdot(true)
    map1 = tmorepmat(map{1}(k,:),sbin(1),2);
    map2 = tmorepmat(map{2}(k,:),sbin(2),2);
    map3 = tmointerp(map{3}(k,:),sbin(3));
    yyaxis left
    h = plot(bins,pmf(k,a:b,1),':',...
        bins,pmf(k,a:b,2),'-',...
        ends,[pmax pmax],'--');
    rgb = get(gca,'ColorOrder');
    set(h,'LineWidth',1,'Color',rgb)
    axis([ends 0 lmax])
    xlabel('Video Input')
    ylabel('Hist. Bin Value')
    yyaxis right
    h = plot(bins,map1(a:b),':',...
        bins,map2(a:b),'-.',...
        bins,map3(a:b),'-');
    rgb = get(gca,'ColorOrder');
    set(h,'LineWidth',1,'Color',rgb)
    ylim([0 rmax])
    ylabel('Tone Function')
    legend(hist{:},type{:,2},'Location','NorthEast')
    frame = getframe(gcf);
    writeVideo(video,frame)
    if k == fnum
        savefig(file)
    end
end
dotdot(false)
close(video)
if fnum <= p
    close
    openfig(file);
end
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end

function [frame,fom] = getFrame(type,file,time)
m = size(type,1);
n = numel(time);
head = sprintf('Creating %d-by-%d image:',m,n);
dotdot(head,n)
file = strcat(file,type(:,1),'.avi');
vread = cellfun(@VideoReader,file,'UniformOutput',false);
frame = cell(m,n);
for i = 1:m
    for j = 1:n
        dotdot(true)
        vread{i}.CurrentTime = time(j);
        frame{i,j} = readFrame(vread{i});
    end
end
dotdot(false)
isupper = cellfun(@(s) strcmp(s,upper(s)),type(:,3));
fom = getMerit(frame,find(isupper,1));
for k = 1:numel(frame)
    frame{k} = addBorder(frame{k});
end
frame = cell2mat(frame);
end

function fom = getMerit(frame,iref)
[m,n] = size(frame);
fom = zeros(m,n);
for i = 1:m
    for j = 1:n
        fom(i,j) = ssim(frame{i,j},frame{iref,j});
    end
end
end

function [pmax,pmf,map,sbin] = getVars(type,file)
assert(startsWith(type{1},'HEFX'))
assert(startsWith(type{2},'LXFX'))
assert(startsWith(type{3},'LXFI'))
vars = load(file);
name = strcat('pmax',type{3});
pmax = vars.(name);
name = strcat('pmf',type{3});
pmf = vars.(name);
map = cell(1,3);
sbin = zeros(1,3);
for k = 1:3
    name = strcat('map',type{k});
    map{k} = uint8(vars.(name));
    sbin(k) = sscanf(type{k}(end),'%d');
end
end

function frame2 = addBorder(frame1)
[m,n] = size(frame1);
frame2 = zeros(m+2,n+2,class(frame1));
frame2(2:m+1,2:n+1) = frame1;
end
