%padJN.m
function I= padJN(preI)
% takes a face image in as a column vector
% and returns it as a vector where it's been padded
% with an extra left column and top row as zeros
sz = size(preI);
%sz(1)
%if sz(1)==1
%    length= max(size(preI));
%    side= length.^.5 ;
%    preI= reshape(preI,side,side) ;
%    bigI= zeros(side+1, side+1) ;%
%    bigI(2:end, 2:end)= preI ;
%    I= reshape(bigI, 1, (side+1)^2) ;
%else
    bigI =zeros(sz(1)+1, sz(2)+1);
    bigI(2:end, 2:end) = preI;
    I=bigI;
    %end