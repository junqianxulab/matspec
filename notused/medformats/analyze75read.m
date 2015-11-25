function I = analyze75read(varargin)
%ANALYZE75READ Read image file of Mayo Analyze 7.5 data set.
%
%   I = ANALYZE75READ(FILENAME) reads the image data from the IMG file of
%   an Analyze 7.5 format data set (a pair of FILENAME.HDR and FILENAME.IMG
%   files).  For single-frame images, I is an M-by-N array where M is the
%   number of rows and N is the number of columns. For multi-dimensional
%   images, I can be an M-by-N-by-O or M-by-N-by-O-by-P array where M is
%   the number of rows, N is the number of columns, O is the number of
%   slices per volume and P is the number of volumes or time points. The
%   data type of I is consistent with the image data type specified in 
%   the metadata obtained from the header file. 
%
%   I = ANALYZE75READ(INFO) reads the image data from the IMG file 
%   referenced in the metadata structure INFO.  The INFO structure is a
%   valid metadata structure which may be obtained using the ANALYZE75INFO
%   function.  
%
%   ANALYZE75READ does not alter the orientation of the data provided in
%   the IMG file.
%
%   Example 1
%   ---------
%   Use ANALYZE75READ to retrieve the data array I from the image file
%   CT_HAND.img. This file may be obtained from the following URL:
%   http://www.radiology.uiowa.edu/downloads/
% 
%       I = analyze75read('CT_HAND');
%       % Since the default ANALYZE orientation is LAS (radiological
%       % orientation), we flip the data for correct image display
%       I = flipdim(I,1);
%       % Selecting frames 51 to 56 of I and reshaping it for MONTAGE 
%       J = reshape(I(:,:,51:56),[size(I,1) size(I,2) 1 6]);
%       montage(J);
%   
%   Example 2
%   ---------
%   Call ANALYZE75READ with the metadata obtained from the header file
%   using ANALYZE75INFO. 
%
%       metadata = analyze75info('CT_HAND.hdr');
%       I = analyze75read(metadata);
%
%   Class support
%   -------------
%   I can be logical, uint8, int16, int32, single, or double. Complex and
%   RGB data types are not supported.
%
%   See also ANALYZE75INFO.

%   Copyright 2005 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2006/06/15 20:10:29 $

% Check the number of input arguments.
iptchecknargin(1,1,nargin,mfilename);

% Parse input arguments.
[metadata, ImgFilename, userSupplied] = parseInputs(varargin{:});

% Open the IMG file.
ByteOrder = metadata.ByteOrder;
fid = analyze75open(ImgFilename, 'img', 'r', ByteOrder);

% Read the IMG file.
I = readImgFile(fid, metadata, userSupplied);

% Close the IMG file
fclose(fid);

    
%%%
%%% Function parseInputs
%%%
function [metadata, ImgFilename, userSupplied] = parseInputs(varargin)

% Check if input argument is a string or a struct.
FirstArg = varargin{1};
switch class(FirstArg)
    case 'char'
        % Filename has been provided.
        % Get metadata struct.
        metadata = analyze75info(FirstArg);
        % Flag to indicate that metadata struct was not supplied by
        % user. 
        userSupplied.metadata = false;  
    case 'struct'
        % Metadata struct has been provided.
        metadata = FirstArg;
        userSupplied.metadata = true;
    otherwise
        eid = 'Images:analyze75read:invalidInputArgument';
        msg = ['Input argument to ANALYZE75READ must be a filename' ...
                ' or a valid metadata struct'];
        error(eid, msg);
end  % switch

% Check if Metadata struct has fields Filename, ByteOrder and
% ImgDataType.
try
    Filename = metadata.Filename;
    ByteOrder = metadata.ByteOrder;
    ImgDataType = metadata.ImgDataType;
catch
    if userSupplied.metadata
        oldmsgstr = lasterr;
        eid = 'Images:analyze75read:invalidMetadataStruct';
        msg = ['Invalid METADATA struct provided: ' oldmsgstr];
        error(eid,msg);
    else
        rethrow(lasterror);
    end  % if

end  % try-catch

% Check if ImgDataType is an unsupported image datatype.
switch ImgDataType
    case {'DT_BINARY','DT_UNSIGNED_CHAR','DT_SIGNED_SHORT', ...
            'DT_SIGNED_INT', 'DT_FLOAT', 'DT_DOUBLE'}
        % Valid Datatypes. Do nothing.
    otherwise 
        % Display error message for DT_COMPLEX, DT_RGB and any
        % unrecognized image datatype. 

        eid = 'Images:analyze75read:unsupportedImageDatatype';
        msg = '"%s" is an unsupported image datatype';
        error(eid, msg, ImgDataType);
end  % switch

% Construct Image filename using Filename obtained from Metadata
% struct.
[pname fname ext] = fileparts(Filename);
ImgFilename = fullfile(pname, [fname '.img']);


    
%%%
%%% Function readImgFile
%%%   
function I = readImgFile(fid, metadata, userSupplied)
 
try
    cols    = double(metadata.Dimensions(1));
    rows    = double(metadata.Dimensions(2));
    slices  = double(metadata.Dimensions(3));
    volumes = double(metadata.Dimensions(4)); 
catch
    fclose(fid);
    if userSupplied.metadata
        oldmsgstr = lasterr;
        eid = 'Images:analyze75read:invalidMetadataStruct';
        msg = ['Invalid METADATA struct provided: ' oldmsgstr];
        error(eid,msg);
    else
        rethrow(lasterror);
    end  % if

end  % try-catch

% SizeVector describes the final size of the data array I.
SizeVector = [rows cols slices volumes];

% SizeVectorMATLAB is used to ensure that the data is read in correctly
% in MATLAB since the data will be read columnwise.
SizeVectorMATLAB = [cols rows slices volumes];

% Compute number of elements to be read.
count = prod(SizeVector);

% Obtain PrecisionString for reading in the data in the right format.
PrecisionString = convertDataType(metadata.ImgDataType);

% Call freadVerified correctly with above PrecisionString
A = freadVerified(fid, count, PrecisionString);
% Rearrange data to correct dimensions as data is read columnwise in
% MATLAB.  
I = correctOrientation(A, SizeVector, SizeVectorMATLAB);

    
%%%
%%% Function correctOrientation
%%%   
function I = correctOrientation(A, SizeVector, SizeVectorMATLAB)
   
% A is vector of data. Reshape it to an array of size SizeVectorMATLAB
% to correctly represent the data.
TempArray = reshape(A, SizeVectorMATLAB);

% Rearrange the dimensions of the TempArray to interchange rows and
% columns. 
TempArray = permute(TempArray, [2 1 3 4]);

% Reshape TempArray to size SizeVector
I = reshape(TempArray, SizeVector);


%%%
%%% Function convertDatatype
%%%
function PrecisionString = convertDataType(DataType)
    
switch DataType
    case 'DT_BINARY'
        PrecisionString = 'ubit1=>logical';
    case 'DT_UNSIGNED_CHAR'
        PrecisionString = 'uint8=>uint8';
    case 'DT_SIGNED_SHORT'
        PrecisionString = 'int16=>int16';
    case 'DT_SIGNED_INT'
        PrecisionString = 'int32=>int32';
    case 'DT_FLOAT'
        PrecisionString = 'float32=>single';     
    case 'DT_DOUBLE'
        PrecisionString = 'double=>double';   
end  % switch

    
%%%
%%% Function freadVerified
%%%
function out = freadVerified(fid, count, precision)
% This function reads the specified number of bytes using fread and checks
% for premature EOF. In that case, an error is generated.
   
temp = fread(fid, count, precision);
if isempty(temp)
    % Early EOF encountered in the image file. Close the file and
    % generate an error.
    fclose(fid);
    eid = 'Images:analyze75read:truncatedImageFile';
    msg = 'Image read failed. File may be corrupt or truncated';
    error(eid, msg);
else
    out = temp;
end  % if


    
    

    
    
    