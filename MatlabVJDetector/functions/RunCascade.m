function result = RunCascade(img)
global f;
global sc;
global stages;
global stage_theta

num_stages = size(stages,2);
clsf = 1;
%num_stages
for i=1:num_stages
    
    T = stages(i);
    
%    clsf : clsf+T-1
   if (RunStage(img,sc(clsf : clsf+T-1), stage_theta(i)) == -1)
%       fprintf('window dropped!');
       result = -1;
       return
   end
    clsf = clsf+T;
end
result = 1;