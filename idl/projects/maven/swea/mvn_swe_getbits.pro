;+
;FUNCTION:   mvn_swe_getbits
;PURPOSE:
;  Extracts a sub-word defined by a range of bits from an input word.
;
;USAGE:
;  subword = mvn_swe_getbits(word, bitrange)
;
;INPUTS:
;       word:          A 16-bit (2-byte) word.  Can also be an array of words.
;                      Can also be a byte or an array of bytes.
;
;       bitrange:      A one- or two-element array specifying the desired bit or 
;                      range of bits: [MSB [, LSB]], where MSB and LSB are integers 
;                      between 0 and 15.  If MSB and LSB are the same, or if only 
;                      one bit is specified, then just that one bit is returned.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 12:38:38 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16103 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_getbits.pro $
;
;CREATED BY:    David L. Mitchell  08-29-11
;FILE: mvn_swe_getbits.pro
;VERSION:   1.0
;LAST MODIFICATION:   08/29/11
;-
function mvn_swe_getbits, word, bitrange

  common bitcom, bitval
  
  if (size(bitval,/type) eq 0) then bitval = 2L^lindgen(17)

  LSB = min(long(bitrange), max=MSB)

  i = (LSB > 0L) < 15L
  j = ((MSB - LSB + 1L) > 1L) < 16L

  return, (word / bitval[i]) mod bitval[j]

end
