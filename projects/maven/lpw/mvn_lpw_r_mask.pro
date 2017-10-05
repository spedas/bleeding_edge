;+
;PROCEDURE:   mvn_lpw_r_mask
;PURPOSE:
;      This procedure only defines different masks
;       so that 8 and 16 bit numbers can be 
;       quickly decomutated
;       some of these masks are no longer used
;       used by mvn_lpw_pkt_r_header.pro and mvn_lpw_pkt_r_header_l0.pro 
;
;USAGE:
;  mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8
;
;INPUTS:
;       r_mask:
;       mask16:     array to convert 16-bite (word)
;       mask8:      array to convert 8-bite (byte)
;       bin_c:
;       index_arr:
;       flip_8: 
;
;KEYWORDS:
;       
;
;CREATED BY:   Laila Andersson 17 august 2011 
;FILE: mvn_lpw_r_mask.pro
;VERSION:   2.0
;;LAST MODIFICATION:   05/16/13
; ;140718 clean up for check out L. Andersson
;-
pro mvn_lpw_r_mask,mask16,mask8,bin_c,index_arr,flip_8

                                                            ;mask(number , the 16 bit word where index 0 is the LS bit)    
 mask16=[[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0], $ 
         [0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,1]]   ;2 x 16
for i=1L,15 do begin       
mask16=[mask16,mask16]                                      ;4 x 16
mask16[2L^i:2L^(i+1)-1,15-i]=1
endfor          

mask8=[[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,1]]     ;2 x 8
for i=1,7 do begin       
mask8=[mask8,mask8]                                         ;4 x 16
mask8[2L^i:2L^(i+1)-1,7-i]=1
endfor          

bin_c=2.^indgen(32)
index_arr=indgen(32)
                                                             ; to flip the 8 values
flip_8=[7-indgen(8)+8,7-indgen(8)]
                                                             ;flip_8=15-indgen(16)
end


