function dicomanon(filename_in, filename_out, varargin)
%DICOMANON  Anonymize DICOM file.
%
%    DICOMANON(FILE_IN, FILE_OUT) removes confidential medical
%    information from the DICOM file FILE_IN and creates a new file
%    FILE_OUT with the modified values.  Image data and other
%    attributes are unmodified.
%
%    DICOMANON(..., 'keep', FIELDS) modifies all of the confidential
%    data except for those listed in FIELDS, which is a cell array of
%    field names.  This syntax is useful for keeping metadata that does
%    not uniquely identify the patient but is useful for diagnostic
%    purposes (e.g., PatientAge, PatientSex, etc.).
%
%      Note: Keeping certain fields may compromise patient
%      confidentiality.
%
%    DICOMANON(..., 'update', ATTRS) modifies the confidential data and
%    updates particular confidential data.  ATTRS is a structure.  The
%    field names of ATTRS are the attributes to preserve, and the
%    structure values are the attribute values.  Use this syntax to
%    preserve the Study/Series/Image hierarchy or to replace one a
%    specific value with a more generic property (e.g., remove
%    PatientBirthDate but keep a computed PatientAge). 
%
%    For information about the fields that will be modified or removed,
%    see DICOM Supplement 55 from <http://medical.nema.org/>.
%
%    Examples:
%
%      % (1) Remove all confidential metadata from a file.
%      dicomanon('patient.dcm', 'anonymized.dcm')
%
%      % (2) Create a training file.
%      dicomanon('tumor.dcm', 'tumor_anon.dcm', ...
%         'keep', {'PatientAge', 'PatientSex', 'StudyDescription'})
%
%      % (3) Anonymize a series of images, keeping the hierarchy.
%      values.StudyInstanceUID = dicomuid;
%      values.SeriesInstanceseriesUID = dicomuid;
%
%      d = dir('*.dcm');
%      for p = 1:numel(d)
%          dicomanon(d(p).name, sprintf('anon%d.dcm', p), ...
%             'update', values)
%      end
%
%    See also DICOMINFO, DICOMWRITE.

% Copyright 2005-2006 The MathWorks, Inc.


% Process input arguments
args = parseInputs(varargin{:});
preserveAttr('', args, 'reset');

% Get the original data.
metadata = dicominfo(filename_in);
[X, map] = dicomread(metadata);

% Update fields to preserve.
metadata = updateAttrs(metadata, args.update); 

% Make new UIDs for attributes that must be different than the input.
SOPInstanceUID = dicomuid;
StudyUID = dicomuid;
SeriesUID = dicomuid;
FrameUID = dicomuid;
SyncUID = dicomuid;
SrUID = dicomuid;

% Anonymize the data.
%
% For type 1 attributes - Use changeAttr with a new value.
% For type 2 attributes - Use changeAttr with an empty value.
% For type 3 attributes - Use removeAttr().

metadata = removeAttr(metadata, '0008', '0014', args);
metadata = changeAttr(metadata, '0008', '0018', SOPInstanceUID, args);
metadata = changeAttr(metadata, '0008', '0050', '', args);
metadata = changeAttr(metadata, '0008', '0080', '', args);
metadata = removeAttr(metadata, '0008', '0081', args);
metadata = changeAttr(metadata, '0008', '0090', '', args);
metadata = removeAttr(metadata, '0008', '0092', args);
metadata = removeAttr(metadata, '0008', '0094', args);
metadata = removeAttr(metadata, '0008', '1010', args);
metadata = removeAttr(metadata, '0008', '1030', args);
metadata = removeAttr(metadata, '0008', '103E', args);
metadata = removeAttr(metadata, '0008', '1040', args);
metadata = removeAttr(metadata, '0008', '1048', args);
metadata = changeAttr(metadata, '0008', '1050', '', args);
metadata = removeAttr(metadata, '0008', '1060', args);
metadata = removeAttr(metadata, '0008', '1070', args);
metadata = removeAttr(metadata, '0008', '1080', args);
metadata = changeAttr(metadata, '0008', '1155', SOPInstanceUID, args);
metadata = removeAttr(metadata, '0008', '2111', args);
metadata = changeAttr(metadata, '0010', '0010', '', args);
metadata = changeAttr(metadata, '0010', '0020', '', args);
metadata = changeAttr(metadata, '0010', '0030', '', args);
metadata = removeAttr(metadata, '0010', '0032', args);
metadata = changeAttr(metadata, '0010', '0040', '', args);
metadata = removeAttr(metadata, '0010', '1000', args);
metadata = removeAttr(metadata, '0010', '1001', args);
metadata = removeAttr(metadata, '0010', '1010', args);
metadata = removeAttr(metadata, '0010', '1020', args);
metadata = removeAttr(metadata, '0010', '1030', args);
metadata = removeAttr(metadata, '0010', '1090', args);
metadata = removeAttr(metadata, '0010', '2160', args);
metadata = removeAttr(metadata, '0010', '2180', args);
metadata = removeAttr(metadata, '0010', '21B0', args);
metadata = removeAttr(metadata, '0010', '4000', args);
metadata = update_0018_1000(metadata, args);  % See tech ref.
metadata = removeAttr(metadata, '0018', '1030', args);
metadata = changeAttr(metadata, '0020', '000D', StudyUID, args);
metadata = changeAttr(metadata, '0020', '000E', SeriesUID, args);
metadata = changeAttr(metadata, '0020', '0010', '', args);  % See tech ref.
metadata = changeAttr(metadata, '0020', '0052', FrameUID, args);
metadata = changeAttr(metadata, '0020', '0200', SyncUID, args);
metadata = removeAttr(metadata, '0020', '4000', args);
metadata = removeAttr(metadata, '0040', '0275', args);
metadata = changeAttr(metadata, '0040', 'A124', SrUID, args);
metadata = removeAttr(metadata, '0040', 'A730', args);  
metadata = removeAttr(metadata, '0088', '0140', args);  % See tech ref.
metadata = changeAttr(metadata, '3006', '0024', FrameUID, args);
metadata = changeAttr(metadata, '3006', '00C2', FrameUID, args);

% Write the new data file.
if (~isempty(map))
    dicomwrite(X, map, filename_out, metadata, 'createmode', 'copy');
else
    dicomwrite(X, filename_out, metadata, 'createmode', 'copy');
end



function metadata = update_0018_1000(metadata, args)
% Update (0018,1000) which can be either type 2 or 3 depending on SOP Class.

thisGroup        = '0018';
thisElement      = '1000';
mediaStorageName = dicom_name_lookup('0002', '0002');

% Assume that if the transfer syntax isn't present, it's safe to remove.
if (~isfield(metadata, mediaStorageName))
    metadata = removeAttr(metadata, thisGroup, thisElement, args);
else
    switch (metadata.(mediaStorageName))
    case '1.2.840.10008.5.1.4.1.1.481.7'
        % Only type 2 in RT Treatment Summary Record Storage.
        metadata = changeAttr(metadata, thisGroup, thisElement, '', args);
    otherwise
        metadata = removeAttr(metadata, thisGroup, thisElement, args);
    end
end


        
function metadata = changeAttr(metadata, group, element, newValue, args)
%CHANGEATTR  Update an attribute's value.

name = dicom_name_lookup(group, element);

if (preserveAttr(name, args))
    return
end

if ((~isempty(name)) && (isfield(metadata, name)))
    metadata.(name) = newValue;
end



function metadata = removeAttr(metadata, group, element, args)
%REMOVEATTR  Remove an attribute.

name = dicom_name_lookup(group, element);

if (preserveAttr(name, args))
    return
end

if ((~isempty(name)) && (isfield(metadata, name)))
    metadata = rmfield(metadata, name);
end



function metadata = updateAttrs(metadata, values)
%UPDATEATTRS  Update metadata with user-specified values.

if (~isstruct(values))
    return
end

fields = fieldnames(values);

for p = 1:numel(fields)
    metadata.(fields{p}) = values.(fields{p});
end



function args = parseInputs(varargin)
%PARSEINPUTS  Parse input arguments to DICOMANON.

args.update = struct([]);
args.keep = {};

params = fieldnames(args);

p = 1;
while (p <= nargin)
    
    if (~ischar(varargin{p}))
        error('dicomanon:badParam', 'Parameter names must be strings.');
    end
    
    idx = strmatch(lower(varargin{p}), params);
    
    if (isempty(idx))
        error('dicomanon:unknownParam', ...
              'Unrecognized parameter "%s".', varargin{p});
    elseif (numel(idx) > 1)
        error('dicomanon:ambiguousParam', ...
              'Ambiguous parameter "%s".', varargin{p});
    else
        args.(params{idx}) = varargin{p + 1};
    end
    
    p = p + 2;
    
end



function tf = preserveAttr(name, args, varargin)

persistent preserveFields;

% If there are three arguments, set up for future inquiries.
if (nargin == 3)
   
    % Keep track of the fields to preserve.
    if (isempty(args.keep))
        
        preserveFields = fieldnames(args.update);
        
    elseif (isempty(args.update))
        
        preserveFields = args.keep;
        
    else
        
        preserveFields = cat(2, {args.keep{:}}, fieldnames(args.update)');
        
    end

    if (isempty(name))
        return
    end
    
end

% Look for the field in the fields to preserve.
tf = ~isempty(strmatch(name, preserveFields, 'exact'));

