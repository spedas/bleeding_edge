;; Sweep [32D x 128E x 16A] ----->  [1D]
PRO spp_swp_spi_flight_get_prod_1D, arr
   arr = intarr(4096)
END
   
    
;; Sweep [32D x 128E x 16A] ----->  [16A]    
PRO spp_swp_spi_flight_get_prod_16A, arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ianode
   ENDFOR
END 

;; Sweep [32D x 128E x 16A] ----->  [32E]    
PRO spp_swp_spi_flight_get_prod_32E, arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ienergy
   ENDFOR
END
   
;; Sweep  [32D x 128E x 16A]  ----->  [08D]    
PRO spp_swp_spi_flight_get_prod_08D , arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ideflector
   ENDFOR
END

;; Sweep  [32D x 128E x 16A]  ----->  [32E x 16A]   
PRO spp_swp_spi_flight_get_prod_32Ex16A, arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ienergy + ianode*'20'x
   ENDFOR
END
   
;; Sweep [32D x 128E x 16A x 16 Mass Bins]  ----->  [08D x 16A]   
PRO spp_swp_spi_flight_get_prod_08Dx16A, arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ideflector + ianode*'08'x
   ENDFOR
END
   
;; Sweep [32D x 128E x 16A x 16 Mass Bins]  ----->  [08D x 32E]   
PRO spp_swp_spi_flight_get_prod_08Dx32E, arr
   arr = intarr(4096)
   FOR ianode=0, '10'x-1 DO $
    FOR ienergy=0, '20'x-1 DO $
     FOR ideflector=0, '08'x-1 DO BEGIN 
      ind = ideflector + $
            ienergy*'08'x + $
            ianode*'20'x*'08'x
      arr[ind] = ideflector + ienergy*'08'x
   ENDFOR
END
   
;; Sweep [32D x 128E x 16A x 16 Mass Bins]  ----->  [08D x 32E x 16A]   
PRO spp_swp_spi_flight_get_prod_08Dx32Ex16A, arr
   arr = intarr(4096)
   bitpar = 0
   FOR ianode=0, '10'x-1 DO BEGIN 
      FOR ienergy=0, '20'x-1 DO BEGIN 
         FOR ideflector=0, '08'x-1 DO BEGIN 
            ind = ideflector + $
                  ienergy*'08'x + $
                  ianode*'20'x*'08'x
            IF bitpar MOD 2 THEN idef = ideflector $
            ELSE idef = 7-ideflector
            arr[ind] = idef+(ienergy*'08'x)+(ianode*'08'x*'20'x)
         ENDFOR
         bitpar = bitpar + 1
      ENDFOR
   ENDFOR 
END


;; Sweep [32D x 128E x 08A x 16 Mass Bins]  ----->  [08D x 32E x 08A]
;; Anodes 1-7 (fixed in v2)
PRO spp_swp_spi_flight_get_prod_08Dx32Ex08A, arr
   arr = intarr(4096)
   bitpar = 0
   FOR ianode=0, '10'x-1 DO BEGIN
      FOR ienergy=0, '20'x-1 DO BEGIN
         FOR ideflector=0, '08'x-1 DO BEGIN
            ind = ideflector + $
                  ienergy*'08'x + $
                  ianode*'20'x*'08'x
            IF bitpar MOD 2 THEN idef = ideflector $
            ELSE idef = 7-ideflector
            IF ianode GT 0 && ianode LT 8 THEN $  
             arr[ind] = idef+ienergy*'08'x+ianode*'08'x*'20'x $
            ELSE arr[ind] = 'FFFF'x ;; Trash Bin
         ENDFOR
         bitpar = bitpar + 1
      ENDFOR
   ENDFOR
END

;; Sweep [32D x 128E x 08A x 16 Mass Bins]  ----->  [08D x 32E x 08A]
;; Anodes 0-7
PRO spp_swp_spi_flight_get_prod_08Dx32Ex08A_v2, arr
   arr = intarr(4096)
   bitpar = 0
   FOR ianode=0, '10'x-1 DO BEGIN
      FOR ienergy=0, '20'x-1 DO BEGIN
         FOR ideflector=0, '08'x-1 DO BEGIN
            ind = ideflector + $
                  ienergy*'08'x + $
                  ianode*'20'x*'08'x
            IF bitpar MOD 2 THEN idef = ideflector $
            ELSE idef = 7-ideflector
            IF ianode GE 0 && ianode LT 8 THEN $  
             arr[ind] = idef+ienergy*'08'x+ianode*'08'x*'20'x $
            ELSE arr[ind] = 'FFFF'x ;; Trash Bin
         ENDFOR
         bitpar = bitpar + 1
      ENDFOR
   ENDFOR
END


;; Sweep [32D x 128E x 08A x 16 Mass Bins]  ----->  [08D x 32E x 08A]
;; Anodes 8-15
PRO spp_swp_spi_flight_get_prod_08Dx32Ex08A_v3, arr
   arr = intarr(4096)
   bitpar = 0
   FOR ianode=0, '10'x-1 DO BEGIN
      FOR ienergy=0, '20'x-1 DO BEGIN
         FOR ideflector=0, '08'x-1 DO BEGIN
            ind = ideflector + $
                  ienergy*'08'x + $
                  ianode*'20'x*'08'x
            IF bitpar MOD 2 THEN idef = ideflector $
            ELSE idef = 7-ideflector
            IF ianode GE 8 && ianode LT 16 THEN $  
             arr[ind] = idef+ienergy*'08'x+(ianode-8)*'08'x*'20'x $
            ELSE arr[ind] = 'FFFF'x ;; Trash Bin
         ENDFOR
         bitpar = bitpar + 1
      ENDFOR
   ENDFOR
END


;;---------------------------------------------------------
;; Product Sum LUT
;;
;; Here we select the number (2**n) of times to sum over an
;; archive and survey product.
;;
;; Purpose: 
;; Write the product sum look-up table with simple values
;; for testing
PRO spp_swp_spi_get_psumlut, ar_sum, sr_sum, psum, psum_chk

   psum = []
   psum_chk = 0

   ;; Part 1: Full Sweep Products
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN
         ;;# Upper 16 bits are 0.
         psum = [psum,0]
         ;;# Lower 16 bits ar/sr        
         tmp1 = sr_sum[mass + product*8] AND '0F'x
         tmp2 = ar_sum[mass + product*8] AND '0F'x
         temp_psum = ishft(tmp1,4) OR tmp2
         psum = [psum,temp_psum]
         psum_chk=psum_chk+(temp_psum AND 'FF'x)
      ENDFOR
   ENDFOR

   ;;# After the first set of 12 addresses and lengths
   ;;# Intermission: Skip 4 Words
   FOR i = 0, 7 DO BEGIN
      ;; Write 4 blank words which are
      ;; skipped over in the FPGA.
      psum = [psum,0]
   ENDFOR 

   ;; Part 2: Targeted Sweep Products
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN
         ;;# Upper 16 bits 0
         psum = [psum,0]
         ;;# Lower 16 bits ar/sr       
         tmp1 = sr_sum[mass + product*8 + 4] AND '0F'x
         tmp2 = ar_sum[mass + product*8 + 4] AND '0F'x
         temp_psum = ishft(tmp1,4) OR tmp2
         psum = [psum,temp_psum]
         psum_chk=psum_chk+(temp_psum AND 'FF'x)
      ENDFOR
   ENDFOR

   psum_chk = psum_chk AND 'FF'x
   return 

END 


;;-------------------------------------------------
;; Product Mass Range LUT
;;
;; The user must categorize the 64 masses into
;; 4 separate mass bins. The bins are defined as
;; follows:
;;
;; 0b000 - Mass Bin 1
;; 0b001 - Mass Bin 2
;; 0b010 - Mass Bin 3
;; 0b011 - Mass Bin 4
;; 0b100 - Discard
;;
;; Example:
;;   # 4 evenly mass distributed bins.
;;   mass_range = [i >> 4 for i in range(64)]
;;   print mass_range
;;   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
;;   1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
;;   2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
;;   3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]
PRO spp_swp_spi_get_mrlut, mrbins, mrlut, mrlut_chk

   mrlut = []
   mrlut_chk = 0
   ;;# If no mass range is set, use default
   IF n_elements(mrbins) EQ 0 THEN  stop
   ;;# Write two mass bins for each 16 bit value.
   FOR i = 0, 31 DO BEGIN
      mrlut = [mrlut,ishft(mrbins[2*i],8) OR mrbins[2*i+1]]
      mrlut_chk = mrlut_chk+(mrlut[i] AND 'FF'x)
      mrlut_chk = mrlut_chk+(ishft(mrlut[i],-8) AND 'FF'x)
   ENDFOR
   mrlut_chk = mrlut_chk AND 'FF'x 
   return

END 


  

;;---------------------------------
;; Product Address/Length LUT
;;
;; Rearrange order of table
;; Address/length table is ordered: 
;;   [targeted|product|mass] 
;; instead of 
;;   [product|targeted|mass]
;; hence the 8 in [mass + product*8]
PRO spp_swp_spi_get_allut, start_address,$
                           prod_length,$
                           allut,$
                           allut_chk

   ;; Check Parameters
   IF n_elements(start_address) NE 25 OR $
    n_elements(prod_length) NE 24 THEN BEGIN
      print, 'Incorrect Start Address or Product Length.'
      return
   ENDIF 

   allut_chk = 0
   value  = []
   start  = []
   length = []
   
   ;; Part 1: Full Sweep Products
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN 
         start  = start_address[mass + product*8]
         length = prod_length[mass + product*8]
         ;; Write length to MRAM first
         value = [value,length]         
         ;; 1. Write start address with LSB cut off.
         ;; 2. There are two value per address, thus
         ;;    divide by 2 (cut off LSB again).
         value = [value,ishft(start,-1)]
         ;; Error Checking
         ;;IF (start AND 3) NE 0 THEN BEGIN 
         ;;   print, "Warning: illegal address for product"
         ;;   print, "Address %x - LSBs must be 00" % start
         ;;   stop
         ;;ENDIF 
         allut_chk = allut_chk + (length AND 'FF'x)
         allut_chk = allut_chk + (ishft(length,-8) AND 'FF'x)
         allut_chk = allut_chk + (ishft(start,-1)  AND 'FF'x)
         allut_chk = allut_chk + (ishft(start,-9)  AND 'FF'x)
      ENDFOR
   ENDFOR
   
   ;; After the first set of 12 addresses and lengths
   ;; Intermission: Skip 4 Words
   FOR i = 0, 7 DO BEGIN
      ;; Write 4 blank words which
      ;; are skipped over in the FPGA    
      value = [value,0]
   ENDFOR 
   
   ;; Part 2: Targeted Sweep Products
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN
         start  = start_address[mass + product*8 + 4]
         length = prod_length[mass + product*8 + 4]
         ;; Write length to MRAM first
         value = [value,length] ;;value.append(length)
         ;; 1. Write start address with LSB cut off.
         ;; 2. There are two value per address so
         ;;    divide by 2 (cut off LSB again).
         value = [value,ishft(start,-1)]
         ;; Error Checking
         ;;IF (start AND 3) NE 0 THEN BEGIN 
         ;;   print, "Warning: illegal address for product"
         ;;   print, "Address %x - LSBs must be 00" % start
         ;;   stop
         ;;ENDIF 
         allut_chk = allut_chk + (length AND 'FF'x)
         allut_chk = allut_chk + (ishft(length,-8) AND 'FF'x)
         allut_chk = allut_chk + (ishft(start,-1)  AND 'FF'x)
         allut_chk = allut_chk + (ishft(start,-9)  AND 'FF'x)
      ENDFOR
   ENDFOR
   allut = value
   allut_chk = allut_chk AND 'FF'x
   return
   
END 








;;#------------------------------------------------------
;;# Product Energy/Deflector LUT
;;#
;;# Set addresses for Energy/Deflector product size table
;;# Rearrange order of table
;;# Table is ordered: [targeted|product|mass]
;;# instead of [product|targeted|mass]
PRO spp_swp_spi_get_edlut, ed_length, edlut, edlut_chk

   edlut_chk = 0
   length = []
   
   ;; Part 1: Full Sweep Products ####
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN
         
         ;;# Upper SRAM 16 bits are 0
         length = [length,0] ;;length.append(0)
         ;;# Write length to mram  
         temp_length = ed_length[mass + product*8]
         length = [length, temp_length]
         edlut_chk = edlut_chk + $
                     (temp_length AND 'FF'x)
         edlut_chk = edlut_chk + $
                     (ishft(temp_length,-8) AND 'FF'x)
      ENDFOR
   ENDFOR

   ;; After the first set of 12 addresses and lengths
   ;; Intermission: Skip 4 Words
   FOR i = 0, 7 DO BEGIN
      ;; Write 4 blank words which are skipped over in the FPGA    
      length = [length,0]
   ENDFOR

   ;; Part 2: Targeted Sweep Products
   FOR product = 0, 2 DO BEGIN
      FOR mass = 0, 3 DO BEGIN
         
         ;;# Upper SRAM 16 bits are 0
         length = [length,0]
         ;;# Write length to mram first
         temp_length = ed_length[mass + product*8 + 4]
         length = [length, temp_length]
         edlut_chk = edlut_chk + $
                     (temp_length AND 'FF'x)
         edlut_chk = edlut_chk + $
                     (ishft(temp_length,-8) AND 'FF'x)
      ENDFOR
   ENDFOR

   edlut = length
   edlut_chk = edlut_chk AND 'FF'x
   return
   
END





;;------------------------------------------------------
;; Product Mass Bins
;;
;; Write the product mass bins table to MRAM
;; This tells how many mass bins to retain for the products
;; Value(8:6)          Value(5:0)
;;  Bit shift           Mass number
;;
;; The mass number tells us how to offset the mass so that it appears as bin 0 
;; of the multiple bins, e.g. if we want multiple bins for masses 12-19, the 
;; mass number should be 12.
;;
;; The bit shift tells how to split the remaining masses into bins.
;; Using the example above, the masses 12-19 will be offset so they
;; are numbered 0-7
;; If you want 4 bins, shift 1 bit.  If you want 2 bins, shift 2 bits.
;;
;; The bit shift definition is:
;; Value    bits shifted
;;   0         0
;;   1         1
;;   2         2
;; ...
;;   6         6
PRO spp_swp_spi_get_pmbins, mrbins, pmbins, pmbins_chk


   ;; Find Offsets
   offset = []
   FOR j = 0, 5 DO BEGIN
      offset = [offset,0]
      FOR i = 0, 62 DO BEGIN
         ind = i+j*64
         tmp = mrbins[ind+1] - mrbins[ind]
         IF tmp NE 0 THEN offset = [offset,i+1]
      ENDFOR 
   ENDFOR
   
   offset = [offset,0]
   bbins = []
   bbits = []
   FOR i = 0, 23 DO BEGIN
      tmp = offset[i+1] - offset[i]
      IF tmp LT 0 THEN tmp = 64 - offset[i]

      bbins = [bbins,tmp]
      FOR j = 0, 4 DO BEGIN
         IF ishft(tmp,-j) LE pmbins[i] THEN BEGIN 
            bbits = [bbits,j]
            BREAK
         ENDIF
      ENDFOR
   ENDFOR
   
   pmbins_chk = 0
   mass_bins = []

   ;; Part 1: Full Sweep Products
   FOR product = 0, 2 DO BEGIN 
      FOR mass=0, 3 DO BEGIN 
         ;; Upper SRAM 16 bits are 0
         mass_bins = [mass_bins,0]
         ;; Write length to mram  
         t_bbits  = (6-bbits[mass + product*8])
         t_offset = offset[mass + product*8]
   
         ;; Klduge to match Abiad's inital setup
         IF t_bbits EQ 2 THEN BEGIN
            t_bbits  = 0
            t_offset = 0
         ENDIF 
         tmp = ishft(t_bbits,6) OR t_offset
         mass_bins = [mass_bins,tmp]
         pmbins_chk=pmbins_chk+(tmp AND 'FF'x)
         pmbins_chk=pmbins_chk+(ishft(tmp,-8) AND 'FF'x)
      ENDFOR
   ENDFOR
   
   ;; After the first set of 12 addresses and lengths
   ;; Intermission: Skip 4 Words
   FOR i = 0, 7 DO BEGIN
      ;; Write 4 blank words which are skipped over in the FPGA    
      ;;cdicmd(f1,write_to_mram)
      mass_bins = [mass_bins,0]
   ENDFOR
   
   ;; Part 2: Targeted Sweep Products ####
   FOR product = 0, 2 DO BEGIN 
      FOR mass = 0, 3 DO BEGIN
         ;; Upper SRAM 16 bits are 0
         mass_bins = [mass_bins,0]
         ;; Write length to mram  
         t_bbits  = (6-bbits[mass + product*8 + 4])
         t_offset = offset[mass + product*8 + 4]
         IF t_bbits LE 2 THEN BEGIN 
            t_bbits  = 0
            t_offset = 0
         ENDIF 
         tmp = ishft(t_bbits,6) OR t_offset
         mass_bins = [mass_bins,tmp]
         pmbins_chk=pmbins_chk+(tmp AND 'FF'x)
         pmbins_chk=pmbins_chk+(ishft(tmp,-8) AND 'FF'x)       
      ENDFOR
   ENDFOR
   
   ;;print "CHECKSUM for PMBINS: " + hex(pmbins_chk AND 'FF'x)
   pmbins = mass_bins
   pmbins_chk = pmbins_chk AND 'FF'x
   return

END 


PRO spp_swp_spi_get_pilut, mem, prod_type, pilut, pilut_chk

   nn = n_elements(prod_type)
   pilut  = intarr(nn,4096)
   pilut_chk = 0
   tnames = tag_names(mem)

   FOR i=0, nn-1 DO BEGIN
      pp = where(strupcase('PROD_'+prod_type[i]+'_DPP_SIZE') EQ $
                 strupcase(tnames),cc)
      IF cc EQ 0 THEN stop, 'Error: Wrong PI-LUT Name.'
      tmp = execute('spp_swp_spi_flight_get_prod_'+prod_type[i]+',arr') 
      IF tmp THEN pilut[i,*] = arr
      FOR j=0, 4095 DO BEGIN
         tmp1 = pilut[i,j] AND 'FF'x
         pilut_chk = (pilut_chk+tmp1) AND 'FF'x
         tmp2 = ishft(pilut[i,j],-8) AND 'FF'x
         pilut_chk = (pilut_chk+tmp2) AND 'FF'x
      ENDFOR 
   ENDFOR
   pilut_chk = pilut_chk AND 'FF'x
   ;;print, format='(A19,z02)','PI-LUT Checksum: 0x', pilut_chk

END

   

FUNCTION spp_swp_spi_flight_product_tables, pmode
   
   ;; Keyword Check
   IF ~keyword_set(pmode) THEN BEGIN
      print, 'No product selected.'
      pmode = 'help'
   ENDIF

   CASE pmode OF

      ;; With zeroes name
      'prod_1D': spp_swp_spi_flight_get_prod_1D, arr
      'prod_08D': spp_swp_spi_flight_get_prod_08D, arr
      'prod_32E': spp_swp_spi_flight_get_prod_32E, arr
      'prod_16A': spp_swp_spi_flight_get_prod_16A, arr
      'prod_32E_16A': spp_swp_spi_flight_get_prod_32Ex16A, arr
      'prod_08D_32E': spp_swp_spi_flight_get_prod_08Dx32E, arr
      'prod_08D_16A': spp_swp_spi_flight_get_prod_08Dx16A, arr
      'prod_08D_32E_16A': spp_swp_spi_flight_get_prod_08Dx32Ex16A, arr
      'prod_08D_32E_08A': spp_swp_spi_flight_get_prod_08Dx32Ex08A, arr
      'prod_08D_32E_08A_v2': spp_swp_spi_flight_get_prod_08Dx32Ex08A_v2, arr
      'prod_08D_32E_08A_v3': spp_swp_spi_flight_get_prod_08Dx32Ex08A_v3, arr
      

      ;; Without zeroes in name
      'prod_1D': spp_swp_spi_flight_get_prod_1D, arr
      'prod_8D': spp_swp_spi_flight_get_prod_08D, arr
      'prod_32E': spp_swp_spi_flight_get_prod_32E, arr
      'prod_16A': spp_swp_spi_flight_get_prod_16A, arr
      'prod_32Ex16A': spp_swp_spi_flight_get_prod_32Ex16A, arr
      'prod_8Dx32E': spp_swp_spi_flight_get_prod_08Dx32E, arr
      'prod_8Dx16A': spp_swp_spi_flight_get_prod_08Dx16A, arr
      'prod_8D_32Ex16A': spp_swp_spi_flight_get_prod_08Dx32Ex16A, arr
      'prod_8Dx32Ex8A': spp_swp_spi_flight_get_prod_08Dx32Ex08A, arr
      'prod_8Dx32Ex8A_v2': spp_swp_spi_flight_get_prod_08Dx32Ex08A_v2, arr
      'prod_8Dx32Ex8A_v3': spp_swp_spi_flight_get_prod_08Dx32Ex08A_v3, arr

      ;; Compile all functions
      'compile':BEGIN
         spp_swp_spi_flight_get_prod_1D, arr
         spp_swp_spi_flight_get_prod_08D, arr
         spp_swp_spi_flight_get_prod_32E, arr
         spp_swp_spi_flight_get_prod_16A, arr
         spp_swp_spi_flight_get_prod_32Ex16A, arr
         spp_swp_spi_flight_get_prod_08Dx32E, arr
         spp_swp_spi_flight_get_prod_08Dx16A, arr
         spp_swp_spi_flight_get_prod_08Dx32Ex16A, arr
         spp_swp_spi_flight_get_prod_08Dx32Ex08A, arr
         spp_swp_spi_flight_get_prod_08Dx32Ex08A_v2, arr
         spp_swp_spi_flight_get_prod_08Dx32Ex08A_v3, arr
         return, 1
      END 

      ;; List all available binmaps
      'help': BEGIN
         print,'----------------------------------'
         print,'Choose from the following options:'
         print,'prod_1D'
         print,'prod_08D'
         print,'prod_32E'
         print,'prod_16A'
         print,'prod_32E_16A'
         print,'prod_08D_32E'
         print,'prod_08D_16A'
         print,'prod_08D_32E_16A'
         print,'prod_08D_32E_08A # Anodes 1-7'
         print,'prod_08D_32E_08A_v2 # Anodes 0-7'
         print,'prod_08D_32E_08A_v3 # Anodes 8-15'
         print,'----------------------------------'
         return, 0
      END
      ELSE:BEGIN
         dprint, 'Error: Wrong product name.'
         return, 0
      END
      
   ENDCASE

   return, arr
   
END 
