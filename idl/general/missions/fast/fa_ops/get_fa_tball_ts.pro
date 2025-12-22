;+
; FUNCTION:
;	GET_FA_TBALL_TS
;
; DESCRIPTION:
;
;	Function to load a time sequence of FAST Teams burst data for all species from the
;	SDT program shared memory buffers.
;
;	The philosophy for the number of array dimensions is to keep them to a minimum,
;	   except that duplication of measurement parameters over npts (the number of 2-d distributions)
;	   takes place in as far as required for consistency with get_md_ts_from_sdt, which
;	   has min1,max1 etc duplicated npts times.
;	   This is not necessarily consistent with Loran/McFadden, where duplication seems a bit out of
;	   control and without simple rules.
;
;	A structure of the following format is returned:
;	   (Note: 1.  nnrgs=nenergy; nnrgs is retained because of frequent use in other software.
;	          2.  "2-d distribution" refers to a single data sample taken from 16 sectors in a plane
;	                and at 48 energies.)
;	          3.  The "look" or "boresight" direction can be computed from quantities below,
;	                but remember that ion direction vector is opposite to look direction.)  
;
;	   DATA_NAME     STRING    'Tms Burst All'  ; Data Quantity name
;	   VALID         INT       1                ; Data valid flag
;	   PROJECT_NAME  STRING    'FAST'           ; project name
;	   UNITS_NAME    STRING    'Counts'         ; Units of this data
;	   UNITS_PROCEDURE  STRING 'proc'           ; Units conversion proc
;	   TIMES         DOUBLE    Array(npts)      ; Start Time of sample (should be true time of
	                                               ; start of data, not original packet time tag
;	   END_TIMES     DOUBLE    Array(npts)      ; End time of sample
;	   INTEG_T       DOUBLE    Array(npts)      ; Integration time for each individual energy step
	                                               ; (dat.endTimes-dat.times)/dat.dimsizes(0)
;	   NBINS         INT       nbins            ; Number of angle bins  (16)
;	   NENERGY       INT       nnrgs            ; Number of energy bins  (48)
;	   NPTS          INT       npts             ; number of data 'points' = # of 2d distributions
;	   CALIBRATED    INT       calibrated       ; flags calibrated data      mb
;	   CALIBRATED_UNITS STRING units            ; calibrated units string    mb 
;	   DATA          FLOAT     Array(nnrgs, nbins, nspec,npts) 
	                             ; Data quantities; nspec=4, may require wrk to change
;	   ENERGY        FLOAT     Array(nnrgs,npts)   ; Ion energy, duplicated npts times (ev)
;	   THETA         FLOAT     Array(nbins,npts)   ; Angle of sector, duplicated npts times (deg)
;	   THETA_FOV     FLOAT     Array(nbins,npts)   ; Angle of sector, duplicated npts times (deg),
	                         ; Measured ccw from between bins 3 and 4 (0-15 range) in detector plane
	                         ; For a diagram see FAST/TEAMS Fields-of-View, D.M. Klumpar, May, 1995
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, npts)       ; Width of energy bins (ev)
;	   DTHETA        FLOAT     Array(nbins,npts)        ; Delta Theta acceptance width, roughly
	                                                       ; actually separation between sectors
;	   EFF           FLOAT     Array(nnrgs,nbins=16,nspec=4)        ; Efficiency (GF)
;	   SPIN_FRACT    FLOAT     Array(nbins)  ; fraction of dat.time-dat.end_time
	                                            ; over which the measurement was active
;	   MODE          BYTE      Array(npts)   ; teams mode for each time
;	   SPHASE        INT       Array(npts)   ; spin phase wrt sun, corrected to dat.times 
                             ; (start-of-acquisition) within this program (as of July 30 1997 mb)
 ; (the original sphase in header_bytes is from the data read time, not the actual data acquisition time) 
;	   SNUMBER       BYTE      Array(npts)   ; spin number
;	   MAGDIR        FLOAT     Array(npts)   ; phase of sun wrt magfld 0 crossing, 0-4095 range,
	                                            ; S/C Y component of field, -/+ crossing                                                                                
;	   MASS          FLOAT     0.0104389 *[16.,1.,4.,2.]  ; Mass eV/(km/sec)^2 (actually mass/(charge/e))
;	   GEOMFACTOR    FLOAT     .0015  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(44,npts) ; Header bytes; 44 was 25. don't know why, changed, mb
	                                             ; 3 sets of 14 with 2 additional bytes (L. Kistler)
;	   HDR_TIME      FLOAT     Array(npts)    ; added to allow timing cross-checks at higher level
      ; these are explicitly the times attached to sphase in the header (which are still wrong, being the
     ; times corrected for the data, not the original times correct for sphase) mb july 29 1997
;	   EFF_VERSION                            ; version number returned by FA_TTOF_CALIBRATION 
;
; CALLING SEQUENCE:
;
; 	data = get_fa_tball_ts (inputTime,endtime, [START=start | EN=en | NPTS=npts | /PANF | /PANB
;                          | /ALL | IDXST=idxst)
; ARGUMENTS:
;
;	inputTime   This argument gives a time handle from which
;	            to start to take data.  It may be either a string
;	            with the following possible formats:
;	                'YY-MM-DD/HH:MM:SS.MSC'  or
;	                'HH:MM:SS'     (use reference date)
;	            or a number, which will represent seconds
;	            since 1970 (must be a double > 94608000.D), or
;	            a hours from a reference time, if set.
;	            time will always be returned as a double
;	            representing the actual data time found in
;	            seconds since 1970.
;
;	endtime     similar, ending time of data interval
;
; KEYWORDS:
;
;	START       If non-zero, get data from the start time
;	            of the data instance in the SDT buffers
;
;	NPTS        If given will determine the number of 2-D distributions to get,
;	                           overriding the endTime specification
;
;	EN          If non-zero, get data at the end time
;	            of the data instance in the SDT buffers
;
;	PANF, PANB  Untested. Meant to override other timing specifications, pan forward or backward
;
;	ALL         Untested. get all data, meant to override other time specs.
;
;	IDXST       Untested. get data at a certain index relative to start of TIMESPAN.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_tba.pro	1.8 09/04/96
;	Originally written by Jonathan M. Loran,  University of
;	California at Berkeley, Space Sciences Lab.   June '95
;	Modified to get_fa_tball by M Boehm may 14 1997. Untested.
;	LAST MODIFICATION:  Modified to get_fa_tball_ts by M Boehm may 28 1997. Tested with a few orbits
;	   only. HDR_TIME returned separately largely for error checking purposes july 11. Note
;	   that most other error checking from get_fa_tb* has been removed, due to the fact
;	   that I couldn't figure out when most of it would apply.
;	Last minor (hopefully not functional) mods July 15, 1997 mb
;	Added theta_fov and documentation, July 17, 1997, ESC.
;       Comment-olny changes July 24 mb.
;       tempw added (line ~162) to avoid where()=-1 problem ~nov 24 1997 mb
;-

FUNCTION Get_fa_tball_ts, inputTime, endtime, NPTS=npts, START=start,  $
     EN=en, PANF=pf,PANB=pb, ALL=all, IDXST=idxst  

                  

      nspec=4
      spec = [3,0,2,1]	; dat.data has [O+,H+,He+,He++} ordering ; spec(i) gives the calibration 
            ; index for dat.data(*,*,i) where [0,1,2,3]=[H+,He++,He+,o+]   mb

      first = 1


      ; get data dat.values into correct dimensions here

      data_name = 'Tms Burst All'
      units_name = 'Counts'
      units_procedure = 'convert_tms_units'

      ; get the header bytes for this time

      hdr_time = inputTime
      hdr_dat = get_fa_tb_hdr_ts (hdr_time,endtime, NPTS=npts, START=start,  $
          EN=en, PANF=pf,PANB=pb, ALL=all, IDXST=idxst)
      IF hdr_dat.valid EQ 0 THEN BEGIN
        print, 'Error getting Header bytes for these packets.  .'
         header_bytes = hdr_dat.bytes
      ENDIF ELSE BEGIN
         header_bytes = hdr_dat.bytes
      ENDELSE

      mode = reform(header_bytes(6,*) AND 15B)	    ; teams mode, dimension = number of time points=hdr_dat.npts

;   Following determines the spin phase at the actual data acquistiion time, which requires
;   a correction back from the read time (to which the header_bytes(0 or 1,*) correspond) 
;   to the acquisition time (as given in dat.times).
      nperspin=intarr(hdr_dat.npts) & nperspin(*)=32         ; number of sweeps per spin
      tempw=where(2*(mode/2) eq mode and mode ne 0,wcount)
      if wcount gt 0 then nperspin(tempw)=64 
      n_cycles=nperspin/4        ; number of cycles of burst read operation per spin (4 bursts held in memory)
      sphase_r = reform(header_bytes(0,*) + ISHFT(1*(header_bytes(1,*) AND 3B), 8))  ; sun phase at mem read
      spin_frac_r=sphase_r/1024.              ; spin fraction at mem read
      address=header_bytes(4,*)               ; storage address in TEAMS memory of present data
; since the time attached to sphase as obtained from the header bytes is no longer the data
; readout time (at which sphase was acquired), 
; but the beginning-of-sweep time, we need to correct the sphase backwards
; to what it was at that beginning of sweep
      print, 'new sphase algorithm'
      nsphase_per_sweep=1024/nperspin
      read_sweep_no=fix(nperspin*spin_frac_r)
      sweep_in_cycle=fix(address/8)
      fcycleno=float(read_sweep_no-sweep_in_cycle)/4.     ; floating version of the (4-sweep) cycle number
              ; of acquisition, possible exception required for negative result when taking integer?
      cycleno=fix(fcycleno+1)-1            ; avoid exception for negative result
      acq_sweep_no=4*cycleno+sweep_in_cycle
      sphase=1024.*float(acq_sweep_no)/float(nperspin)    ;  sphase given by number of sweep within
                           ; spin (sun-pulse synchronized!)  
    sphase(where(sphase lt 0))=sphase(where(sphase lt 0))+1024
  ;  end sun phase calculation
      snumber = reform(ISHFT(header_bytes(1,*), -2))   ; Spin number
;      addr = header_bytes(4,*)
      ;magdir = reform((ISHFT(header_bytes(2,*), -4) + 			$ 
      ;        ISHFT((1*header_bytes(3,*)), 4))*(360.0/4096.0))
      magdir = reform((ISHFT(header_bytes(2,*), -4) + 			$
              ISHFT((1*header_bytes(3,*)), 4)))   ; Removed conversion for consistency with sphase,
                                                 ;  ESC, 7/3/97.              
      t1=hdr_dat.start_time+0.5*(hdr_dat.time(1)-hdr_dat.time(0))
      dat = get_md_ts_from_sdt ('Tms_Burst_Data', 2001,T1=t1, T2=t2, NPTS=npts, START=start,  $
          EN=en, PANF=pf,PANB=pb, ALL=all, IDXST=idxst)

      IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}

      data = FLOAT (dat.values)   ; removed a reform instruction which normally doesn't do anything may 27 1997 mb ??
      theta=FLTARR(dat.dimsizes(1),dat.npts)  ; dat.dimsizes(1)=16=number of angular sectors assumed
      FOR i = 0, 7 DO theta(i,*)=78.75 - i*22.5
      FOR i = 8, 15 DO theta(i,*)=theta(15-i,*)

      ; Variable theta_fov varies through a full 360 deg.; can be used in place of theta when
      ;  needed to simplify geometry and logic, ESC, 7/16/97.      
      ; theta_fov measured ccw from direction of separator between teams directions 3,4 (0-15 range)
      ;  For a diagram see FAST/TEAMS Fields-of-View, D.M. Klumpar, May, 1995
      theta_fov = FLTARR(dat.dimsizes(1),dat.npts)  ; dat.dimsizes(1)=16=number of angular sectors assumed
      theta_fovs = indgen(dat.dimsizes(1))*22.5 - 78.75  ; Create 16 angles at sector center-lines
      ; Duplicate teams FOV directions for all data samples for consistency with other phase space
      ;  variables
      FOR i = 0, dat.dimsizes(1)-1 DO theta_fov(i,*) = theta_fovs(i)

      dtheta = FLOAT(REPLICATE(22.5,dat.dimsizes(1),npts))   
;     energy = FLOAT (REBIN((dat.max1+dat.min1)/2., dat.dimsizes(0),dat.dimsizes(1),dat.npts))  
      denergy = float(dat.max1 - dat.min1)
      energy = float(dat.max1 + dat.min1)/2
      geom = REPLICATE (1., dat.dimsizes(1))
      mass =  0.0104389*[16.,1.,4.,2.] ; mass eV/(km/sec)^2 , mass/charge for [O+,H+,He+,He++]
                                      ; (the order of dat.data) - mb
      geomfactor = 0.0015


      spin_fract = REPLICATE(1, dat.dimsizes(1))  ;
                   ; spin_fract is apparently in general the fraction of dat.time-dat.end_time
                   ; over which the measurement was active mb

      pac = header_bytes(11)		;For post acceleration voltage; pac=168 sometimes
      eff = fltarr(dat.dimsizes(0),dat.dimsizes(1),nspec)
      for i=0,nspec-1 do begin
        species=spec(i)
        eff(*,*,i) = FA_TTOF_CALIBRATION(energy, species, pac, eff_version)
      endfor

      ; load up the data into IDL data structs

      RETURN,  {data_name:	data_name, 				      $
                 valid: 	1, 					      $
                 project_name:	'FAST',					      $
                 units_name: 	units_name, 				      $
                 units_procedure: units_procedure,			      $
                 times: 	dat.times,				      $
                 end_times: 	dat.endTimes,				      $
                 integ_t: 	(dat.endTimes-dat.times)/dat.dimsizes(0),     $
                 nbins: 	dat.dimsizes(1), 			      $
                 nenergy: 	dat.dimsizes(0), 			      $
                 npts:          dat.npts,                                     $
                 calibrated:     0,                                           $
                 calibrated_units:  'counts',                                 $
                 data: 		data,					      $
                 energy: 	energy, 				      $
                 theta: 	theta,                                        $
                 theta_fov:	theta_fov,				      $
                 geom: 		geom, 	       				      $
                 denergy: 	denergy,       				      $
                 dtheta: 	dtheta, 				      $
                 eff: 		eff,					      $
                 spin_fract:	spin_fract,				      $
                 mode:		mode,					      $
                 sphase:        sphase,					      $
                 snumber:	snumber,				      $
                 magdir:	magdir,                                       $ 
                 mass: 		mass,					      $
                 geomfactor: 	geomfactor,				      $
                 header_bytes: 	header_bytes,				      $
                 hdr_time:      hdr_dat.time,                                 $
                 eff_version:   eff_version}

END 
