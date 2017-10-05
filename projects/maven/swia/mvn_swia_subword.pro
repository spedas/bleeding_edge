;+
;FUNCTION: 
;	MVN_SWIA_SUBWORD
;PURPOSE: 
;	Function to return a portion of a word
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE: 
;	Result = MVN_SWIA_SUBWORD(Word,BIT1 = 7, BIT2 = 0)
;INPUTS: 
;	Word: the input word
;KEYWORDS: 
;	BIT1: The bit to start from (inclusive), from 15 to 0, default 15
;	BIT2: The bit to end at (inclusive), from 15 to 0, default 0
;OUTPUTS: 
;	Returns the value formed by the bits from ['bit1','bit2'] of 'word'
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_subword.pro $
;
;-

function mvn_swia_subword, word, bit1 = bit1, bit2 = bit2

compile_opt idl2

if not keyword_set(bit1) then bit1 = 15
if not keyword_set(bit2) then bit2 = 0

len = bit1-bit2 + 1

sub1 = floor(word/2L^bit2)
sub2 = sub1 mod (2L^len)

return,sub2

end






