function mat2 = tmofoo(foo,mat1,sbin)
rows = size(mat1,1);
bits1 = round(log2(size(mat1,2)));
num1 = pow2(bits1);
mat1 = reshape(mat1,rows,num1);
mat1 = permute(mat1,[3 2 1]);
numd = pow2(sbin);
switch foo
    case 'interp'
        mat1 = [mat1; mat1(:,[2:num1 num1],:)];
        coef = [numd:-1:1; 0:numd-1]';
        mat2 = pagemtimes(coef,mat1);
        mat2 = bitshift(mat2,-sbin);
    case 'repmat'
        mat2 = repmat(mat1,numd,1);
end
mat2 = reshape(mat2,[],rows)';
