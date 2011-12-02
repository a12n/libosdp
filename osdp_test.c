
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

#include <osdp.h>

static void
print_session_descr(const struct osdp_session_descr* sdp)
{
    size_t i;

    printf("protocol_version: %d\n", sdp->protocol_version);
    if (sdp->origin != NULL) {
        printf("origin.username: \"%s\"\n"
               "origin.session_id: %llu\n"
               "origin.session_version: %llu\n"
               "origin.network_type: \"%s\"\n"
               "origin.address_type: \"%s\"\n"
               "origin.address: \"%s\"\n",
               sdp->origin->username,
               sdp->origin->session_id,
               sdp->origin->session_version,
               sdp->origin->network_type,
               sdp->origin->address_type,
               sdp->origin->address);
    }
    printf("session_name: \"%s\"\n"
           "session_information: \"%s\"\n"
           "uri: \"%s\"\n",
           sdp->name,
           sdp->information,
           sdp->uri);
    for (i = 0; i < sdp->emails_size; ++i) {
        printf("emails[%d].address: \"%s\"\n"
               "emails[%d].name: \"%s\"\n",
               i, sdp->emails[i].address,
               i, sdp->emails[i].name);
    }
    for (i = 0; i < sdp->phones_size; ++i) {
        printf("phones[%d].number: \"%s\"\n"
               "phones[%d].name: \"%s\"\n",
               i, sdp->phones[i].number,
               i, sdp->phones[i].name);
    }
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
