%cumImageJN.m
function I= cumImageJN(preI)
% takes a 1x100 or 1x121 face
% interprets it as a 10x10 or 11x11 face
% gets a cumsum image
% returns it with original 1x100 or 1x121 dimensions
%
numPix= max(size( preI )) ;
side= numPix ^ .5 ;
%preI= reshape(preI,side,side) ;
preI= cumsum(cumsum(preI,1),2) ;
I = preI;
%I= reshape(preI,1,numPix);

