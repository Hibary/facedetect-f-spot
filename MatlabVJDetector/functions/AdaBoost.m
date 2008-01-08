%   +=======================================================================================+
%   |                                                                                       |
%   |   Face Detection,                                                                     |
%   |   boosting algorithm                                                                  |
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
%   |   This function is called by the trainCascade program and is supposed to train a      |
%   |   strong classifier that will be later used within the cascade. in the last           |
%   |   step.                                                                               |
%   |   This program has been written as a part of my contribution to the F-Spot project,   |
%   |   within the Google Summer of Code 2007.                                              |
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
	
	
	% AdaBoost
	% function [selClas, theta, d, fn,fp, fpos] = AdaBoost ( x, xN, xNN, y, n )
	%
	%	INPUT :
	%				x	- array of [positive; negative] examples, one in each row
	%				xN	- number of positive examples
	%				xNN	- number of negative examples
	%				y	- labels
	%				n	- maximum number of features in the classifier
	%
	%	OUTPUT :
	%				selClas	- classifier array (stage of a cascade) 
	%				theta	- the threshold of the classifier
	%				d		- detection rate as returned by TestStage
	%				fn		- number of false negatives as returned by TestStage
	%				fp		- number of false positives as returned by TestStage
	%				fpos	- return the false positives themselves, to feed to next stages 
	
	function [selClas, theta, d, fn,fp] = AdaBoost ( x, xN, xNN, y, T )
	global f;
	global fN;
	global fArr;
	global valSet;
	global nonfaces;
	
%	Initialize weights
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
	
% 	Initialize the structure that will hold the classifiers

	for i = 1:n
	    sc(i) = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx', 0);
	end
	
	%selClas = zeros(1,T);
	D = 0.0;
	
%	Proceed until the max classifier count is reached
%	this has to be changed wrt to Table 1., p142 of [1]
%	(I think)

	for t=1:n
	
%		If detection rate over 0.99 is achieved - stop.
		if(D > 0.99)  break; end;
		ok =0;
			
%	 2. For each feature train a classifier h_j which is restricted to using a single feature
%	 The error is evaluated with respect to wt, ej = S_i w_i |h_j(x_i) - y_i|.



%	Normalize the weights to form a distribution
		wsum=sum(w);
		w=w/wsum;


        
		disp('next round!!');
		pause(1);
		
		fIdx =0;
		hT = 0;
		img_count = xN+xNN;
		mminErrorArray(t)=1.01;

%		Start iterating through features
	
		for fNcount=1:fN
			if(used(fNcount)==1) continue;	end;
			
			faces1=[];
			nofaces1=[];
			
%			for each feature fNcount, examples are sorted based on feature
%			value
	
	        for i=1:img_count
	            fout=ApplyFeature(f(:,fNcount),x(i,:));
	            if y(i)==1
	               faces1=[faces1 fout];
	             else
	               nofaces1=[nofaces1 fout];
	           end
	        end
	        fx = [faces1 nofaces1];
	        [fx fxIdx]         = sort(fx); 
% 			end: for each feature fNcount, examples are sorted based on feature
% 			end: value
	
			sc(fNcount) = SingleFeatureClassifier(f(:,fNcount),fxIdx,fx,w,y);
			sc(fNcount).f = fNcount;
			sc(fNcount).idx = fNcount;
	
	     % sc(fNcount) = GetClassifierError(sc(fNcount),f,x,y);
	     
			if(sc(fNcount).error < mminErrorArray(t))
				mminErrorArray(t) = sc(fNcount).error;
				selClas(t) = sc(fNcount);
%		        fprintf('\tselected a %d %% error classifier\n',selClas(t).error*100)
			end
	      % if(mod(fNcount,100)==0) disp(fNcount);
	      % end
	    end 
%	 	End iterating through features.

%		For each classifier, calculate it's error
		fn=0;
	    fp=0;
		h = zeros(1,xN+xNN);
	    used(selClas(t).idx)=1;
		fprintf('feature selected %d, error rate %d%%\n', double(selClas(t).f),selClas(t).error*100) 
	 %  used(selClas(t).f) = 1;
	    hT = selClas(t).h;
		beta = mminErrorArray(t) / (1-mminErrorArray(t));
	    
		for xNcount=1:(xN+xNN)
	       h=ApplyClassifier(f(:,selClas(t).f),x(xNcount,:),selClas(t).theta, selClas(t).p);
	       result(xNcount) = result(xNcount)+(selClas(t).alpha * h);
	       w(xNcount)=w(xNcount)*exp( -1 * y(xNcount) * selClas(t).alpha * h );
		end
	
	
		theta = theta + 0.5*selClas(t).alpha;
		[err fn fp D] = TestStage(selClas,theta);
	%   [fp 1/(5*T)]
		if(fp < 1/(5*T)) break;   end
		
	end
	% End of the for t=1:T outer loop
	
% 	Update theta, to achieve higher detection rate !
	theta
%	Find the stage's false positives :
	
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
% 		this is supposed to correct the threshold, so we get more false
% 		positives.
		% theta = min(fx);
	    
		[fx fxIdx] = sort(fx);
		theta = fx(1);
	 	theta
	end 
% 	End of threshold adjust - only when D<smth

	%stepp = 0.1*theta;


%	Finalize, test the stage and print the results.
	
	[err fn fp d] = TestStage(selClas,theta);
	fprintf('\terror %d%%\t fN %d%%\t fP %d%%\t D %d%%\n',err*100,fn*100,fp*100,d*100);
	
	fpos = [];
	
	for i=xN+1:xN+xNN
	    if(RunStage(x(i,:),selClas,theta)==1)
	        fpos = [fpos ; x(i,:) ];
	    end
	end
	