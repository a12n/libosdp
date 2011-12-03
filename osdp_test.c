
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

#include <osdp.h>

static void
print_session_descr(const struct osdp_session_descr* sdp)
{
    size_t i, j, k;

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
    if (sdp->connection != NULL) {
        printf("connection.network_type: \"%s\"\n"
               "connection.address_type: \"%s\"\n"
               "connection.address: \"%s\"\n"
               "connection.ttl: %d\n"
               "connection.n_addresses: %d\n",
               sdp->connection->network_type,
               sdp->connection->address_type,
               sdp->connection->address,
               sdp->connection->ttl,
               sdp->connection->n_addresses);
    }
    for (i = 0; i < sdp->bandwidths_size; ++i) {
        printf("bandwidths[%d].type: \"%s\"\n"
               "bandwidths[%d].value: %d\n",
               i, sdp->bandwidths[i].type,
               i, sdp->bandwidths[i].value);
    }
    for (i = 0; i < sdp->times_size; ++i) {
        printf("times[%d].start: %llu\n"
               "times[%d].stop: %llu\n",
               i, sdp->times[i].start,
               i, sdp->times[i].stop);
        for (j = 0; j < sdp->times[i].repeats_size; ++j) {
            printf("times[%d].repeats[%d].interval: %llu"
                   "times[%d].repeats[%d].duration: %llu",
                   i, j, sdp->times[i].repeats[j].interval,
                   i, j, sdp->times[i].repeats[j].duration);
            for (k = 0; k < sdp->times[i].repeats[j].offsets_size; ++k) {
                printf("times[%d].repeats[%d].offsets[%d]: %llu\n",
                       i, j, k, sdp->times[i].repeats[j].offsets[k]);
            }
        }
    }
    if (sdp->time_zones != NULL) {
        for (i = 0; i < sdp->time_zones->size; ++i) {
            printf("time_zones.adjustment_times[%d]: %llu\n"
                   "time_zones.offsets[%d]: %llu\n",
                   i, sdp->time_zones->adjustment_times[i],
                   i, sdp->time_zones->offsets[i]);
        }
    }
    if (sdp->key != NULL) {
        printf("key.method: \"%s\"\n"
               "key.value: \"%s\"\n",
               sdp->key->method,
               sdp->key->value);
    }
    for (i = 0; i < sdp->attributes_size; ++i) {
        printf("attributes[%d].name: \"%s\"\n"
               "attributes[%d].value: \"%s\"\n",
               i, sdp->attributes[i].name,
               i, sdp->attributes[i].value);
    }
    /* TODO: Print media descrs. */
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
    error = osdp_parse_session_descr(&sdp, str, size);
    if (error < 0) {
        warnx(strerror(-error));
        ret = 1;
    } else if (error > 0) {
        warnx("Syntax error near position %d", error);
        ret = 1;
    } else {
        print_session_descr(&sdp);
    }
    osdp_reset_session_descr(&sdp);

    return ret;
}
