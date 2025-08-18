;+
;PROCEDURE: 
;	MVN_SWIA_LOG_DECOMP
;PURPOSE: 
;	Routine to log-decompress an array of values 
;	(OBSOLETE: I have switched to Davin's lookup table routine)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_LOG_DECOMP, Array, TYPE = 0
;INPUTS:
;	Array: An array of log-compressed values
;KEYWORDS: 
;	TYPE: The type of compression, default 0 corresponds to 19-8
;OUTPUTS: 
;	Array: Returns the decompressed values as floats
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-05-23 09:54:15 -0700 (Thu, 23 May 2013) $
; $LastChangedRevision: 12392 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_log_decomp.pro $
;
;-

pro mvn_swia_log_decomp, array, type=type

if not keyword_set(type) then type = 0

array = float(array)
narray = array

if type eq 0 then begin
	w = where(array le 'FF'X)
	if w(0) ne -1 then narray(w) = '4000'X*(array(w)-'F0'X) + '40000'X
	w = where(array le 'EF'X)
	if w(0) ne -1 then narray(w) = '2000'X*(array(w)-'E0'X) + '20000'X
	w = where(array le 'DF'X)
	if w(0) ne -1 then narray(w) = '1000'X*(array(w)-'D0'X) + '10000'X
	w = where(array le 'CF'X)
	if w(0) ne -1 then narray(w) = '800'X*(array(w)-'C0'X) + '8000'X
	w = where(array le 'BF'X)
	if w(0) ne -1 then narray(w) = '400'X*(array(w)-'B0'X) + '4000'X
	w = where(array le 'AF'X)
	if w(0) ne -1 then narray(w) = '200'X*(array(w)-'A0'X) + '2000'X
	w = where(array le '9F'X)
	if w(0) ne -1 then narray(w) = '100'X*(array(w)-'90'X) + '1000'X
	w = where(array le '8F'X)
	if w(0) ne -1 then narray(w) = '80'X*(array(w)-'80'X) + '800'X
	w = where(array le '7F'X)
	if w(0) ne -1 then narray(w) = '40'X*(array(w)-'70'X) + '400'X
	w = where(array le '6F'X)
	if w(0) ne -1 then narray(w) = '20'X*(array(w)-'60'X) + '200'X
	w = where(array le '5F'X)
	if w(0) ne -1 then narray(w) = '10'X*(array(w)-'50'X) + '100'X
	w = where(array le '4F'X)
	if w(0) ne -1 then narray(w) = '8'X*(array(w)-'40'X) + '80'X
	w = where(array le '3F'X)
	if w(0) ne -1 then narray(w) = '4'X*(array(w)-'30'X) + '40'X
	w = where(array le '2F'X)
	if w(0) ne -1 then narray(w) = '2'X*(array(w)-'20'X) + '20'X
	w = where(array le '1F'X)
	if w(0) ne -1 then narray(w) = array(w)

	array = narray
endif

end

