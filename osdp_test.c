
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

#include <osdp.h>

static void
print_session_descr(const struct osdp_session_descr* sdp)
{
    printf("Protocol Version: %d\n", sdp->protocol_version);
    if (sdp->origin != NULL) {
        printf("Origin.Username: \"%s\"\n"
               "Origin.Session Id: %llu\n"
               "Origin.Session Version: %llu\n"
               "Origin.Network Type: \"%s\"\n"
               "Origin.Address Type: \"%s\"\n"
               "Origin.Address: \"%s\"",
               sdp->origin->username,
               sdp->origin->session_id,
               sdp->origin->session_version,
               sdp->origin->network_type,
               sdp->origin->address_type,
               sdp->origin->address);
    }
    printf("Session Name: \"%s\"\n"
           "Session Information: \"%s\"\n"
           "URI: \"%s\"\n",
           sdp->name,
           sdp->information,
           sdp->uri);
}

int
main(void)
{
    int ret = 0;

    char str[4096];
    size_t size;

    struct osdp_session_descr sdp = OSDP_SESSION_DESCR_INIT;
    int error;

    size = fread(str, 1, sizeof(str), stdin);
    error = osdp_parse(&sdp, str, size);
    if (error < 0) {
        warnx(strerror(-error));
        ret = 1;
    } else if (error > 0) {
        warnx("Syntax error near position %d", error);
        ret = 1;
    } else {
        print_session_descr(&sdp);
    }
    osdp_reset(&sdp);

    return ret;
}
