% AdaBoost training

clear all
tic

load('moje.mat');
disp('faces loaded!');

global xN;
global xNN;
xN=1000;
xNN=1000;

%weights for face/nonface examples
wface=0.5*1/xN; 
wNoface=0.5*1/xNN;

%initialize the weights as 1/2m and 1/2l
w=[wface*ones(1,xN) wNoface*ones(1,xNN)];

%a matrix with each row being one ofthe test images
x=[faces(1:xN,:) ; nonfaces(1:xNN,:)];

load('features.mat');
fArr=[int16(unifrnd(1,39000,1,1000))]
fN=size(fArr,2);
% labels
y=[ones(1,xN) -1*ones(1,xNN)];
used = zeros(1,fN);

T=70; % number of rounds
% init those bitches
mminErrorArray = ones(1,T);
fNbestArray = zeros(1,T);
alphaArray = zeros(1,T);
pArray = zeros(1,T);
thetaArray = zeros(1,T);
okCount =zeros(1,T);
falsePos =zeros(1,T);
falseNeg =zeros(1,T);
for i = 1:fN
    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0);
end
selClass = zeros(1,T);
for t=1:T
%			/// 2. For each feature train a classifier h_j which is restricted to using a single feature
%			/// The error is evaluated with respect to wt, ej = S_i w_i |h_j(x_i) - y_i|.
   wsum=sum(w);
   w=w/wsum;
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

      sc(fNcount) = SingleFeatureClassifier(f(:,fArr(fNcount)),fxIdx,x,w,y);
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
   beta = mminErrorArray(t) / (1-mminErrorArray(t));
   for xNcount=1:(xN+xNN)
       h=ApplyClassifier(f,x(xNcount,:),selClas(t).theta, selClas(t).p);
%           w(xNcount)=w(xNcount)*beta;
          w(xNcount)=w(xNcount)*exp( -1 * y(xNcount) * selClas(t).alpha * h );
       end
      
   end


end % END of t-th round

ttoc=toc
%loc= 'C:\Documents and Settings\BAGHIYE\Desktop\Special topics Vision FALL 04\PROJECT\' ;
%save([loc 'TrainResults.mat'], 'fNbestArray','thetaBestArray','pBestArray','alpha_t_Array','T');
