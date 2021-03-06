function varargout = dicom_sort(FNames, Opt)

% FUNCTION FNames = dicom_sort(FNames, Opt)
%
% Sorts DICOM files into local subdirectories with a SeriesNumber_ProtocolName
% name.
%
% INPUT
% 	FNames -	Character array with the DICOM filenames in rows. Leave empty for
%				interactive use.
%	Opt	 -	Files are moved if Opt = 'move' (default), else a symbolic link is
%				made with a PatientsName_ProtocolName_SeriesNumber_InstanceNumber
% 				naming convention (unix only).
%
% OUTPUT
%	FNames -	Character array with the sorted DICOM filenames in rows
%
% Marcel, 11-02-2011.
%
% See also: dicom_sortp

if nargin<1
    FNames = spm_select(Inf, 'any', 'Select DICOM data', {''}, pwd, '.ima$|.IMA$|.dcm$|.DCM$');
end
if isempty(FNames), return, end
if nargin<2 || isempty(Opt)
	Opt = 'move';
end

PrcolDirs = {''};
FNames_	  = cell(size(FNames,1), 1);
H = waitbar(0, ['Sorting ' num2str(size(FNames,1)) ' files...'], 'Name','dicom_sort');
for n = 1:size(FNames,1)
    DcmHdr	 = spm_dicom_headers(FNames(n,:), true);
	DcmHdr	 = DcmHdr{1};
	PrcolDir = [fileparts(FNames(n,:)) filesep sprintf('%02d',DcmHdr.SeriesNumber) ...
				'_' strtrim(DcmHdr.ProtocolName)];
	if ~any(strcmp(PrcolDir, PrcolDirs))		% We have a new dir/protocol
		PrcolDirs = [PrcolDirs PrcolDir];
		if ~exist(PrcolDir, 'dir')
			mkdir(PrcolDir)
		end
	end
	if strcmpi(Opt, 'move')
		[Dum FName Ext] = fileparts(strtrim(FNames(n,:)));
		FNames_{n} = fullfile(PrcolDir, [FName Ext]);
		movefile(strtrim(FNames(n,:)), FNames_{n}, 'f')
	elseif isunix
		FNames_{n} = sprintf('%s%s%s_%s_%04d_%04d.dcm', PrcolDir, filesep, ...
			strtrim(DcmHdr.PatientsName), strtrim(DcmHdr.ProtocolName), ...
			DcmHdr.SeriesNumber, DcmHdr.InstanceNumber);
		unix(['ln -sf ' strtrim(FNames(n,:)) ' ' FNames_{n}]);
	else
		error('Linking option is implemented for unix/linux only')
	end
    waitbar(n/size(FNames,1), H)
end
close(H)

if nargout
	varargout{1} = char(FNames_);
end
