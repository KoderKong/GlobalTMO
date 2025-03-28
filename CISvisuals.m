clear
load CISmodels
makeGraph(logAPS,'logAPS',[6 4])
makeGraph(logDPS,'logDPS',[6 4])

function makeGraph(CISobj,file,dims)
Li = CISobj.L2Y.breaks;
Yi = ppval(CISobj.L2Y,Li);
Xi = exp(Li);
yyaxis left
h = semilogx(Xi,Yi,'.-');
rgb = get(gca,'ColorOrder');
set(h,'LineWidth',1,'Color',rgb)
xlabel('Scene Luminance (cd/m^2)')
ylabel('Pixel Response')
yyaxis right
h = semilogx(Xi([1 end]),CISobj.stde([1 1]),'--');
ylabel('Noise Std. Dev.')
ymax = pow2(ceil(log2(CISobj.stde)));
ylim([0 ymax])
rgb = get(gca,'ColorOrder');
set(h,'LineWidth',1,'Color',rgb)
fig2pdf(file,dims,'FontName','Arial','FontSize',10,...
    'LineWidth',0.5,'MarkerSize',4)
close
end
