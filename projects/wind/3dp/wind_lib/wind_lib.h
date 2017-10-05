/*==============================================================================
|------------------------------------------------------------------------------|
|									       |
|				    WIND_LIB.H				       |
|									       |
|------------------------------------------------------------------------------|
|									       |
| CONTENTS								       |
| --------								       |
| This header file contains preprocessor definitions (macros), typedefs, dec-  |
l arations, etc. for the wind_lib library.				       |
|									       |
| AUTHOR								       |							       | ------								       |
| Davin Larson,   Space Sciences Laboratory, U.C. Berkeley		       |
| Todd H. Kermit, Space Sciences Laboratory, U.C. Berkeley		       |
|									       |	------------------------------------------------------------------------------*/

#ifndef WIND_LIB_H
#define WIND_LIB_H

/*  Include header files   */

#include <stdio.h>

#include "filter.h"
//  basic entry point

#include "winddefs.h"
//  basic definitions for wind structures

#include "defs.h"
//  basic typedefs  (uint4 uint2 etc.)

#include "frame_dcm.h"
// Used for filtering and loading data files 

#include "wind_pk.h"
// contains routines that store and retrieve data packets

#include "windmisc.h"
//  contains miscellaneous routines
//  includes definition of FILE *debug for debugging

#include "pcfg_dcm.h"
//  contains pesa configuration routines

#include "ecfg_dcm.h" 
//  contains eesa configuration routines

#include "esteps.h"
//  contains routines that get energy steps for eesa and pesa
//  and convert data to special units

#include "emom_dcm.h"
//  eesa moment decomutation routines

#include "pmom_dcm.h"
//  pesa moment decomutation routines

#include "spec_dcm.h"
//  spectra decomutation routines

#include "kpd_dcm.h"
//  key parameter decomutation routines

#include "hkp_dcm.h"
//  house keeping decomutation routines

#include "pl_dcm.h"
//  Pesa low snapshot decomutation routines

#include "pads_dcm.h"
//  Eesa high pitch angle distribution decomutation routines

#include "tmp_dcm.h"
//  Temperature decomutation routines

#include "pckt_prt.h"
//  prototypes for printing routines

#include "map3d.h"
//  decomutation of esa 3d packets

#include "sst_dcm.h"
//  decomutation of sst packets

/******* Function prototypes for some printing routines ********************/


#endif /* WIND_LIB_H */
