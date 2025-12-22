;+
; FUNCTION:
; 	 GET_FA_SEB_C
;
; DESCRIPTION:
;
;
;	function to load FAST Sesa burst combined data from the SDT program shared
;	memory buffers.  This is the caching version
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Sesa Burst Combined'; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; project name
; 	   UNITS_NAME    STRING    'Counts'            ; Units of this data
; 	   UNITS_PROCEDURE  STRING 'proc'              ; Units conversion proc
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   INTEG_T       DOUBLE    3.0000000           ; Integration time
;	   NBINS         INT       nbins               ; Number of angle bins
;	   NENERGY       INT       nnrgs               ; Number of energy bins
;	   DATA          FLOAT     Array(nnrgs, nbins) ; Data qauantities
;	   ENERGY        FLOAT     Array(nnrgs, nbins) ; Energy steps
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Angle for bins
;	   GEOM          FLOAT     Array(nnrgs, nbins) ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nnrgs, nbins) ; Delta Theta
;	   EFF           FLOAT     Array(nnrgs)        ; Efficiency (GF)
;	   MASS          DOUBLE    5.68566e-6          ; Particle Mass
;	   GEOMFACTOR    DOUBLE    0.000625            ; Bin GF
;	   HEADER_BYTES  BYTE      Array(44)	       ; Header bytes
;	   INDEX         LONG      idx                 ; Index in sdt buffers
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_seb (time, [START=start | EN=en | ADVANCE=advance |
;				RETREAT=retreat], CALIB=calib,
;				INDEX=idx, FLUSH=flush, CACHE_SIZE=cache_size)
;
; ARGUMENTS:
;
;	time 			This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
;
; KEYWORDS:
;
;	START			If non-zero, get data from the start time
;				of the data instance in the SDT buffers
;
;	EN			If non-zero, get data at the end time
;				of the data instance in the SDT buffers
;
;	ADVANCE			If non-zero, advance to the next data point
;				following the time or index input
;
;	RETREAT			If non-zero, retreat (reverse) to the previous
;				data point before the time or index input
;
;	CALIB			If non-zero, caclulate geometry
;				factors for each bin instead of using 1.'s
;
;	INDEX			If index is set, it is used for selecting
;				the index to get data.
;
;	FLUSH			If non-zero, will flush the data cache
;				This is useful to force a re-read of sdt
;				buffers in case the data has changed.
;
;	CACHE_SIZE		If gt 0, will reset the length in points
;				of data to cache.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_seb_c.pro	1.2 08/30/99
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;
;	Major upgrade, using get_cache_md_from_sdt to load a time range
;	at once to cache data in idl for speedup.   J.M. Loran Apr. 97
;-

FUNCTION Get_fa_seb_c, inputTime, START=start, EN=en, ADVANCE=advance,  $
                     RETREAT=retreat, CALIB=calib,                    $
                     INDEX=index, FLUSH=flush, CACHE_SIZE=cache_size

   ; cache common
   common fa_seb_common, fa_seb_cache, fa_seb_cache_hsk, fa_seb_dat, $
                         fa_seb_hdr_cache_hsk, fa_seb_hdr_cache
   
   data_name = 'Sesa_Cmb_Burst_Data'
   cidx = get_cache_md_from_sdt (data_name, 2001,                         $
                                 fa_seb_cache_hsk, fa_seb_cache,          $
                                 TIME=inputTime, START = start, EN = en,  $
                                 ADVANCE = advance, RETREAT = retreat,    $
                                 INDEX=index, FLUSH = flush,              $
                                 CACHE_SIZE = cache_size)

   IF cidx LT 0 THEN          RETURN, {data_name: 'Null', valid: 0}

   ; if the dat struct isn't defined, or dims are wrong do it now
   
   IF n_elements (fa_seb_dat) EQ 0 THEN $
     fa_seb_dat = make_fa_esa_struct(fa_seb_cache.dimsizes)
   IF ( fa_seb_dat.nenergy NE fa_seb_cache.dimsizes(0) ) OR    $
      ( fa_seb_dat.nbins NE fa_seb_cache.dimsizes(1) ) THEN    $
     fa_seb_dat = make_fa_esa_struct(fa_seb_cache.dimsizes)
   
   ; setup times

   fa_seb_dat.time = fa_seb_cache.times(cidx)
   fa_seb_dat.end_time = fa_seb_cache.endtimes(cidx)
   inputTime = fa_seb_dat.time
   
   ; get data values into correct dimensions here

   fa_seb_dat.index = cidx + fa_seb_cache.st_index
   fa_seb_dat.data_name = data_name
   fa_seb_dat.units_name = 'Counts'
   fa_seb_dat.units_procedure = 'convert_esa_units2'
   min1 = fa_seb_cache.min1(*,cidx)
   max1 = fa_seb_cache.max1(*,cidx)
   min2 = fa_seb_cache.min2(*,cidx)
   max2 = fa_seb_cache.max2(*,cidx)
   IF (where(max2-min2 lt 0))(0) NE -1 THEN      $
     max2(where(max2-min2 lt 0))=max2(where(max2-min2 lt 0))+360
   fa_seb_dat.theta = FLOAT (REPLICATE (1., fa_seb_cache.dimsizes(0)) # $
                             ((max2+min2)/2.) mod 360.)
   fa_seb_dat.energy = FLOAT (REBIN(([max1+min1])/2., fa_seb_cache.dimsizes(0), $
                                    fa_seb_cache.dimsizes(1)))
   fa_seb_dat.denergy = FLOAT (REBIN ([max1 - min1], fa_seb_cache.dimsizes(0), $
                                      fa_seb_cache.dimsizes(1)))
   fa_seb_dat.dtheta = FLOAT (REPLICATE (1., fa_seb_cache.dimsizes(0)) # $
                              (max2 - min2))
   fa_seb_dat.eff = REPLICATE (1., fa_seb_cache.dimsizes(0))
   fa_seb_dat.mass = 5.68566e-6
   fa_seb_dat.geomfactor = .000625

   ; get the header bytes for this index

   hdr_idx  = cidx+fa_seb_cache.st_index
   hidx = get_cache_ts_1p_from_sdt ('Sesa_Cmb_Burst_Packet_Hdr', 2001,	    $
                                    fa_seb_hdr_cache_hsk, fa_seb_hdr_cache, $
                                    INDEX=hdr_idx,			    $
                                    FLUSH = flush, CACHE_SIZE = cache_size)
   
   ; handle header setup and related effects
   
   IF hidx LT 0 THEN BEGIN
      print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
      fa_seb_dat.header_bytes = BYTARR(44)
      got_header_bytes = 0
      hdr_dat = {valid: 0, time: 0.D, bytes: bytarr(44)}
   ENDIF ELSE BEGIN
       hdr_dat = {valid: fa_seb_hdr_cache.valid,      $
                  time:  fa_seb_hdr_cache.time(hidx), $
                  bytes: fa_seb_hdr_cache.comp1(*,hidx)}
      fa_seb_dat.header_bytes = hdr_dat.bytes
      got_header_bytes = 1
      
; ??????????????????????????
       ; mcfadden: The following corrects for s/c spin during the sweep, will also 
       ; work for eesa/iesa survey as long as nswp_spin=32or64.
       ; NOTE: This will not work correctly for nswp_spin = 16.
;   	nswp_spin=3072/(fa_seb_cache.dimsizes(0)*2^(ishft((hdr_dat.bytes(4) and 48),-4)))
;        fa_seb_dat.theta = fa_seb_dat.theta + ((180./(nswp_spin))* $ 
;                                               (findgen(fa_seb_cache.dimsizes(0))- $
;                                                fa_seb_cache.dimsizes(0)/2+.5)/ $
;                                               (fa_seb_cache.dimsizes(0)/2.) $
;                                              ) # replicate(1.,fa_seb_cache.dimsizes(1))
; ??????????????????????????
   ENDELSE

   ; get geometry factors

   IF NOT keyword_set(calib) THEN  $
       calib = getenv ('FAST_ESA_CALIBRATION')
   
; done calib yet, maybe don't know how (JML Aug 1999)
   calib=0
   IF keyword_set(calib) AND got_header_bytes THEN BEGIN
       geom = calc_fa_esa_geom({data_name:	data_name, $
                                time:		inputTime, $
                                header_bytes:	hdr_dat.bytes})
       IF geom(0) GE 0 AND $
         (n_elements(geom) EQ fa_seb_cache.dimsizes(0) * $
          fa_seb_cache.dimsizes(1)) THEN BEGIN
           fa_seb_dat.geom = $
             reform(geom, fa_seb_cache.dimsizes(0), fa_seb_cache.dimsizes(1)) 
       ENDIF ELSE  BEGIN
           PRINT, 'Error getting geom factors for this packet.  Values will be 1.'
           fa_seb_dat.geom = $
             FLOAT(REPLICATE (1., fa_seb_cache.dimsizes(0), fa_seb_cache.dimsizes(1)))
       ENDELSE
   ENDIF ELSE  BEGIN
       fa_seb_dat.geom = $
         FLOAT(REPLICATE (1., fa_seb_cache.dimsizes(0), fa_seb_cache.dimsizes(1)))
   ENDELSE

   ; blank out energy bin 0 (retrace bin)
   ; if header bit one in byte six is on, then we have a double
   ; retrace, so blank out e-bin 1 too

; ??????
;   fa_seb_dat.denergy(0,*) = 0.
;   IF (2 AND hdr_dat.bytes(6)) NE 0 THEN  fa_seb_dat.denergy(1,*) = 0.
; ??????

   ; delta-T  (Times six, because this is six combined analyzers)

   fa_seb_dat.integ_t = ((fa_seb_cache.endTimes(cidx) - $
                          inputTime)/fa_seb_cache.dimsizes(0)) * 6
   
   ; finally, the data
   
   fa_seb_dat.data = fa_seb_cache.values(*,*,cidx)
   
   RETURN, fa_seb_dat
   
END 
