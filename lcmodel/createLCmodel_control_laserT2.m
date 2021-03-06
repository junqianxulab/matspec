function controlfilename = createLCmodel_control_laser(metabname,l1,l2,l3,preproc_dir)

ind=findstr(metabname,'_TE');
sss=metabname(ind:end);
ind = findstr(sss,'N');
echotime = sss(4:ind-1)


 basis_set_file_path = get_subdir_regex_files('/home/romain/data/spectro/Basis_set/Gosia/LASER',[echotime,'.*BASIS$'])


basis_set_file_path = char(basis_set_file_path);



do_water_scaling=0;
doecc=0;
TEMET=1;


[pathstr,filename ] = fileparts(metabname)

wd = fullfile(pathstr,preproc_dir)
if ~exist(wd)
  mkdir(wd)
end

rawname = metabname;
metabname = fullfile(wd,filename);

controlfilename=[metabname '.CONTROL'];

% create .CONTROL file for LCModel
disp(['Creating file ' metabname]); disp(' ')



fileid=fopen(controlfilename,'w');
fprintf(fileid,' $LCMODL\n');
fprintf(fileid,[' TITLE=''HIPO deprim''\n']);
fprintf(fileid,[' OWNER=''CENIR''\n']);
fprintf(fileid,[' PGNORM=''A4''\n']);

fprintf(fileid,[' FILBAS=''%s''\n'],basis_set_file_path);

fprintf(fileid,[' FILRAW=''' rawname '.RAW''\n']);
fprintf(fileid,[' FILPS=''' metabname  '.PS''\n']);
fprintf(fileid,[' FILCOO=''' metabname '.COORD''\n']);
fprintf(fileid,' LCOORD=31\n');
fprintf(fileid,[' FILPRI=''' metabname '.PRINT''\n']);
fprintf(fileid,' LPRINT=6\n');
%fprintf(fileid,[' FILTAB=''' metabname '.TAB''\n']);
%fprintf(fileid,' LTABLE=7\n');

 %FILTAB='Sujet07_E1_MC_L.TAB'
 %LTABLE = 7

fprintf(fileid,' NAMREL=''NAA''\n'); %give ratio over NAA
fprintf(fileid,' CONREL=10\n'); %11 mm give the attemp conc of NAA

if do_water_scaling
  
  %fprintf(fileid,' DOECC=T\n');
  fprintf(fileid,' DOWS=T\n');
  
  dd=dir([rawname,'*.H2O']);
  if length(dd)~=1
    error('can not find water referenc scan of %s',rawname)
  end

  % fprintf(fileid,' WCONC=40300\n');
  % fprintf(fileid,' ATTH2O=0.45\n');  %exp(-64/80)
  % fprintf(fileid,' ATTMET=0.7\n');   %exp(-64/300)*(1-exp(-3000/1500))

  fprintf(fileid,' WCONC=55555\n');
  fprintf(fileid,' ATTH2O=1\n');
  fprintf(fileid,' ATTMET=1\n');

  %fprintf(fileid,' WCONC=42400\n');
  %fprintf(fileid,' ATTH2O=0.34\n');
  %fprintf(fileid,' ATTMET=1\n');
  
  fprintf(fileid,[' FILH2O=''' fullfile(pathstr,dd.name) '''\n']);

  if doecc
    fprintf(fileid,' DOECC=T\n');
  end
  

end

%fprintf(fileid,' TRAMP=1\n VOLUME=7.2 \n');

if TEMET
  fprintf(fileid,' NCOMBI=5');
  fprintf(fileid,' CHCOMB(1) = ''NAA+NAAG''\n ');
  fprintf(fileid,' CHCOMB(2) = ''Cr-CH2+PCrCH2''\n ');
  fprintf(fileid,' CHCOMB(3) = ''Cr-CH3+PCrCH3''\n ');
  fprintf(fileid,' CHCOMB(4) = ''Glu+Gln''\n ');
  fprintf(fileid,' CHCOMB(5) = ''PCho+GPC''\n ');
  
  fprintf(fileid,' CHUSE1(1)=''NAA'',''CrCH2'',''CrCH3''\n');
%gosia proposition  fprintf(fileid,' CHUSE1(1)=''CrCH3'',''NAA'',''CrCH2''\n');

else

  fprintf(fileid,' NCOMBI=4');
  fprintf(fileid,' CHCOMB(1) = ''NAA+NAAG''\n ');
  fprintf(fileid,' CHCOMB(2) = ''Cr+PCr''\n ');
  fprintf(fileid,' CHCOMB(3) = ''Glu+Gln''\n ');
  fprintf(fileid,' CHCOMB(4) = ''PCho+GPC''\n ');
end


fprintf(fileid,' NEACH=50\n');
%fprintf(fileid,' NUSE1=4\n');
%fprintf(fileid,' CHUSE1(1)=''GABA'',''NAA'',''GLU'',''OCC_MM''\n');

fprintf(fileid,[' DEGZER= 0 \n']); %expected value of zero order phase corection
fprintf(fileid,' SDDEGZ=20.\n');    %freedom in zero order phase corection

%fprintf(fileid,' SDDEGZ=999.\n');
fprintf(fileid,[' DEGPPM=0\n']);   %expected value of first order phase correction
fprintf(fileid,' SDDEGP=20.0\n');  %standard deviation in expectation value of degppm 
%fprintf(fileid,' SDDEGP=0\n');

%fprintf(fileid,' NSIMUL=0\n');
%fprintf(fileid,' NSIMUL=13\n');

%fprintf(fileid,' SHIFMN=-0.2,-0.1\n');
%fprintf(fileid,' SHIFMX=0.3,0.3\n');

fprintf(fileid,' FWHMBA=0.0050\n');

fprintf(fileid,' RFWHM=2.5\n');

%no information in the user manual (Hidden Control Parameters)
fprintf(fileid,' DKNTMN=1\n');


fprintf(fileid,' PPMST=4.15\n');
%fprintf(fileid,' PPMEND=1\n');
fprintf(fileid,' PPMEND=1.6\n');


fprintf(fileid,' NSIMUL=0\n');
fprintf(fileid,'NRATIO=0\n');

fprintf(fileid,[l1,'\n']);
fprintf(fileid,[l2,'\n']);
fprintf(fileid,[l3,'\n']);
fprintf(fileid,' $END\n');

fclose(fileid);

