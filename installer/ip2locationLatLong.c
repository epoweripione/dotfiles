#include "IP2Location.h"


int main(int argc,char**argv)
{
    if (argc!=3)
    {
        fprintf(stderr,"%s BinFile IP\n",argv[0]);
        return 0;
    }
    char *szBinFile=argv[1];
    char *szIp=argv[2];

    IP2Location *IP2LocationObj = IP2Location_open(szBinFile);
    if (IP2LocationObj==NULL)
    {
        fprintf(stderr,"Obj is NULL\n");
        return 0;
    }

    IP2LocationRecord *record = IP2Location_get_all(IP2LocationObj, szIp);
    if(record==NULL)
    {
        fprintf(stderr,"Record is NULL\n");
    }
    printf("%f,%f\n",
        record->latitude,
        record->longitude);
    IP2Location_free_record(record);
    IP2Location_close(IP2LocationObj);
    return 0;
}