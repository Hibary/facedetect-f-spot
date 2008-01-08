%DisplayFeature.m
function boxen = DisplayFeature(nI,nJ,B, varargin)
% Display feature B within an image of size nIxnJ
%
 %if (nI~=nJ)
 % warning('nI and nJ should be equal');
 % return;
 %end
 nI = nI+1; nJ = nJ + 1;
 L = tril(ones(nI,nI));
 A = zeros(nI*nJ);
 for iv = 1:nJ
   for jv = 1:iv;
    A((nI*(iv-1)+1):nI*iv,(nI*(jv-1)+1):nI*jv) = L;
   end;
 end;
 wts = B'*A;
 S = reshape(wts,[nI,nJ]);
 boxen = S(2:end,2:end);
 if nargin == 4
   ind = find(boxen==0);
   boxen = boxen + varargin{1};
 end
 imshow(boxen); %,...
           % [min(min(avgf)), max(max(avgf))],...
            %'notruesize');
 %drawnow;

