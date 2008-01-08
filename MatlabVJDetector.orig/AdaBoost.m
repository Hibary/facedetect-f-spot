% AdaBoost
function [selClas, theta, d, fn,fp] = AdaBoost ( x, xN, xNN, y, T )
global f;
global fN;
global fArr;
global valSet;
global nonfaces;
    wface=0.5*1/xN; 
    wNoface=0.5*1/xNN;

w=[wface*ones(1,xN) wNoface*ones(1,xNN)];
used = zeros(1,fN);
mminErrorArray = ones(1,T);
fNbestArray = zeros(1,T);
alphaArray = zeros(1,T);
pArray = zeros(1,T);
thetaArray = zeros(1,T);
okCount =zeros(1,T);
falsePos =zeros(1,T);
falseNeg =zeros(1,T);
theta = 0;
result = zeros(1,(xN+xNN));
for i = 1:fN
    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0);
end
%selClas = zeros(1,T);
D = 0.0;
for t=1:T
%			/// 2. For each feature train a classifier h_j which is restricted to using a single feature
%			/// The error is evaluated with respect to wt, ej = S_i w_i |h_j(x_i) - y_i|.
ok =0;
   wsum=sum(w);
   w=w/wsum;

        if(D > 0.99)  break;
         end
        
disp('next round!!');
pause(1);
fIdx =0;
hT = 0;
img_count = xN+xNN;
mminErrorArray(t)=1.01;
   for fNcount=1:fN
       if(used(fNcount)==1) continue;
       end
      faces1=[];
      nofaces1=[];
      % for each feature fNcount, examples are sorted based on feature
      % value

         for i=1:img_count
            fout=ApplyFeature(f(:,fArr(fNcount)),x(i,:));
            if y(i)==1
               faces1=[faces1 fout];
             else
               nofaces1=[nofaces1 fout];
           end
        end
        fx = [faces1 nofaces1];
        [fx fxIdx]         = sort(fx); 
      % end: for each feature fNcount, examples are sorted based on feature
      % end: value

      sc(fNcount) = SingleFeatureClassifier(f(:,fArr(fNcount)),fxIdx,fx,w,y);
      sc(fNcount).f = fArr(fNcount);
      sc(fNcount).idx = fNcount;

     % sc(fNcount) = GetClassifierError(sc(fNcount),f,x,y);
      if(sc(fNcount).error < mminErrorArray(t))
          mminErrorArray(t) = sc(fNcount).error;
          selClas(t) = sc(fNcount);
    %      fprintf('\tselected a %d %% error classifier\n',selClas(t).error*100)
      end
      % if(mod(fNcount,100)==0) disp(fNcount);
      % end
    end % end iterating through features.
    % for each classifier, calculate it's error
   h = zeros(1,xN+xNN);
    used(selClas(t).idx)=1;
  fprintf('feature selected %d, error rate %d%%\n', double(selClas(t).f),selClas(t).error*100) 
 %  used(selClas(t).f) = 1;
    hT = selClas(t).h;
    fn=0;
   beta = mminErrorArray(t) / (1-mminErrorArray(t));

    fp=0;
   for xNcount=1:(xN+xNN)
       h=ApplyClassifier(f(:,selClas(t).f),x(xNcount,:),selClas(t).theta, selClas(t).p);
       result(xNcount) = result(xNcount)+(selClas(t).alpha * h);

       w(xNcount)=w(xNcount)*exp( -1 * y(xNcount) * selClas(t).alpha * h );
   end


   theta = theta + 0.5*selClas(t).alpha;
  [err fn fp D] = TestStage(selClas,theta);
%   [fp 1/(5*T)]
   if(fp < 1/(5*T)) break;
   end
end
% update theta, to achieve higher detection rate !
theta
%find the stage's false positives :

if(D<0.98 && fp<1/(T))
count = size(selClas,2);
fx = zeros(1,size(valSet,1));

for i=1:size(valSet,1) % for each example
    for j=1:count % run it through the classfs in the stage
       h=ApplyClassifier(f(:,selClas(j).f),valSet(i,:),selClas(j).theta, selClas(j).p);
       if(h==1)
           fx(i) = fx(i) + h*selClas(j).alpha;
       end
   end

end
% this is supposed to correct the threshold, so we get more false
% positives.
%theta = min(fx);    
    [fx fxIdx] = sort(fx);
   theta = fx(1);
 %end
theta
end % end of threshold adjust - only when D<smth
%stepp = 0.1*theta;
[err fn fp d] = TestStage(selClas,theta);
fprintf('\terror %d%%\t fN %d%%\t fP %d%%\t D %d%%\n',err*100,fn*100,fp*100,d*100);
nonfaces = [];
for i=xN+1:xN+xNN
    if(RunStage(x(i,:),selClas,theta)==1)
        nonfaces = [nonfaces ; x(i,:) ];
    end
end
