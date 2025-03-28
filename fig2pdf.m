function fig2pdf(name,dims,varargin)
set(gcf,'Name',name,'PaperUnits','inches',...
    'PaperSize',dims,'PaperPosition',[0 0 dims])
for k = 1:2:numel(varargin)
    obj = findall(gcf,'-property',varargin{k});
    set(obj,varargin{k},varargin{k+1})
end
if ~isempty(name)
    print(gcf,'-dpdf',name)
end
