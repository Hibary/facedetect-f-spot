function sc = SingleFeatureClassifier(f,fxIdx,fx,w,y)
        global xN;
        global xNN;
      
        Tp = sum(w(1:xN));
        Tn = sum(w(xN+1:xN+xNN));
        Sp = 0;
        Sn = 0;
        e1 = sum(w(1:xN));
        min1 = e1;
        e2 = 1-e1;
        min2 = e2;
        min1Idx=1;
        min2Idx=1;
        minE = 1.0;
            sc = struct('f',0, 'theta', 0,'p', 0,'alpha',0, 'error',0, 'fp',0, 'fn',0, 'h',[], 'idx',0);
      % For each element in the sorted list, four sums are maintained Tp,
      % Tn, Sp, Sn
        for i=1:(xN+xNN)
            if(y(fxIdx(i))==1)
%                Sp = Sp+w(fxIdx(i));
                e1 = e1-w(fxIdx(i));
                else
                e1 = e1+w(fxIdx(i));
                %Sn = Sn+w(fxIdx(i));
            end
            % the error for a threshold which splits the range between the
            % current and previous example in the sorted list is e=min(e1,e2)
%            e1 = (Sp + (Tn - Sn)); % Sp - suma poz Sn suma net, Tn
%            e2 = (Sn + (Tp - Sp));
%            e = min(  ,  );
            e2 = 1 -e1;        
            
            if(e1<min1)
                min1=e1;
                min1Idx = i;
            end
            
            if(e2<min2)
                min2=e2;
                min2Idx = i;
            end
        end % end iterating through examples
         
        if(min1 < min2)
            sc.p = 1;
            minE = min1;
       %     sc.theta = ApplyFeature(f,x(fxIdx(min1Idx),:));
       sc.theta = fx(min1Idx);
       %     sc.f = fArr(fNcount);
            sc.error = min1;
            mIdx = min1Idx;
        else
            sc.p = -1;
            minE = min2;
%%            sc.theta = ApplyFeature(f,x(fxIdx(min2Idx),:));
                   sc.theta = fx(min2Idx);
            sc.error = min2;
        
            mIdx = min2Idx;
        end
        beta = sc.error / double(1-sc.error);
        beta = beta + 0.00000001;
        sc.alpha = -log(beta);
%    sc.error
       
        % we probably have found the threshold for the given feature
        % fNcount thus forming a classifier