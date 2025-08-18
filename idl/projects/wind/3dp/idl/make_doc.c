#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TRUE 1
#define FALSE 0


main(int argc, char *argv[])
{
int i;
int printing;
FILE *fp;
char s[1000];
char *p;

for (i=1; i<argc; i++){

	fp = fopen(argv[i], "r");
	if(fp==0)
		continue;

	printf("++++++++++  %s  ++++++++++\n", argv[i]);
	printing = FALSE;

	while(p = fgets(s, 1000, fp)){
		
		if(s[0] == ';'){
			
			if(s[1] == '+') {
				printing = TRUE;
				printf("\n");
				}
			
			else if(s[1] == '-') {
				printing = FALSE;
				printf("-------------------------------\n\n");
				}
			
			else if(printing) fputs(s+1,stdout);

			}
		}
	printf("\n");

	fclose(fp);

	}

	return(0);
}
