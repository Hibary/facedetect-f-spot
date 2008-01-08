function result = ApplyClassifier(f,img,theta,p)

    fx = ApplyFeature(f,img);
    h = 0;
    if ( fx*p < theta * p)
        h=1;
    else
        h=-1;
    end
    
    result = h;