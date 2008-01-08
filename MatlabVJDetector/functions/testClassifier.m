function Error = testClassifier(threshold, parity, posHist, negHist, posHistWeights, negHistWeights)
%           if fout * pArr{j}(stage_count) < thetaArr{j}(stage_count) * pArr{j}(stage_count)
%             h(stage_count)=1;
%           else
%              h(stage_count)=-1;
%           end           
%           stage_sum = stage_sum + alphaArr{j}(stage_count) * h(stage_count);
x=[posHist negHist];
w=[posHistWeights negHistWeights];
k=2;
%xN=size(x,2)
global xN;
global xNN;

%size(x)
%size(w)
y=[ones(1,xN) -1*ones(1,xNN)];
Error =0;
for xNcount=size(x,2);
    
             % x contains the feature applied to the image
         %    if(used(xNcount)) continue;
             if x(xNcount)*parity < threshold*parity
                h=1;
            else
                h=-1;
            end
           %if h==1 && y(xNcount)==-1   % false positive, that's not so bad - we will still examine this window
              % Error = Error +1*w(xNcount);
               %elseif h==-1 && y(xNcount)==1 % false negative - this is worse - we are dropping the window
              % Error = Error +5*w(xNcount);
               %else
            % Error = Error + 0;
             %      end
                    Error = Error + (h
                    Error = Error - ( -1 + 0.5*( abs( h + y(xNcount) ) ) )*w(xNcount);
end