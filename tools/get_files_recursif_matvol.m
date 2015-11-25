function F=get_files_recursif(in_dir)

F=[];
  
for nbdir =1:size(in_dir,1)
  cur_dir = deblank(in_dir(nbdir,:));
  
  DD = dir(cur_dir);
  DD=DD(3:end);

  for i=1:size(DD,1)

    if ( DD(i).isdir )
      F = [F;get_files_recursif( fullfile(cur_dir,DD(i).name) )];
    else 
      [pathstr,filename,ext] = fileparts(DD(i).name);
      if ~isempty(ext)
%	if  ~all(ext == '.log') & ~all(ext == '.txt')
    
	if  strcmp(ext,'.dic')|strcmp(ext,'.MRDC')|strcmp(ext,'.dcm') 
	  F = [F;{fullfile(cur_dir,DD(i).name)}];
	end
      else
 	F = [F;{fullfile(cur_dir,DD(i).name)}];
      end
    end
  end
end

  
