function [nz,pmf] = tmopmf(Yj,bits)
assert(isscalar(bits) && fix(bits) == bits)
Yovf = pow2(bits);
Yj = round(Yj(:));
assert(all(Yj >= 0 & Yj < Yovf))
Yj = sort(Yj);
novel = logical([1; diff(Yj)]);
index = find([novel; true]);
nz = struct('val',Yj(novel),'pmf',diff(index));
if nargout > 1
    pmf = zeros(Yovf,1);
    pmf(double(nz.val)+1) = nz.pmf;
end
