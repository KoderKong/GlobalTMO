function map2 = tmointerp(map1,bitsd)
assert(isa(map1,'uint8'))
assert(isscalar(bitsd) && fix(bitsd) == bitsd && bitsd >= 0)
bits1 = round(log2(numel(map1)));
num1 = pow2(bits1);
map1 = reshape(map1,1,num1);
map1 = [map1; map1([2:num1 num1])];
numd = pow2(bitsd);
coef = [numd:-1:1; 0:numd-1]';
map2 = coef*double(map1);
map2 = bitshift(map2,-bitsd);
map2 = uint8(map2(:));
