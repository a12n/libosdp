
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
    printf("n_emails: %u\n", sdp->n_emails);
    for (i = 0; i < sdp->n_emails; ++i) {
        printf("emails[%d].address: \"%s\"\n"
               "emails[%d].name: \"%s\"\n",
               i, sdp->emails[i].address,
               i, sdp->emails[i].name);
    }
    printf("n_phones: %u\n", sdp->n_phones);
    for (i = 0; i < sdp->n_phones; ++i) {
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
    printf("n_bandwidths: %u\n", sdp->n_bandwidths);
    for (i = 0; i < sdp->n_bandwidths; ++i) {
        printf("bandwidths[%d].type: \"%s\"\n"
               "bandwidths[%d].value: %d\n",
               i, sdp->bandwidths[i].type,
               i, sdp->bandwidths[i].value);
    }
    printf("n_times: %u\n", sdp->n_times);
    for (i = 0; i < sdp->n_times; ++i) {
        printf("times[%d].start: %llu\n"
               "times[%d].stop: %llu\n",
               i, sdp->times[i].start,
               i, sdp->times[i].stop);
        for (j = 0; j < sdp->times[i].n_repeats; ++j) {
            printf("times[%d].repeats[%d].interval: %llu"
                   "times[%d].repeats[%d].duration: %llu",
                   i, j, sdp->times[i].repeats[j].interval,
                   i, j, sdp->times[i].repeats[j].duration);
            for (k = 0; k < sdp->times[i].repeats[j].n_offsets; ++k) {
                printf("times[%d].repeats[%d].offsets[%d]: %d\n",
                       i, j, k, sdp->times[i].repeats[j].offsets[k]);
            }
        }
    }
    printf("n_time_zones: %u\n", sdp->n_time_zones);
    for (i = 0; i < sdp->n_time_zones; ++i) {
        printf("time_zones[%d].adjustment_time: %llu\n"
               "time_zones[%d].offset: %d\n",
               i, sdp->time_zones[i].adjustment_time,
               i, sdp->time_zones[i].offset);
    }
    if (sdp->key != NULL) {
        printf("key.method: \"%s\"\n"
               "key.value: \"%s\"\n",
               sdp->key->method,
               sdp->key->value);
    }
    printf("n_attributes: %u\n", sdp->n_attributes);
    for (i = 0; i < sdp->n_attributes; ++i) {
        printf("attributes[%d].name: \"%s\"\n"
               "attributes[%d].value: \"%s\"\n",
               i, sdp->attributes[i].name,
               i, sdp->attributes[i].value);
    }
    printf("n_media_descrs: %u\n", sdp->n_media_descrs);
    for (i = 0; i < sdp->n_media_descrs; ++i) {
        printf("media_descrs[%d].media.type: \"%s\"\n"
               "media_descrs[%d].media.port: %d\n"
               "media_descrs[%d].media.n_ports: %d\n"
               "media_descrs[%d].media.protocol: \"%s\"\n",
               i, sdp->media_descrs[i].media->type,
               i, sdp->media_descrs[i].media->port,
               i, sdp->media_descrs[i].media->n_ports,
               i, sdp->media_descrs[i].media->protocol);
        printf("media_descrs[%d].media.n_formats: %u\n",
               i, sdp->media_descrs[i].media->n_formats);
        for (j = 0; j < sdp->media_descrs[i].media->n_formats; ++j) {
            printf("media_descrs[%d].media.formats[%d]: \"%s\"\n",
                   i, j, sdp->media_descrs[i].media->formats[j]);
        }
        printf("media_descrs[%d].information: \"%s\"\n",
               i, sdp->media_descrs[i].information);
        printf("media_descrs[%d].n_connections: %u\n",
               i, sdp->media_descrs[i].n_connections);
        for (j = 0; j < sdp->media_descrs[i].n_connections; ++j) {
            /* FIXME: Duplicates connection printing. */
            printf("media_descrs[%d].connections[%d].network_type: \"%s\"\n"
                   "media_descrs[%d].connections[%d].address_type: \"%s\"\n"
                   "media_descrs[%d].connections[%d].address: \"%s\"\n"
                   "media_descrs[%d].connections[%d].ttl: %d\n"
                   "media_descrs[%d].connections[%d].n_addresses: %d\n",
                   i, j, sdp->media_descrs[i].connections[j].network_type,
                   i, j, sdp->media_descrs[i].connections[j].address_type,
                   i, j, sdp->media_descrs[i].connections[j].address,
                   i, j, sdp->media_descrs[i].connections[j].ttl,
                   i, j, sdp->media_descrs[i].connections[j].n_addresses);
        }
        printf("media_descrs[%d].n_bandwidths: %u\n",
               i, sdp->media_descrs[i].n_bandwidths);
        for (j = 0; j < sdp->media_descrs[i].n_bandwidths; ++j) {
            /* FIXME: Duplicates bandwidths printing. */
            printf("media_descrs[%d].bandwidths[%d].type: \"%s\"\n"
                   "media_descrs[%d].bandwidths[%d].value: %d\n",
                   i, j, sdp->media_descrs[i].bandwidths[j].type,
                   i, j, sdp->media_descrs[i].bandwidths[j].value);
        }
        if (sdp->media_descrs[i].key != NULL) {
            /* FIXME: Duplicates key printing. */
            printf("media_descrs[%d].key.method: \"%s\"\n"
                   "media_descrs[%d].key.value: \"%s\"\n",
                   i, sdp->media_descrs[i].key->method,
                   i, sdp->media_descrs[i].key->value);
        }
        printf("media_descrs[%d].n_attributes: %u\n",
               i, sdp->media_descrs[i].n_attributes);
        for (j = 0; j < sdp->media_descrs[i].n_attributes; ++j) {
            /* FIXME: Duplicates attributes printing. */
            printf("media_descrs[%d].attributes[%d].name: \"%s\"\n"
                   "media_descrs[%d].attributes[%d].value: \"%s\"\n",
                   i, j, sdp->media_descrs[i].attributes[j].name,
                   i, j, sdp->media_descrs[i].attributes[j].value);
        }
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
