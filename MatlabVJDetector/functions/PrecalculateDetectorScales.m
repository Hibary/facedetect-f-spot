function scaledF = PrecalculateDetectorScales(f,scale)

    global stages;
    global sc;
    
    featCount = sum(stages);
    usedFeats = zeros(1,featCount);
    
    for i=1:featCount
        usedFeats(i) = sc(i).f;
    end

    nWidth = floor(25*scale);
    nHeight = floor(25*scale);
    scaledF = sparse(nWidth*nHeight, 39150);

    for z = 1:featCount
  %      z
        cFeat = reshape(f(:,usedFeats(z)),25,25);
        ind = find(cFeat')
        sF = sparse(nWidth,nHeight);
        for i=1:size(ind)
            rows=floor((ind(i)-1)/25);
            cols = ind(i) - rows*25;     
%            if(cols==0) cols=1;end
            sF(floor(rows*scale)+1,floor((cols-1)*scale)+1) = cFeat(rows+1,cols);
            scaledF(:,usedFeats(z)) = reshape(sF,nWidth*nHeight,1);
 %           cFeat(rows+1,cols)
        end
    end