% test stage
function [err, fn, fp, d] = TestStage(  cls,theta)
    global f;
%    global cls;
    global valSet;
    global valSetY;
    global valSetPos;
    ok = 0;
    fn = 0;
    fp = 0;
    pos = 0;
    for i=1:size(valSet,1)
        H=  RunStage(valSet(i,:),cls,theta);
        if(H==valSetY(i))
            if(H==1) pos = pos+1; 
            end;
           ok = ok +1;
       elseif(H==1 && valSetY(i)==-1)
               fp = fp+1;
       else fn = fn+1;
       end
    end
    err = (fp+fn) / size(valSet,1);
    fn = fn / size(valSet,1);
    fp = fp / size(valSet,1);
    d = pos / valSetPos;
    