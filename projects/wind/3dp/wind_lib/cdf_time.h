#ifndef GetWindKPTimeSpan_H
#define GetWindKPTimeSpan_H

/*==============================================================================
|------------------------------------------------------------------------------|
|									       |
|				 GetWindKPTimeSpan.H			       |
|									       |
|------------------------------------------------------------------------------|
|									       |
| CONTENTS								       |
| --------								       |
| This header file contains the GetWindKPTimeSpan() definition.		       |
|									       |
| AUTHOR								       |							       | ------								       |
| Todd H. Kermit, Space Sciences Laboratory, U.C. Berkeley		       |
|									       |	------------------------------------------------------------------------------*/

int GetWindKPTimeSpan(char *path,			/* path and file name  */
		      int *SYear,			/* start date/time  */
		      int *SMonth, 
		      int *SDay,
		      int *SHour, 
		      int *SMinute, 
		      int *SSeconds, 
		      int *SMsec,
		      int *EYear,			/* end date/time */
		      int *EMonth, 
		      int *EDay, 
		      int *EHour, 
		      int *EMinute,
		      int *ESeconds,
		      int *EMsec,
		      int *nrecords
		      );

#endif /* GetWindKPTimeSpan_H  */
