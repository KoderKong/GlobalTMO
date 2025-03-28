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
    'LXFX2','TMO 2021 (sbin=2)','(b)';
    'LXFX8','TMO 2021 (sbin=8)','(c)';
    'LXFI8','TMO 2025 (sbin=8)','(d)'};
makeVideo(type,file,font,fnum)
makeImage(type,file,time,[8 4])
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
    fnum = fnum-1;
    frame = readFrames(vread);
    for k = 1:num
        frame{k} = insertText(frame{k},[1 1],type{k,2},...
            'Font','Arial','FontSize',font);
    end
    frame = reshape(frame,n,m)';
    frame = cell2mat(frame);
    if fnum == 0
        imwrite(frame,strcat(file,'.png'))
    end
    writeVideo(vwrite,frame)
    dotdot(true)
end
close(vwrite)
dotdot(false)
end

function makeImage(type,file,time,dims)
m = size(type,1);
n = numel(time);
frame = getFrame(type,file,time);
[rows,cols] = size(frame);
xstep = cols/n;
ystep = rows/m;
x = round(xstep/2:xstep:cols);
y = round(ystep/2:ystep:rows);
imshow(frame)
xticks(x)
xticklabels(time)
xlabel('Time (s)')
yticks(y)
yticklabels(type(:,3))
ylabel('Method')
axis on
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end

function makeGraph(type,file,fnum,dims)
[pmax,pmf,map,sbin] = getVars(type(:,1),file);
pmf = tmorepmat(pmf,sbin(3),2);
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
    yyaxis left
    h = plot(bins,pmf(k,a:b,1),':',...
        bins,pmf(k,a:b,2),'-',...
        ends,[pmax pmax],'--');
    rgb = get(gca,'ColorOrder');
    set(h,'LineWidth',1,'Color',rgb)
    axis([ends 0 lmax])
    xlabel('Video In')
    ylabel('Hist. Bin Value')
    yyaxis right
    map1 = tmorepmat(map{1}(k,:),sbin(1),2);
    map2 = tmorepmat(map{2}(k,:),sbin(2),2);
    map3 = tmointerp(map{3}(k,:),sbin(3));
    h = plot(bins,map1(a:b),':',...
        bins,map2(a:b),'-.',...
        bins,map3(a:b),'-');
    rgb = get(gca,'ColorOrder');
    set(h,'LineWidth',1,'Color',rgb)
    ylim([0 rmax])
    ylabel('Tone Function')
    legend('Scene Histogram','Percv. Histogram',...
        'Histogram Ceiling',type{:,2},'Location','West')
    frame = getframe(gcf);
    writeVideo(video,frame)
    dotdot(true)
    if k == fnum
        savefig(file)
    end
end
close(video)
dotdot(false)
if fnum <= p
    close
    openfig(file);
end
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end

function frame = getFrame(type,file,time)
m = size(type,1);
n = numel(time);
head = sprintf('Creating %d-by-%d image:',m,n);
dotdot(head,n)
file = strcat(file,type(:,1),'.avi');
vread = cellfun(@VideoReader,file,'UniformOutput',false);
frame = cell(m,n);
for i = 1:m
    for j = 1:n
        vread{i}.CurrentTime = time(j);
        frame{i,j} = readFrame(vread{i});
        frame{i,j} = addBorder(frame{i,j});
        dotdot(true)
    end
end
frame = cell2mat(frame);
frame = addBorder(frame);
dotdot(false)
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
