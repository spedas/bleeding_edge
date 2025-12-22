;	@(#)ask.pro	1.5	
function ask,question
;
;  Returns 'y' or 'n' based on user's keyboard response to
;  QUESTION. Does not take 'maybe' for an answer. 
;
response = 'nothing'

oops = 0
patience = 5

while (response ne 'y') and (response ne 'n') do begin
   if response ne 'nothing' then begin
      oops = oops + 1
      if (oops gt patience) then begin
         oops =  0
         print,"$($,a)",' Yo!   Yes or no, please...'
      endif
   endif
   print,"$($,a)",question
   response = strlowcase(get_kbrd(1))
   print,' '   
endwhile

return,response
end



