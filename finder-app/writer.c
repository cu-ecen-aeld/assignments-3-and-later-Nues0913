#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        syslog(LOG_ERR, "Usage: %s fileName string", argv[0]);
        return 1;
    }

    const char *fileName = argv[1];
    const char *content = argv[2];
    FILE *file = fopen(fileName, "w");
    if (!file) {
        syslog(LOG_ERR, "Failed to open file: %s", fileName);
        return 1;
    }
    fprintf(file, "%s", content);
    fclose(file);

    syslog(LOG_DEBUG, "Writing %s to %s", content, fileName);
    return 0;
}
