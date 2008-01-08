%   +=======================================================================================+
%   |                                                                                       |
%   |   Face Detection,                                                                     |
%   |   training algorithm                                                                  |
%   |                                                                                       |
%   +---------------------------------------------------------------------------------------+
%   |                                                                                       |
%   |   author: Andrzej Wytyczak-Partyka                                                    |
%   |   email :	apart (at) iapart (dot) net                                                 |
%   |   date  : Jul 16th 2007                                                               |
%   |                                                                                       |
%   +---------------------------------------------------------------------------------------+
%   |                                                                                       |
%   |   Synopsis:                                                                           |
%   |   ----------                                                                          |
%   |   This is the main training program. It calls AdaBoost.m to train individual stages   |
%   |   of the cascade.                                                                     |
%   |   Most of variable names correspond with [1].                                         |
%   |   This program has been written as a part of my contribution to the F-Spot project,   |
%   |   within the Google Summer of Code 2007.                                              |
%   |                                                                                       |
%   |   Problems:                                                                           |
%   |   1. Too many false positives detected. Maybe something wrong with boosting?          |
%   |   2. Can't seem to find a weight normalization step after the stage has been selected?|
%   |                                                                                       |
%   |   History:                                                                            |
%   |   Jan 8,2008 - change to comply with Table 2, p146 [1]                                |
%   |   Jan 7,2008 - finished cleaning & commenting the code                                |
%   |                                                                                       |
%   |   References:                                                                         |
%   |   ------------                                                                        |
%   |   [1]	Robust Real-Time Face Detection, P. Viola, M. Jones, IJCV 2004                  |
%   |   [2]	Hamed Masnadi-Shirazi's code                                                    |
%   |       http://www-cse.ucsd.edu/classes/fa04/cse252c/projects/hamed.pdf                 |
%   |   [3] Training data by Imad Khoury et al                                              |
%   |       http://khoury.imad.googlepages.com/computervision(comp358b)project              |
%   |                                                                                       |
%   +=======================================================================================+


	clear all
	tic
	
	addpath([pwd '/data']);
	addpath([pwd '/functions']);
	
	load('moje.mat');
	load('features.mat');
	disp('data loaded!');
	
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
	global fNMax;
	global ktory;
	global prevFeats;
	
	ktory = 1;
	prevFeats = zeros(0);
		
	% Use the whole training set, or just parts of it
	
	valSetPos 		= size(faces,1);
	valSetNeg 		= size(nonfaces,1);
	random_faces 	= faces;%([int16(unifrnd(1,size(faces,1),1,valSetPos))],:); %faces; %
	random_nonfaces = nonfaces;%([int16(unifrnd(1,size(nonfaces,1),1,valSetNeg))],:); %nonfaces; %
	valSet  		= [random_faces ; random_nonfaces];
	valSetY 		= [ones(1,valSetPos) -1*ones(1,valSetNeg) ];
	
%	Weights for face/nonface examples
	xN  = valSetPos
	xNN = valSetNeg
	
	
	
	fArr = 1:size(f,2);
	fN	 = size(fArr,2);
	
% 	Labels
	y=[ones(1,xN) -1*ones(1,xNN)];
	


% 	Init the variables
	t		= 0;
	T		= 70; % max number of rounds
	fNMax 	= 5000;
	pArray 	= zeros(1,T);
	okCount = zeros(1,T);
	falsePos 		= zeros(1,T);
	falseNeg 		= zeros(1,T);
	stage_theta 	= zeros(1,100);
	mminErrorArray	= ones(1,T);
	fNbestArray 	= zeros(1,T);
	alphaArray		= zeros(1,T);
	thetaArray 		= zeros(1,T);
	
		
	
	for i=1:fNMax
	    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0);
	end
	
	nonfacesOrig = nonfaces;
	nonfaces = nonfaces(1:xNN,:);
	
	
	Fi 	= 1.0;
	Fi1 = 1.0;   % a helper var to keep the previous Fi value
	Di	= 1.0;
	i	= 0;
	ff 	= 0.001; % the maximum acceptable false positive rate per layer
	d	= 0.999; % the minimum acceptable detection rate per layer
	T	= -4;
	n	= 1;
	Fp	= 1.0;
	
	Ftarget = 0.00001;
	stages 	 = [];
	selClass = zeros(1,T);
	globalFp = 1.0;
	
	
%	Cascade training loop 
%	proceed until we reach the target false neg or false pos goal
%	or if we run out of example images

	while Fi > Ftarget
		i = i+1;
	    fprintf('next stage!\n');
	    
	    xNN = size(nonfaces,1);

%		Stop if we ran out of negative examples
%		if(xNN==0) break; end

%		Fix the labels
	    y=[ones(1,xN) -1*ones(1,xNN)];
	    used = zeros(1,fN);
	    
%		Initialize the weights as 1/2m and 1/2l
%    	w=[wface*ones(1,xN) wNoface*ones(1,xNN)];
%		X is a matrix with each row being one of the test images
	    x = [faces(1:xN,:); nonfaces(1:xNN,:)];    
	
	    Fi = Fi1;
	    st=0;
	    fprintf(' false positives promoted = %d \n' ,xNN);

%		Stage training loop
	    while Fi > ff *Fi1
		
		    n = n+1;
%			T=T+5;

% 			Start Adaboost
%			set Fi - number of false negatives
%			and Fp - number of false positives
%			of the returned stage

		    [scs theta D Fi Fp] = AdaBoost  (x, xN, xNN, y, n);
			
		
		
			%    [err fn fp D] = TestStage( scs, theta);
			%    return
		
		 	%      D = p/xN;
			%      Fi = Fi/size(valSet,1);
		    
		    sums = sum(stages);
		    stage_theta(n) = theta;
		    
		    for i=1:size(scs,2)
		        sc(sums+i) = scs(i);
		    end
		    
		    stages = [stages size(scs,2)];
		    n=n+1;
		    fprintf('stage %d completed with Fi = %d%% and %d false positives', n-1,Fi*100,size(nonfaces,1) );
		end
%		End of the stage training loop

	end
% 	End of the cascade training loop
	
	ttoc=toc
	%loc= 'C:\Documents and Settings\BAGHIYE\Desktop\Special topics Vision FALL 04\PROJECT\' ;
	%save([loc 'TrainResults.mat'], 'fNbestArray','thetaBestArray','pBestArray','alpha_t_Array','T');
	
%	Save results

	save('mojeKaskada2k.mat','sc','stages','stage_theta');