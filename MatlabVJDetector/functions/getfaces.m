% GETFACES   Displays the faces in a faces file.
%    GETFACES(FILENAME, IMGSIZE, IMGDIR) creates an interfaces for
%    viewing the faces in the database specified by the FILENAME file
%    path. IMGSIZE specifies the size of the dimensions of the face
%    images. IMGDIR is 1 if the entries are ordered first along the width
%    of the image, and then along the height (i.e. we store all the
%    entries in row 1 first before proceeding to row 2). Otherwise,
%    IMGDIR is 0 which indicates that the entries are stored first along
%    the height of the image.
%
%    The database created by Mike Jones (mjones@merl.com). For this
%    database, IMGSIZE is 24 and IMGDIR is 0 since the pixel entries are
%    first ordered along the height of the image. 
%
%    This function can also be used to view the non-faces database, or
%    any other image database in the same format.
% 
%    Date: August 26, 2002
%    Authors:
%    - Peter Carbonetto, University of British Columbia Computer Science
%      Deptartment, pcarbo@cs.ubc.ca
%    - Matt Flagg, Georgia Tech College of Computing, mflagg@cs.gatech.edu 

function faces = getfaces (fileName, imgSize, imgDir)

  % get the file handle
  fid = fopen(fileName);
  if fid == -1,
    disp('Unable to open file');
  else,
      
    % File opened successfully.
 
    % Start from position 0 and find out how many images are in the
    % file.
    fseek(fid, 0, 'eof');
    numImages = ftell(fid) / (imgSize * imgSize);
    fseek(fid, 0, 'bof');
 
    % Make the 3D array.
    faces = zeros(numImages, 25*25);
    for i = 1:1
      [A count] = fread(fid, [imgSize imgSize], 'uint8');
      A=A';
      A = imresize(A, [25 25], 'bicubic');
%        imshow(uint8(A));
 %       pause(2);
      A=cumImageJN(A);
        
%        imshow(uint8(A'));
%        pause(2);

      A = reshape(A, 1, 25*25);
%      if imgDir == 1,
%	faces(i,:) = A;
%      else,
	faces(i,:) = A;
    %      end;
    end;

    R = 1;
    figure(1);
    clf;
      
  end; % if 