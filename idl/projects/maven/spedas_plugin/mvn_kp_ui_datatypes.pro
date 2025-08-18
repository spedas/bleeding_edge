;+
;NAME:
;mvn_kp_ui_datatypes
;PURPOSE:
;Uses an array to create a pointer array to the MAVEN KP data type
;variables. Messy, but these are not likely to change.
;CALLING SEQUENCE:
; paramArray = mvn_kp_ui_datatypes()
;INPUT: none
;OUTPUT: 
;A ptrarr(8) each with an array of strings for data types, one
;for each of LPW,MAG,NGIMS,SEP,STATIC,SWEA,SWIA,SPICE
;KEYWORDS:
;allvars = a list of tplot variables created by the load procedure
;HISTORY: 2015-10-14, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: jimm $
;$LastChangedDate: 2015-10-21 14:16:06 -0700 (Wed, 21 Oct 2015) $
;$LastChangedRevision: 19130 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/spedas_plugin/mvn_kp_ui_datatypes.pro $
;-
Function mvn_kp_ui_datatypes, allvars = allvars, _extra=_extra

  
  allvars = ['LPWElectronDensity','LPWElectronDensityQuality','LPWElectronTemperature','LPWElectronTemperatureQuality',$
             'LPWSpacecraftPotential','LPWSpacecraftPotentialQuality','LPWE-fieldPower2-100Hz','LPWE-field2-100HzQuality',$
             'LPWE-fieldPower100-800Hz','LPWE-field100-800HzQuality','LPWE-fieldPower0.8-1.0Mhz','LPWE-field0.8-1.0MhzQuality',$
             'LPW-EUVEUVIrradiance0.1-7.0nm','LPW-EUVIrradiance0.1-7.0nmQuality','LPW-EUVEUVIrradiance17-22nm',$
             'LPW-EUVIrradiance17-22nmQuality','LPW-EUVEUVIrradianceLyman-alpha','LPW-EUVIrradianceLyman-alphaQuality',$
             'SWEASolarWindElectronDensity','SWEASolarWindE-DensityQuality','SWEASolarWindElectronTemperature',$
             'SWEASolarWindE-TemperatureQuality','SWEAFlux,e-Parallel(5-100ev)','SWEAFlux,e-(5-100ev)Quality',$
             'SWEAFlux,e-Parallel(100-500ev)','SWEAFlux,e-(100-500ev)Quality','SWEAFlux,e-Parallel(500-1000ev)',$
             'SWEAFlux,e-(500-1000ev)Quality','SWEAFlux,e-Anti-par(5-100ev)','SWEAFlux,e-Anti-par(100-500ev)',$
             'SWEAFlux,e-Anti-par(500-1000ev)','SWEAElectronSpectrumShape','SWEASpectrumShapeQuality','SWIAH+Density',$
             'SWIAH+DensityQuality','SWIAH+FlowVelocityMSO','SWIAH+FlowMSOQuality','SWIAH+Temperature',$
             'SWIAH+TemperatureQuality','SWIASolarWindDynamicPressure','SWIASolarWindPressureQuality',$
             'STATICSTATICQualityFlag','STATICH+Density','STATICH+DensityQuality','STATICO+Density','STATICO+DensityQuality',$
             'STATICO2+Density','STATICO2+DensityQuality','STATICH+Temperature','STATICH+TemperatureQuality',$
             'STATICO+Temperature','STATICO+TemperatureQuality','STATICO2+Temperature','STATICO2+TemperatureQuality',$
             'STATICO2+FlowVelocityMAVEN_APP','STATICO2+FlowMAVEN_APPQuality','STATICO2+FlowVelocityMSO',$
             'STATICO2+FlowMSOQuality','STATICH+OmniFlux','STATICH+Energy','STATICH+EnergyQuality','STATICHe++OmniFlux',$
             'STATICHe++Energy','STATICHe++EnergyQuality','STATICO+OmniFlux','STATICO+Energy','STATICO+EnergyQuality',$
             'STATICO2+OmniFlux','STATICO2+Energy','STATICO2+EnergyQuality','STATICH+DirectionMSO','STATICH+AngularWidth',$
             'STATICH+WidthQuality','STATICPickupIonDirectionMSO','STATICPickupIonAngularWidth','STATICPickupIonWidthQuality',$
             'SEPIonFluxFOV1F','SEPIonFluxFOV1FQuality','SEPIonFluxFOV1R','SEPIonFluxFOV1RQuality','SEPIonFluxFOV2F',$
             'SEPIonFluxFOV2FQuality','SEPIonFluxFOV2R','SEPIonFluxFOV2RQuality','SEPElectronFluxFOV1F',$
             'SEPElectronFluxFOV1FQuality','SEPElectronFluxFOV1R','SEPElectronFluxFOV1RQuality','SEPElectronFluxFOV2F',$
             'SEPElectronFluxFOV2FQuality','SEPElectronFluxFOV2R','SEPElectronFluxFOV2RQuality','SEPLookDirection1-FMSO',$
             'SEPLookDirection1-RMSO','SEPLookDirection2-FMSO','SEPLookDirection2-RMSO','MAGMagneticFieldMSO',$
             'MAGMagneticMSOQuality','MAGMagneticFieldGEO','MAGMagneticGEOQuality','MAGMagneticFieldRMSDev',$
             'MAGMagneticRMSQuality','NGIMSDensityHe','NGIMSDensityHePrecision','NGIMSDensityHeQuality','NGIMSDensityO',$
             'NGIMSDensityOPrecision','NGIMSDensityOQuality','NGIMSDensityCO','NGIMSDensityCOPrecision','NGIMSDensityCOQuality',$
             'NGIMSDensityN2','NGIMSDensityN2Precision','NGIMSDensityN2Quality','NGIMSDensityNO','NGIMSDensityNOPrecision',$
             'NGIMSDensityNOQuality','NGIMSDensityAr','NGIMSDensityArPrecision','NGIMSDensityArQuality','NGIMSDensityCO2',$
             'NGIMSDensityCO2Precision','NGIMSDensityCO2Quality','NGIMSDensity32+','NGIMSDensity32+Precision',$
             'NGIMSDensity32+Quality','NGIMSDensity44+','NGIMSDensity44+Precision','NGIMSDensity44+Quality','NGIMSDensity30+',$
             'NGIMSDensity30+Precision','NGIMSDensity30+Quality','NGIMSDensity16+','NGIMSDensity16+Precision',$
             'NGIMSDensity16+Quality','NGIMSDensity28+','NGIMSDensity28+Precision','NGIMSDensity28+Quality','NGIMSDensity12+',$
             'NGIMSDensity12+Precision','NGIMSDensity12+Quality','NGIMSDensity17+','NGIMSDensity17+Precision',$
             'NGIMSDensity17+Quality','NGIMSDensity14+','NGIMSDensity14+Precision','NGIMSDensity14+Quality',$
             'SPICESpacecraftGEO','SPICESpacecraftMSO','SPICESpacecraftGEOLongitude','SPICESpacecraftGEOLatitude',$
             'SPICESpacecraftSolarZenithAngle','SPICESpacecraftLocalTime','SPICESpacecraftAltitudeAeroid',$
             'SPICESpacecraftAttitudeGEO','SPICESpacecraftAttitudeMSO','SPICEAPPAttitudeGEO','SPICEAPPAttitudeMSO',$
             'SPICEOrbitNumber','SPICEInboundOutboundFlag','SPICEMarsSeason(Ls)','SPICEMars-SunDistance',$
             'SPICESubsolarPointGEOLongitude','SPICESubsolarPointGEOLatitude','SPICESub-MarsPointontheSunLongitude',$
             'SPICESub-MarsPointontheSunLatitude','SPICERotmatrixMARS->MSO','SPICERotmatrixSPCCRFT->MSO']

  instr = ['LPW-EUV','LPW','MAG','NGIMS','SEP','STATIC','SWEA','SWIA','SPICE']
  ninstr = n_elements(instr)
  paramarray = ptrarr(ninstr)
  nvars = n_elements(allvars)
  used = bytarr(nvars)          ;Need a used flag because of LPW, LPW-EUV
  For j = 0, ninstr-1 Do Begin
     nlen = strlen(instr[j])
     sss = where(strmid(allvars, 0, nlen) Eq instr[j] And used Eq 0, nj)
     If(nj Gt 0) Then Begin
        used[sss] = 1
        paramarray[j] = ptr_new(['*', strmid(allvars[sss], nlen)])
     Endif Else dprint, 'No '+instr[j]+' Datatypes?'
  Endfor

  Return, paramarray
End

