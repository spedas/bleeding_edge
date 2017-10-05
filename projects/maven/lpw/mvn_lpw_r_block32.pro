;+
;FUNCTION:   mvn_lpw_r_block32
;PURPOSE:
; Decomutater for the compression for block=32 reading the datafile as WORD
; This routine is called by the mvn_lpw_r_header.pro
;
;USAGE:
;  output=mvn_lpw_r_block32(data,ptr,nn_e,mask16,bin_c,index_arr,output)
;
;INPUTS:
;            data            this should be the unsigned array of the read in file
;            ptr             this is which element to start with in the data array and updated ptr
;            nn_e            this is which bit to start with based on element 'ptr' and array 'data' and update nn_e   
;            mask16          this is to convert the value in the array 'data' to a 16-bit binary array  
;            bin_c           this is an index array to convert the bit's to a integer 
;            index_arr       this is an index array       
;            output          the result of the read resultinf in an 128 point array with values form the array 'data'
;
;OUTPUTS:
;  hsbm - array of [1024,*] or [4096,*], one column for each hunk
;  p    - number of hunks, intended to go into variable p20, p21, or p22 in mvn_lpw_r_header
;
;KEYWORDS:
;       
;
;CREATED BY:   2011 
;FILE: mvn_lpw_r_block32.pro
;VERSION:   2.0
;;LAST MODIFICATION: 2012 April 24 by: Laila 
; ;140718 clean up for check out L. Andersson
;-

function mvn_lpw_r_block32,data,ptr,nn_e,mask16,bin_c,index_arr,arr_size,edac_on
  ;-------------- LAilas using uncompress SECTION 8.9 data compression---------------
      ; 32 blocks of 16 bits   or 16 blocks of 32 bits (20 bits sign estended)
      ; first value is the absolute the following points are the fluctuation, PADING might have been used
      ;EUV and AVG have both 16 and 32 sample blocks  (swp_i 16 and swp_v 32)
      ; broken into multiple 64 byte compression blocks     
      ;32 block
      ;first 32 block start with 16 bit    then ND 7 bit number  last 31 is 6 bit    16 + 7 + 31 x 6 = 209   ->27*8 words=216
      ;the 7 bit = P2 P1 P0 D3 D2 D1 D0  where ND-1= D3D2D1D0 EDAC=P2P1P0  and P2 =D1xorD2xorD3; P1=D0xorD2xorD3; P0=D0xorD1xorD3 
      ;second 32 block start with 16 bit followed by 7 bit number  this continues until ND =16     
      ;16 block
      ;first 16 block starts with 20 bit sample    followed ND as 9 bits then 16 deltas of length ND 
      ;the 9 bits are P3P2P1P0D4D3D2D1D0 EDACbits then ND-1bits P3=D4 and P2 =D1xorD2xorD3; P1=D0xorD2xorD3; P0=D0xorD1xorD3xorD4 
      ;second 16 block with 20 bit sample folloewd with 9 bit ND     ND - 20 delta is disable     
      ;For this one it is as follows:
      ;I1(0-15) I1(16-31) I1(32-47) I1(48-63) I1(64-79) I1(80-95) I1(96-111) I1(112-127) V2(0-31) V2(32-63) V2(64-95) V2(96-127)
  
   edac_on=0
   n_loops=arr_size/32                                             ; how many time the loop below createin 32 values at a time needs to be operated  
   output=fltarr(arr_size)   
   reject=0
    tmp0=intarr(16)                                                ;  newfile_signed is 16 bit array
    temp_32=fltarr(32)                                             ; this is the number of points in this     32*4 == 128 number of points   
    ptr_size=(16+7+16*31)/8  < ((n_elements(data)-ptr)-1)  
  IF ptr+(ptr_size)/8 LT (n_elements(data)-1) THEN $
  for nii = 0,n_loops-1 do begin   ; 4 sets
        ptr_size=(16+7+16*31)/8  < ((n_elements(data)-ptr)-1)   
        ptr_end=(ptr+ptr_size)                                      ;< (n_elements(data)-1)  ;(length2[i]-len_offset-4)/8 +1  ; this should be based on the (length2[i]-len_offset-4)  
        tmp=data[ptr:ptr_end]
        bin=intarr(16)                                              ;  newfile_signed is 16 bit array need to be renewed in the loop
        bin[*]=mask16[tmp[0],*]                                     ; manuall change        
        for ui=1,ptr_size-1  do begin                               ; remove this begin end .....
            tmp0[*]=mask16[tmp[ui],*]
            bin=[bin,tmp0]
        endfor                    
        nd_1=bin[19+nn_e]*8+bin[20+nn_e]*4+bin[21+nn_e]*2+bin[22+nn_e]                                  ; should be first 3 EDAC bits then 4 bit which is ND-1       
        if bin[16+nn_e] NE (bin[19+nn_e]+bin[20+nn_e]+bin[21+nn_e]) mod 2          AND $                ;P2 = D1xorD2xorD3
           bin[17+nn_e] NE (bin[19+nn_e]+bin[20+nn_e]+bin[22+nn_e]) mod 2          AND $                ;P1 = D0xorD2xorD3
           bin[18+nn_e] NE (bin[19+nn_e]+bin[21+nn_e]+bin[22+nn_e]) mod 2         THEN edac_on=1        ;P0 = D0xorD1xorD3
                                                                      ;  Print,' Warning the EDAC and ND values did not agree in this 32 block compression VV ', bin(16+nn_e),bin(17+nn_e),bin(18+nn_e), bin(19+nn_e),bin(20+nn_e),bin(21+nn_e),bin(22+nn_e)  ;use this later to fluch this package          
         if bin[16+nn_e] NE (bin[19+nn_e]+bin[20+nn_e]+bin[21+nn_e]) mod 2          AND $                ;P2 = D1xorD2xorD3
           bin[17+nn_e] NE (bin[19+nn_e]+bin[20+nn_e]+bin[22+nn_e]) mod 2          AND $                 ;P1 = D0xorD2xorD3
           bin[18+nn_e] NE (bin[19+nn_e]+bin[21+nn_e]+bin[22+nn_e]) mod 2         THEN reject=reject+1   ;P0 = D0xorD1xorD3                        
         temp_32[0] =   (1-bin[0+nn_e])* total(double(                            bin[1+nn_e:15+nn_e]*bin_c[14-index_arr[0:14]]))- $  ; if the value is positive      
                           bin[0+nn_e] *(total(double((1-bin[1+nn_e:15+nn_e])*(1+bin[1+nn_e:15+nn_e])*bin_c[14-index_arr[0:14]]))+1)  ;if the value is negative
         nd=nd_1+1                                                  ; the recorded information is ND-1   
         nn_g=7+16+nn_e
     if nn_g+31*nd GT n_elements(bin) then nd= (n_elements(bin)-nn_g)/31
    IF nd EQ 1 then $
           for ii=0,30 do  temp_32[ii+1]=temp_32[ii]+   $            ; first value is the sign, then sum over the other nd-1 elements 
                    0  -              $                              ; if it is positive
                    bin[nn_g+0+ii*nd] $                              ; if it is negative
   ELSE $                                                            ; if nd is not == 1
   IF nd EQ 2 then $
           for ii=0,30 do  temp_32[ii+1]=temp_32[ii]+   $            ; first value is the sign, then sum over the other nd-1 elements 
                 (1-bin[nn_g+0+ii*nd])*                         bin[nn_g+ii*nd+1]  -$     ; if it is positive
                    bin[nn_g+0+ii*nd] *((1-bin[nn_g+ii*nd+1])*(1+bin[nn_g+ii*nd+1])+1) $  ; if it is negative 
   ELSE $                                                             ; if nd not == 1,2      
             IF nd EQ 16  then $                                      ;  ND == 16 decoding disable 
        for ii=0,30 do temp_32[ii+1]=   $                              ; first value is the sign, then sum over the other nd-1 elements 
                         (1-bin[nn_g+0+ii*nd])* total(double(                                        bin[1+ii*nd+nn_g:15+ii*nd+nn_g]*bin_c[14-index_arr[0:14]]))-        $          ; if the value is positive      
                            bin[nn_g+0+ii*nd]  *(total(double((1-bin[1+ii*nd+nn_g:15+ii*nd+nn_g])*(1+bin[1+ii*nd+nn_g:15+ii*nd+nn_g])*bin_c[14-index_arr[0:14]]))+1) $ ;if the value is negative
    ELSE $                                                            ; the rest, not special cases
        for ii=0,30 do  temp_32[ii+1]=temp_32[ii]+   $                ; first value is the sign, then sum over the other nd-1 elements 
                 (1-bin[nn_g+0+ii*nd])*total(double(                                          bin[nn_g+ii*nd+1:nn_g+(ii+1)*nd-1] *bin_c[nd-1-index_arr[1:nd-1]])) -$                                        ; if it is positive
                    bin[nn_g+0+ii*nd] *(total(double((1-bin[nn_g+ii*nd+1:nn_g+(ii+1)*nd-1])*(1+bin[nn_g+ii*nd+1:nn_g+(ii+1)*nd-1])*bin_c[nd-1-index_arr[1:nd-1]]) )+1)  ; if it is negative
          nn_e=(nn_g+nd*31) mod 16
         ptr=ptr+floor(1.0*(nn_g+nd*31)/16)                            ; 20+9+nd*15 bit   should one block contain and newfile_signed is a 16 bit array                
         output[nii*32+0: nii*32+31] = temp_32                        ; this is just 1/8 of the points 
    endfor ELSE ptr= n_elements(data)                                   ; change ptr if en odd array has been reached
    
   If reject GT 0 then output=output*0                                ; there was an issue during this packet
   
   return,output
end