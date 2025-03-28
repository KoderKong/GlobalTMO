classdef CISnoFPN
    properties (SetAccess = protected)
        L2Y % Monotonic nonlinear response function
        Y2L % Monotonic nonlinear stimulus function
        stde % Standard deviation of residual error
    end
    methods
        function CIS = CISnoFPN(Xi,Yijk,maxY)
            assert(ceil(log2(maxY)) <= 16)
            Yij = sum(Yijk,4)/size(Yijk,4);
            Eijk = Yijk-Yij;
            dof = numel(Yijk)-numel(Yij);
            Eijk = Eijk(:);
            CIS.stde = sqrt(2*(Eijk'*Eijk)/dof);
            Yij = Yij(:,:);
            Yi = sum(Yij,2)/size(Yij,2);
            Li = log(Xi);
            CIS.Y2L = pchip(Yi,Li);
            CIS.L2Y = pchip(Li,Yi);
        end
        function Yj = image(CIS,Xj)
            Yj = ppval(CIS.L2Y,log(Xj));
            Ej = randn(size(Yj))*CIS.stde;
            Yj = uint16(Yj+Ej);
        end
        function Yj = ideal(CIS,Xj)
            Yj = ppval(CIS.L2Y,log(Xj));
            Yj = uint16(Yj);
        end
        function Wj = tonemap(CIS,Yj,varargin)
            [~,Wj] = stmo(Yj,CIS.Y2L,varargin{:});
        end
    end
end
