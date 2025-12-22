;+
; NAME:  make_fa_esa_struct
;
; PURPOSE:
;
;	Build an esa dat structure given dimentions
;
; CALLING SEQUENCE:
;
;	dat=make_fa_esa_struct(dimsizes)
; 
; INPUTS:
;
;	dimsizes:	a two (or three) dimensional array
;
; OUTPUTS:
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'data name'         ; Data Quantity name
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
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   EFF           FLOAT     Array(nnrgs)        ; Efficiency (GF)
;	   MASS          DOUBLE    5.68566e-6          ; Particle Mass
;	   GEOMFACTOR    DOUBLE    0.000147            ; Bin GF
;	   HEADER_BYTES  BYTE      Array(44)	       ; Header bytes
;	   INDEX         LONG      idx                 ; Index in sdt buffers
;
; MODIFICATION HISTORY:
;	@(#)make_fa_esa_struct.pro	1.1 05/30/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   May '97
;
;-

FUNCTION make_fa_esa_struct, dimsizes

   RETURN,  {data_name:	'data_name',					$
              valid: 		1, 					$
              project_name:	'FAST', 				$
              units_name: 	'counts', 				$
              units_procedure:  'units_procedure',			$
              time: 		1.D, 					$
              end_time: 	2.D, 					$
              integ_t: 		3.D,					$
              nbins: 		dimsizes(1), 				$
              nenergy: 		dimsizes(0), 				$
              data: 		fltarr(dimsizes(0),dimsizes(1)),	$
              energy: 		fltarr(dimsizes(0),dimsizes(1)),	$
              theta: 		fltarr(dimsizes(0),dimsizes(1)),	$
              geom: 		fltarr(dimsizes(0),dimsizes(1)),	$
              denergy: 		fltarr(dimsizes(0),dimsizes(1)),	$
              dtheta: 		fltarr(dimsizes(0),dimsizes(1)),	$
              eff: 		fltarr(dimsizes(0)),			$
              mass: 		4.,					$
              geomfactor: 	5.,					$
              header_bytes: 	bytarr(44),				$
              index:		1L}
   
END
