;+
;PROCEDURE:   mvn_lpw_r_group_hsbm
;PURPOSE:
;Group together the data from several HSBM packets into one hunk of data 
; 
;Notes:
;  A hunk is the data from several packets which all have the same timestamp.
;  
;  The program presumes that the packets forming one hunk are in order in comp_p, but not necessarily
;  consecutive. 
;
;  If the hunk is longer than expected, this is an error.
;
;  If the hunk is shorter, it may not be an error. The program will attempt to pad the hunk, at the beginning
;  if it is the first hunk (presuming that the first packet(s) did not make it into the data stream), at the
;  end otherwise.
;
;USAGE:
;  mvn_lpw_r_group_hsbm,comp_t_,comp_p,length,hsbm,p,index_i
;
;INPUTS:
;  comp_t - array of doubles representing the timestamp, calculated as sec+subsec/2^16
;  comp_p - array of pointers to data from HSBM packets
;  length - expected length of each hunk of HSBM data, 1024 for LF and 4096 for MF and HF
;
;OUTPUTS:
;  hsbm - array of [1024,*] or [4096,*], one column for each hunk
;  p    - number of hunks, intended to go into variable p20, p21, or p22 in mvn_lpw_r_header
;
;KEYWORDS:
;       
;
;CREATED BY:   2011 
;FILE: mvn_lpw_r_group_hsbm.pro
;VERSION:   2.0
;;LAST MODIFICATION: 
; ;140718 clean up for check out L. Andersson 
;-
pro mvn_lpw_r_group_hsbm,comp_t_,comp_p,length,hsbm,p,index_i
;Algorithm
; While there are still unmarked timestamps
;   Get the first unmarked timestamp (comp_t)
;   Get all the timestamps and packet indexes with the same value as comp_t
;   Mark all of these timestamps so they don't show up again
;   Concatenate the data from all these packets, freeing pointers along the way
;   Check the length. If too short, and first hunk, pad the beginning, otherwise pad the end
;   If too long, report an error
; end while
  
      ; since multiple packets is combined to create 
  new_index_i=-1  ; since multiple packets is combined to create one final packet the time index needs to reflect this
  
  comp_t=comp_t_
  if n_elements(hsbm) gt 0 then junk=temporary(hsbm) 
  w=where(comp_t gt 0,count)
  p=0
  first=1
  
    
  while count gt 0 do begin
    this_t=comp_t[w[0]]    ; looking at all packets to find which has the mathing times, the packets with matching times will be merged
     
    w=where(comp_t eq this_t,count)     
    comp_t[w]=-1
      
    if n_elements(this_hsbm) gt 0 then junk=temporary(this_hsbm)
    for i=0,count-1 do begin      ; is this where multiple pakages are merged? 
      if n_elements(this_hsbm) eq 0 then $     ; this is to make sure the index_i matches the number of merged burst packets
               if new_index_i(0) EQ -1 then new_index_i=index_i[w[i]] else new_index_i=[new_index_i,index_i[w[i]]]
      if n_elements(this_hsbm) eq 0 then this_hsbm=*comp_p[w[i]] else this_hsbm=[this_hsbm,*comp_p[w[i]]]
      ptr_free,comp_p[w[i]]                 
    endfor
     
    if n_elements(this_hsbm) gt length then begin
      message,string(length,n_elements(this_hsbm),n_elements(new_index_i),format='(%"        HSBM packet too long, expected %d, found %d, no of found data so far %d")'),/info     
      this_hsbm=this_hsbm[0:length-1]
    end else if n_elements(this_hsbm) lt length then begin
      message,string(length,n_elements(this_hsbm),n_elements(new_index_i),format='(%"Incomplete HSBM packet found, expected %d, found %d, no of found data so far %d")'),/info
      leftover=make_array(type=size(this_hsbm,/type),length-n_elements(this_hsbm))
      if first then this_hsbm=[leftover,this_hsbm] else this_hsbm=[this_hsbm,leftover]
    endif
    
    if n_elements(hsbm) eq 0 then hsbm=this_hsbm else hsbm=[[hsbm],[this_hsbm]]
    p=p+1
    first=0
    w=where(comp_t gt 0,count)
 
  endwhile
    
  index_i=new_index_i     ; replace the old information about the packets
end