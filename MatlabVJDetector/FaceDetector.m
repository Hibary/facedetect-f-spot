% FaceDetector.m
% This is based on Hamed Masnadi-Shirazi's code
% for a project he did during his studies at ucsd. 
% http://www-cse.ucsd.edu/classes/fa04/cse252c/projects/hamed.pdf 
% and the Imad Khoury et al who claim this to be
% their own and do not mention Hamed 
% I used the training data provided by Imad.
% http://khoury.imad.googlepages.com/computervision(comp358b)project
% 
% I've optimized the code somewhat, made it more readable
% added comments and suggestions and bit more compliance with the OpenCV 
% and the original paper by Viola & Jones
% 

clear all

load('features.mat');

Itest=imread('PIC00.jpg');

Itest=rgb2gray(Itest);
Itest = histeq(Itest); % this is really needed for high contrast images
Itest=imresize(Itest, [240, 320]);

Itest=double(Itest);
Itest= normImageF(Itest); % this is a very important step as well
figure,imshow(Itest,[])

[row col]=size(Itest);

mindim=min(row,col);
rects=[];
rectcount=0;
for size = 24:6:mindim  
   for xplace=2:10:col-size
      for yplace=2:10:row-size

        [Ichunk, rect]=imcrop(Itest,[xplace yplace size size]);
       
        cropsize=24;
        
        Ichunk=imresize(Ichunk,[cropsize,cropsize]);   %resizing the image, should resize the detector!
        Ichunk= padJN(Ichunk);
        Ichunk=cumImageJN(Ichunk);
        Ichunk=reshape(Ichunk,1,(cropsize+1)^2);

        
        result = RunCascade(Ichunk,f,xplace,yplace,rect);
        if result >0
            disp('Face found');
            rectcount= rectcount + 1;
            rect
            rects = [rects rect];
            rectangle('Position', rect);
        end
      end
   end
end       % SIZE if

% here we should iterate throught the result set and try to resolve
% overlapping boxes

disp('Found the following number of faces: ');
rectcount
%clear size;
%size(rects);