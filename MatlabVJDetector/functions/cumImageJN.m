%cumImageJN.m
function I= cumImageJN(src)
% takes a 1x100 or 1x121 face
% interprets it as a 10x10 or 11x11 face
% gets a cumsum image
% returns it with original 1x100 or 1x121 dimensions
%
[height width] = size(src);
%side= numPix ^ .5 ;
%preI= reshape(preI,side,side) ;
%preI= cumsum(cumsum(preI,1),2) ;
%I = preI;
%I= reshape(preI,1,numPix);

% modified for compliance with the Torch library
% as in ipIntegralImage.cc
% 
            dst = zeros(height, width);
		    dst(1,1) = src(1,1);
			
                    %// first line
                    for x = 2:width
                        dst(1,x) = dst(1,x-1) + src(1,x);
                    end
                    for y = 2:height;
                    
                        line = src(y,1);

                        %// first element of line y
                        dst(y,1) = dst(y-1,1) + line;

                        for  x = 2:width;
                        
                                line = line + src(y, x);
                                dst(y, x) = dst(y-1, x) + line;
                        end
                    end
             I = dst;