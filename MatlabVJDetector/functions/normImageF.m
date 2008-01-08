%normImageF.m

function I= normImageF(I) ;
[r c]= size(I) ;
avgVal= sum(sum(I)) / (r*c) ;
subtrMat= repmat(avgVal, r, c) ;
I= I - subtrMat ;
sdI= std(reshape(I,r*c,1)) ;
I= I ./ repmat(sdI, r, c) ;
% if you want, use these to check mean==0 & stdev==1
%meanI= sum(sum(I)) / (r*c)
%stNormI= std(reshape(I,r*c,1))

