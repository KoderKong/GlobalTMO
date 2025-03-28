function img2 = imredim(img1,dim2)
dim1 = size(img1);
head = dim1(1:2);
if isequal(head,dim2)
    img2 = img1;
else
    tail = dim1(3:end);
    img2 = zeros([dim2 tail],class(img1));
    scale = max(dim2./head);
    box = [];
    for k = 1:prod(tail)
        img = imresize(img1(:,:,k),scale,'nearest');
        if isempty(box)
            pos = round((size(img)-dim2)/2);
            box = [flip(pos)+1 flip(dim2)-1];
        end
        img2(:,:,k) = imcrop(img,box);
    end
end
