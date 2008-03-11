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
%   |                          | |   ____ (_)                      | |              | |     |
%   |     __ _ _ __   __ _ _ __| |_ / __ \ _  __ _ _ __   __ _ _ __| |_   _ __   ___| |_    |
%   |    / _` | '_ \ / _` | '__| __/ / _` | |/ _` | '_ \ / _` | '__| __| | '_ \ / _ \ __|   |
%   |   | (_| | |_) | (_| | |  | || | (_| | | (_| | |_) | (_| | |  | |_ _| | | |  __/ |_    |
%   |    \__,_| .__/ \__,_|_|   \__\ \__,_|_|\__,_| .__/ \__,_|_|   \__(_)_| |_|\___|\__|   |
%   |         | |                   \____/        | |                                       |
%   |         |_|                                 |_|                                       |
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
	
	
    load('cumimages-28-01-08.mat');
 %   load('moje.mat');
 %   load('images.mat');
	load('features.mat');
%	load('fff.mat');
%	f = fff;%
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
    global used;
	ktory = 1;
	prevFeats = zeros(0);
		
	% Use the whole training set, or just parts of it
   faces = cumfaces;
   nonfaces = cumnonfaces;
    random_faces 	= faces(1500:1800,:);%;[int16(unifrnd(1,size(faces,1),1,valSetPos))],:); %faces; %
	random_nonfaces = nonfaces(3500:3800,:);%([int16(unifrnd(1,size(nonfaces,1),1,valSetNeg))],:); %nonfaces; %
%    faces 			= faces(1:1500,:);
%	nonfaces		= nonfaces(1:3500,:);
	xN              = size(faces,1);
	xNN             = size(nonfaces,1);


    
    valSetPos 		= size(random_faces,1);
	valSetNeg 		= size(random_nonfaces,1);
    
    valSet  		= [random_faces ; random_nonfaces];
	valSetY 		= [ones(1,valSetPos) -1*ones(1,valSetNeg) ];
	
%	Weights for face/nonface examples

  	%w=[wface*ones(1,xN) wNoface*ones(1,xNN)];
	
	fArr = 1:size(f,2);
	fN	 = size(fArr,2);
	
% 	Labels
	y=[ones(1,xN) -1*ones(1,xNN)];
	


% 	Init the variables
	t				= 0;
	T				= 70; 	% max number of rounds
	fNMax 			= 5000;
	pArray 			= zeros(1,T);
	okCount 		= zeros(1,T);
	falsePos 		= zeros(1,T);
	falseNeg 		= zeros(1,T);
	stage_alpha 	= zeros(1,100);
	mminErrorArray	= ones(1,T);
	fNbestArray 	= zeros(1,T);
	alphaArray		= zeros(1,T);
	thetaArray 		= zeros(1,T);
	
		
	
	for i=1:fNMax
	    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0, 'beta', 0);
	end
	
	nonfacesOrig = nonfaces;
	nonfaces 	 = nonfaces(1:xNN,:);
	
	
	Fi 	= 1.0;
	Fi1 = 1.0;   			% a helper var to keep the previous Fi value
	Di	= 1.0;
	i	= 0;
	ff 	= 0.01; 			% the maximum acceptable false positive rate per layer
	d	= 0.99; 			% the minimum acceptable detection rate per layer
	T	= -4;
	n	= 0;
	Fp	= 1.0;
	
	Ftarget = 0.00001;
	stages 	 = [];			% holds the number of classifiers in individual stages of the cascade
	selClass = zeros(1,T);
	globalFp = 1.0;
	
	
%	Cascade training loop 
%	proceed until we reach the target false neg or false pos goal
%	or if we run out of example images
	cache(1:100)=0;
%	cache(1) = 128; %63; %88;
%    cache(2) = 508;
	stage_counts = [2 5 10 20 20];
%	while Fi > Ftarget
	used = zeros(1,size(f,2));
    while i<5
		i = i+1;
	    fprintf('next stage!\n');
	    
	    xNN = size(nonfaces,1)

%		Stop if we ran out of negative examples
		if(xNN==0) break; end

%		Fix the labels
	    y=[ones(1,xN) -1*ones(1,xNN)];

	    
%		Initialize the weights as 1/2m and 1/2l
%    	w=[wface*ones(1,xN) wNoface*ones(1,xNN)];
%		X is a matrix with each row being one of the test images
	    x = [faces(1:xN,:); nonfaces(1:xNN,:)];    
	
	    Fi1 = Fi;
	    st=0;
        n=stage_counts(i)-1;    
	    fprintf(' false positives promoted = %d \n' ,xNN);

%		Stage training loop
%	    while Fi > ff *Fi1 && n <= stage_counts(i)
        while n == stage_counts(i)-1
		    n = n+1

% 			Start Adaboost
%			set Fi - number of false negatives
%			and Fp - number of false positives
%			of the returned stage

%			Use the results of previous iteration of the inner loop - don't calculate from scratch.
						
		%	if(exist('sums'))
		%		for i = 1:1; %sums:size(sc,2)
		%			cache = [cache sc(i).f];
		%		end
		%	end
				  
		    [scs alpha D Fi Fp fpos] = AdaBoost  (x, xN, xNN, y, n, cache);
            
			%    [err fn fp D] = TestStage( scs, theta);
			%    return
		
		 	%      D = p/xN;
			%      Fi = Fi/size(valSet,1);
		    
		    sums = sum(stages);
		    stage_alpha(i) = alpha;

		 
		    for z=1:size(scs,2)
		        sc(sums+z) = scs(z);
		    end

% TODO:		Decrease threshold for the i-th classifier until the current cascaded
%			classifier has a detection rate of at least d * D_(i-1)

			[err Fi Fp D new_thetas ss] = TestStage(scs, alpha);

%           Adjust the confidence level of the classifier

            fprintf('error on validation set: %2.2f, Fn=%2.2f Fp=%2.2f\n', err,Fi,Fp);
		    fprintf('adjusting alpha........................\n');
          %  1/xNN
		    while (D < 0.97)%d * Di) 
		    	alpha = alpha - 0.1;
			    [err Fi Fp D new_thetas,ss] = TestStage(scs, alpha);      
            end
            fprintf('error on validation set: %2.2f, Fn=%2.2f Fp=%2.2f\n', err,Fi,Fp);
		    stage_alpha(i) = alpha;
		    stages = [stages size(scs,2)];
%		    n=n+1;

		end
%		End of the stage training loop


%		Add the false positives to the negative example set !

% TODO:	Check if this is done right !
% TODO: Should we add just the false-positives or both fp & the original negative examples

        fprintf('updating example sets...\n');
      	fpos=[];
        wneg = [];
    	for z=xN+1:xN+xNN
            if(RunStage(x(z,:),scs,stage_alpha(i))==1)
                fpos = [fpos ; x(z,:) ];
%                wneg = [wneg w(z)];
            end
        end
       
	fprintf('stage %d completed with Fi = %d%% and %d false positives (%2.2f%%)\n', i,Fi*100,size(fpos,1),Fp );
		nonfaces = fpos;
		xNN = size(nonfaces,1);
		x = [faces(1:xN,:); nonfaces(1:xNN,:)];
 %    	w = [w(1:xN) wneg];
	end
% 	End of the cascade training loop
		
%	Save results
	save('mojeKaskada2k.mat','sc','stages','stage_alpha');