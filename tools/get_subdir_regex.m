function [o no]=get_subdir_regex(indir,reg_ex,varargin)

if ~exist('indir'), indir=pwd;end
if ~exist('reg_ex'), reg_ex=('graphically');end

if length(varargin)>0
  o = get_subdir_regex(indir,reg_ex);
  for ka=1:length(varargin)
    o = get_subdir_regex(o,varargin{ka});
  end
  return
end

if ~iscell(indir), indir={indir};end

if ischar(reg_ex)
  if strcmp(reg_ex,'graphically')
    o={};
    for nb_dir=1:length(indir)
      dir_sel = spm_select(inf,'dir','select a directories','',indir{nb_dir});
      dir_sel = cellstr(dir_sel);
      for kk=1:length(dir_sel)
	o{end+1} = dir_sel{kk};
      end
    end
    return
  end
end 


if ~iscell(reg_ex), reg_ex={reg_ex};end

o={};
no={};

for nb_dir=1:length(indir)
  od = dir(indir{nb_dir});
  od = od(3:end);
  found_sub=0;
  
  for k=1:length(od)
    
    for nb_reg=1:length(reg_ex)      
      if strcmp(reg_ex{nb_reg}(1),'-')
%	reg_ex{nb_reg}(1)=''
	if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}(2:end)))
	  break
	end
      end
      
      if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}))
	o{end+1} = fullfile(indir{nb_dir},od(k).name,filesep);
	found_sub=1;
	break% (to avoid that 2 reg_ex adds the same dir
      end
      
    end
    
  end
  
  if ~found_sub
    no{end+1} = indir{nb_dir};
  end
end
