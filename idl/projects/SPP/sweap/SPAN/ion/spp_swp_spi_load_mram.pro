PRO spp_swp_spi_load_mram

   ;; SPAN-I Parameters
   common spi_param, param, dict

   ;; If Parameters have not yet been loaded
   IF ~isa(param) THEN spp_swp_spi_param
   dict = orderedhash()

   ;; Read SPAN-I Flight MRAM
   openr,1,'~/Desktop/spi_mem.bin'
   file = bytarr(2000000)
   readu, 1, file
   close, 1

   ;; Extract MRAM addresses and names
   tags = tag_names(param.mem)
   nn = n_elements(tags)
   pp_tags = intarr(nn)

   ;; Loop through products and determine
   ;; their size and location in MRAM
   FOR i=0, nn-1 DO $
    IF strmatch(tags[i], "*MRAM*") THEN BEGIN

      ;; Separate field name
      tmp = strsplit(tags[i],"_",/extract)

      ;; Find corresponding product size
      CASE strmid(tmp[0],0,4) OF
         'SLUT': siz = param.mem.SLUT_SRAM_SIZE
         'PSUM': siz = param.mem.PSUM_SRAM_SIZE
         'MLUT': siz = param.mem.MLUT_SRAM_SIZE
         'PSUM': siz = param.mem.PSUM_SRAM_SIZE
         'FSLU': siz = param.mem.FSLUT_SRAM_SIZE
         'TSLU': siz = param.mem.TSLUT_SRAM_SIZE
         'MRLU': siz = param.mem.MRLUT_SRAM_SIZE
         'ALLU': siz = param.mem.ALLUT_SRAM_SIZE
         'EDLU': siz = param.mem.EDLUT_SRAM_SIZE
         'SPSU': siz = param.mem.SPSUM_SRAM_SIZE
         'PMBI': siz = param.mem.PMBINS_SRAM_SIZE
         'PROD': siz = param.mem.PROD_SRAM_SIZE
         'SCI':  siz = param.mem.SLUT_SRAM_SIZE
         'ES':BEGIN
            IF tmp[1] EQ 'FSLUT' THEN siz = param.mem.FSLUT_SRAM_SIZE
            IF tmp[1] EQ 'TSLUT' THEN siz = param.mem.TSLUT_SRAM_SIZE
         END
         'MODE':BEGIN
            CASE strmid(tmp[1],0,4) OF 
            'PSUM': siz = param.mem.PSUM_SRAM_SIZE
            'MRLU': siz = param.mem.MRLUT_SRAM_SIZE
            'ALLU': siz = param.mem.ALLUT_SRAM_SIZE
            'EDLU': siz = param.mem.EDLUT_SRAM_SIZE
            'SPSU': siz = param.mem.SPSUM_SRAM_SIZE
            'PMBI': siz = param.mem.PMBINS_SRAM_SIZE
         ENDCASE
         END
         ELSE:stop, strmid(tmp[0],0,4)
      ENDCASE

      ;; SRAM Size contains 32 Bytes per memory block
      ;; MRAM Size contains 8 Bytes per memory block
      siz = siz*4.-1.

      ;; Remove 'MRAM' and 'ADDR' from tag
      nnn = n_elements(tmp)-2
      str_tmp = strjoin(tmp[0:nnn-1],'_')

      ;; Get index and insert array into dictionary
      tmp1 = execute('ind = param.mem.'+tags[i])
      dict += orderedhash(str_tmp,file[ind:ind+siz]) 

   ENDIF

END
