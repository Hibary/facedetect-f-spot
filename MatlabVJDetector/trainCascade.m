% AdaBoost training

clear all
tic

load('moje.mat');
disp('faces loaded!');

global valSet;
global valSetY;
global valSetPos;
global valSetNeg;
global xN;
global xNN;
global f;
global fN;
global fArr;
global nonfaces;

valSetPos = 500;
valSetNeg = 500;
random_faces = faces([int16(unifrnd(1,size(faces,1),1,valSetPos))],:);
random_nonfaces = nonfaces([int16(unifrnd(1,size(nonfaces,1),1,valSetNeg))],:);
valSet = [random_faces ; random_nonfaces];
valSetY = [ones(1,valSetPos) -1*ones(1,valSetNeg) ];

xN=1000;
xNN=5000;

%weights for face/nonface examples

load('features.mat');
fArr=[int16(unifrnd(1,39000,1,1000))]
fN=size(fArr,2);
% labels
y=[ones(1,xN) -1*ones(1,xNN)];

stage_theta = zeros(1,100);
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
t=0;

for i=1:fN
    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0);
end

xNN
nonfacesOrig = nonfaces;
nonfaces = nonfaces(1:xNN,:);

stages = [];
selClass = zeros(1,T);
globalFp=1.0;
Fi = 1.0;
Fi1 = 1.0;
ff = 0.3;
T=-4;
n=1;
Fp =1.0;
while Fi > 0.01 || Fp > 0.01

    fprintf('next stage!\n');
    
    xNN = size(nonfaces,1);
%    xN
    if(xNN==0) break;
    end
    y=[ones(1,xN) -1*ones(1,xNN)];
    used = zeros(1,fN);
    %initialize the weights as 1/2m and 1/2l
%    w=[wface*ones(1,xN) wNoface*ones(1,xNN)];
    %a matrix with each row being one ofthe test images
    x=[faces(1:xN,:); nonfaces(1:xNN,:)];    
%    size(x)
    Fi = Fi1;
    st=0;
    fprintf(' false positives promoted = %d \n' ,xNN);
    while Fi > ff *Fi1

    % start Adaboost
    T=T+5;
    [scs theta D Fi Fp] = AdaBoost  (x, xN, xNN, y, T);



%    [err fn fp D] = TestStage( scs, theta);
%    return

 %      D = p/xN;
%       Fi = Fi/size(valSet,1);
    stage_theta(n) = theta;
    sums=sum(stages);
    for i=1:size(scs,2)
        sc(sums+i) = scs(i);
    end
    stages = [stages size(scs,2)];
    n=n+1;
    fprintf('stage %d completed with Fi = %d%% and %d false positives', n-1,Fi*100,size(nonfaces,1) );
end
end

ttoc=toc
%loc= 'C:\Documents and Settings\BAGHIYE\Desktop\Special topics Vision FALL 04\PROJECT\' ;
%save([loc 'TrainResults.mat'], 'fNbestArray','thetaBestArray','pBestArray','alpha_t_Array','T');