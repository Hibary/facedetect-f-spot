%   +=======================================================================================+
%   |                                                                                       |
%   |   Face Detection,                                                                     |
%   |   detector program                                                                    |
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
%   |   This program uses the trained cascade to detect faces in the input image.           |
%   |   An attempt on merging mutiple detections of the same face is made in the last       |
%   |   step. The program uses a feature set defined in the file features.mat, and          |
%   |   in that doesn't comply with the V-J algorithm, because it doesn't use integral      |
%   |   images.                                                                             |
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
%

	addpath([pwd '/data']);
	addpath([pwd '/functions']);

	global f;
	global sc;
	global stages;
	global stage_alpha;
%	load('mojeKaskada2k.mat');
	%load('niepenwe.mat');
	%load('trening-MEGA.mat');
	load('features.mat');
	Itest=imread('data/testy/pos/10.jpg');
%    gaussianFilter = fspecial('gaussian', [7, 7], 0.8);
 %   Itest=imfilter(Itest, gaussianFilter, 'symmetric', 'conv');
	%Itest = img1;
	Iorig = Itest;
	%faces=getfaces('faces.pat',24,0);
	% size(Iorig)
%	scaleX = size(Iorig,2)/160;
%	scaleY = size(Iorig,1)/120;
    scaleX =4; %4;
    scaleY = 4; %4;
    Itest = imresize(Itest,0.25);
%	Itest=imresize(Itest, [120, 160]);
	%Itest = faces(1,:);
	%Itest = reshape(Itest,25,25);
	imshow(Itest);
	
	Itest=rgb2gray(Itest);
        	Itest = Itest(:,:,1);
%	Itest = histeq(Itest); % this is really needed for high contrast images
	
	Itest=double(Itest);
	
	%Itest= normImageF(Itest); % this is a very important step as well
	%figure,imshow(Itest,[])
	%Itest=cumImageJN(Itest);
	        
	
	[row col]=size(Itest);
	
	mindim=min(row,col)/3;
	rects=[];
	rectcount=0;

% this should be where we compute the integral image
% I don't know why it doesn't work - perhaps because the classifiers
% are trained to work with different thresholds (based upon integral
% images calculated in each subwindow
	dropped =0;
	for szWin = 20:5:mindim  % enlarge the window by 6px every step
	   for xplace=2:10:col-szWin % move the window by 10px x
	      for yplace=2:10:row-szWin % move it by 10px y as well
	
	        [Ichunk, rect]=imcrop(Itest,[xplace yplace szWin szWin]);
	        %Itest= padJN(Itest);
	
	        cropsize=25;
	        Ichunk=imresize(Ichunk,[cropsize,cropsize]);   %resizing the image, should resize the detector!
	
	        Ichunk=cumImageJN(Ichunk);     
	        Ichunk=reshape(Ichunk,1,(cropsize)^2);
	        result = RunCascade(Ichunk);
	        
	        if result >0
	            rectcount= rectcount + 1;
	            rect(1) = rect(1) * scaleX;
	            rect(2) = rect(2) * scaleY;
	            rect(3) = rect(3) * scaleX;
	            rect(4) = rect(4) * scaleY;
	            rect;
	            rects = [rects rect];
	
	            rectangle('Position', rect,'edgecolor','green');
	        else
	%            fprintf('+');
	            dropped = dropped +1;
	        end
	       
	      end
	   end
	end       % SIZE if
	rect
	
% here we will iterate throught the result set and try to resolve
% overlapping boxes. Since it's a lot easier to do using OOP I'll just keep
% this really basic.
	sprintf('dropped windows: %d accepted windows: %d', dropped, rectcount)
	%break;
	%disp('Found the following number of faces: ');
	%rectcount
	overlappingRects=0;
	[cnt cnt] = size(rects);
	imshow(Iorig);
	for i=1:4:cnt
	    overlaps = 0;
	    hasChild = 0;
	    for j=1:4:cnt
	        if i==j continue;
	        end
	       % if(is_equal(rects(i:(i+3)), rects(j:(j+3))))
	       %     overlappingRects = overlappingRects +1;
	       %    overlaps = overlaps+1;%
	            %sprintf('kwadraty %d i %d pokrywaja sie!', (i-1)/4, (j-1)/4)
	       %     break;
           overlaps=0;
           break;
	       if (is_inner(rects(j:(j+3)), rects(i:(i+3))))
	           overlappingRects = overlappingRects +1;
	            overlaps = overlaps+1;
	           % sprintf('%d jest w srodku %d!', (j-1)/4, (i-1)/4)
	            break;
            end
	    end
	    if(overlaps==0)
	                rectangle('Position', rects(i:(i+3)), 'edgecolor','red');
	end
    end
    rectangle('Position', [0 0 20 20], 'edgecolor', 'green');
    rectangle('Position', [0 0 mindim*scaleX mindim*scaleY],'edgecolor','blue');
	%overlappingRects
	%clear size;
	%size(rects);