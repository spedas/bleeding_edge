; This program returns a byte number for a specified set of observatory selection.
; If biarray=[1,0,0,1] is passed to this function (meaning, MMS-1 and MMS-4 are selected),
; this function returns a BYTE number '9' which can be stored into the FOMStr.
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2023-08-21 20:46:44 -0700 (Mon, 21 Aug 2023) $
; $LastChangedRevision: 32050 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_obsset_bitarray2byte.pro $
FUNCTION eva_obsset_bitarray2byte, bitarray
  compile_opt idl2
  
  obsset = bitarray[3]*2^3 + bitarray[2]*2^2 + bitarray[1]*2^1 + bitarray[0]
  return, byte(obsset)
END