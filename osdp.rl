/* -*- mode: c -*- */
/*
 * Copyright (c) 2011 Anton Yabchinskiy <arn@users.berlios.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "osdp.h"

#define OSDP_ADD_DIGIT(x_)                      \
    x_ = x_ * 10 + (*p - '0')

#define OSDP_CREATE(type_)                      \
    osdp_calloc(1, sizeof(type_))

#define OSDP_FREE_ARRAY(ptr_, n_)                \
    if (ptr_ != NULL) {                          \
        size_t i_;                               \
        for (i_ = 0; i_ < n_; ++i_) {            \
            osdp_free(ptr_[i_]);                 \
        }                                        \
        osdp_free(ptr_);                         \
        ptr_ = NULL;                             \
    }                                            \
    n_ = 0

#define OSDP_RESET_ARRAY(ptr_, n_, reset_func_)                         \
    if (ptr_ != NULL) {                                                 \
        size_t i_;                                                      \
        for (i_ = 0; i_ < n_; ++i_) {                                   \
            reset_func_(ptr_ + i_);                                     \
        }                                                               \
        osdp_free(ptr_);                                                \
        ptr_ = NULL;                                                    \
    }                                                                   \
    n_ = 0

%% machine osdp;
%% write data;

void (*osdp_free)(void*) = free;

void* (*osdp_calloc)(size_t, size_t) = calloc;

void* (*osdp_realloc)(void*, size_t) = realloc;

static char*
osdp_copy(const char* begin, const char* end)
{
    size_t size = (size_t)(end - begin);
    char* result;

    result = osdp_realloc(NULL, size + 1);
    if (result != NULL) {
        memcpy(result, begin, size);
        result[size] = '\0';
    }

    return result;
}

static void*
osdp_resize(void** ptr, size_t* n, size_t size)
{
    void* new_ptr;

    size *= (*n + 1);
    new_ptr = osdp_realloc(*ptr, size);
    if (new_ptr != NULL) {
        *ptr = new_ptr;
        *n += 1;
    }
    return new_ptr;
}

int
osdp_parse_session_descr(struct osdp_session_descr* sdp, const char* str, size_t sz)
{
    const char* p = str;
    const char* pe = p + sz;
    const char* eof = pe;
    int cs;

    const char* begin[4];
    const char* end[4];

    struct osdp_bandwidth* current_bandwidth = NULL;
    struct osdp_connection* current_connection = NULL;
    struct osdp_email* current_email = NULL;
    struct osdp_media_descr* current_media_descr = NULL;
    struct osdp_phone* current_phone = NULL;

    errno = 0;

    %%{
        crlf =
            "\r\n" | "\n";

        text =
            [^\0\r\n]+;

        token =
            [!#$%&´*+\-.0-9A-Z^_`a-z]+;




        decimal_octet =
            digit |
            ([1-9] digit) |
            ("1" digit{2}) |
            ("2" [01234] digit) |
            ("25" [012345]);

        hex_4 =
            xdigit{1,4};

        hex_seq =
            hex_4 (":" hex_4)*;

        hex_part =
            hex_seq | hex_seq "::" hex_seq? | "::" hex_seq?;

        ip4_address =
            decimal_octet ("." decimal_octet){3};

        ip6_address =
            hex_part (":" ip4_address)?;

        ttl =
            ([1-9] digit{,2}) | "0";

        n_addresses =
            "/" ([1-9] digit*) >{ current_connection->n_addresses = 0; }
                               @{ OSDP_ADD_DIGIT(current_connection->n_addresses); };

        ip4_multicast =
            ((("22" [456789]) | ("23" digit)) ("." decimal_octet){3})
              >{ begin[0] = fpc; }
              %{ current_connection->address = osdp_copy(begin[0], fpc); }
            "/" ttl >{ current_connection->ttl = 0; }
                    @{ OSDP_ADD_DIGIT(current_connection->ttl); }
                    n_addresses?;

        ip6_multicast =
            hex_part >{ begin[0] = fpc; }
                     %{ current_connection->address = osdp_copy(begin[0], fpc); }
            n_addresses?;

        fqdn =
            [\-.0-9A-Za-z]{4,};

        multicast_address =
            ip4_multicast | ip6_multicast | fqdn;

        unicast_address =
            ip4_address | ip6_address | fqdn;




        email_safe =
            [^\0\r\n()<>];

        # FIXME -- Parse email?
        email_address =
            graph+ "@" graph+;

        phone_number =
            "+"? digit [\- 0-9]+;

        email =
            (email_address >{ begin[0] = fpc; } %{ end[0] = fpc; } " "+ "(" email_safe+ >{ begin[1] = fpc; } %{ end[1] = fpc; } ")")
             %{ current_email->address = osdp_copy(begin[0], end[0]);
                current_email->name = osdp_copy(begin[1], end[1]); } |
            (email_safe+ >{ begin[1] = fpc; } %{ end[1] = fpc; } " "+ "<" email_address >{ begin[0] = fpc; } %{ end[0] = fpc; } ">")
             %{ current_email->address = osdp_copy(begin[0], end[0]);
                current_email->name = osdp_copy(begin[1], end[1]); } |
            email_address >{ begin[0] = fpc; } %{ current_email->address = osdp_copy(begin[0], fpc); };

        phone =
            (phone_number >{ begin[0] = fpc; } %{ end[0] = fpc; } " "+ "(" email_safe+ >{ begin[1] = fpc; } %{ end[1] = fpc; } ")")
            %{ current_phone->number = osdp_copy(begin[0], end[0]);
                current_phone->name = osdp_copy(begin[1], end[1]); } |
            (email_safe+ >{ begin[1] = fpc; } %{ end[1] = fpc; } " "+ "<" phone_number >{ begin[0] = fpc; } %{ end[0] = fpc; } ">")
             %{ current_phone->number = osdp_copy(begin[0], end[0]);
                current_phone->name = osdp_copy(begin[1], end[1]); } |
            phone_number >{ begin[0] = fpc; } %{ current_phone->number = osdp_copy(begin[0], fpc); };





        protocol_version_field =
            "v=" digit+ >{ sdp->protocol_version = 0; } @{ OSDP_ADD_DIGIT(sdp->protocol_version); } crlf;

        action create_origin {
            assert(sdp->origin == NULL);
            sdp->origin = OSDP_CREATE(struct osdp_origin);
            if (sdp->origin == NULL) {
                fbreak;
            }
        }

        origin_field =
            ("o=" %create_origin
             graph+ >{ begin[0] = fpc; } %{ end[0] = fpc; } " "
             digit+ >{ sdp->origin->session_id = 0; } @{ OSDP_ADD_DIGIT(sdp->origin->session_id); } " "
             digit+ >{ sdp->origin->session_version = 0; } @{ OSDP_ADD_DIGIT(sdp->origin->session_version); } " "
             token >{ begin[1] = fpc; } %{ end[1] = fpc; } " "
             token >{ begin[2] = fpc; } %{ end[2] = fpc; } " "
             unicast_address >{ begin[3] = fpc; } %{ end[3] = fpc; }
             crlf) %{ sdp->origin->username = osdp_copy(begin[0], end[0]);
                      sdp->origin->network_type = osdp_copy(begin[1], end[1]);
                      sdp->origin->address_type = osdp_copy(begin[2], end[2]);
                      sdp->origin->address = osdp_copy(begin[3], end[3]); };

        name_field =
            "s=" text >{ begin[0] = fpc; } %{ sdp->name = osdp_copy(begin[0], fpc); } crlf;

        information_field =
            "i=" text >{ begin[0] = fpc; }
                      %{ if (current_media_descr != NULL) {
                             current_media_descr->information = osdp_copy(begin[0], fpc);
                         } else {
                             sdp->information = osdp_copy(begin[0], fpc);
                         } } crlf;

        # TODO -- Do URI parsing?
        uri_field =
            "u=" text >{ begin[0] = fpc; } %{ sdp->uri = osdp_copy(begin[0], fpc); } crlf;

        action create_email {
            if (osdp_resize((void**)&sdp->emails, &sdp->n_emails, sizeof(struct osdp_email)) != NULL) {
                current_email = sdp->emails + (sdp->n_emails - 1);
                memset(current_email, 0, sizeof(struct osdp_email));
            } else {
                fbreak;
            }
        }

        email_field =
            "e=" %create_email email crlf;

        action create_phone {
            if (osdp_resize((void**)&sdp->phones, &sdp->n_phones, sizeof(struct osdp_phone)) != NULL) {
                current_phone = sdp->phones + (sdp->n_phones - 1);
                memset(current_phone, 0, sizeof(struct osdp_phone));
            } else {
                fbreak;
            }
        }

        phone_field =
            "p=" %create_phone phone crlf;

        action create_connection {
            current_connection = NULL;
            if (current_media_descr != NULL) {
                if (osdp_resize((void**)&current_media_descr->connections,
                                &current_media_descr->n_connections,
                                sizeof(struct osdp_connection)) != NULL)
                {
                    current_connection = current_media_descr->connections + (current_media_descr->n_connections - 1);
                    memset(current_media_descr, 0, sizeof(struct osdp_connection));
                }
            } else {
                assert(sdp->connection == NULL);
                sdp->connection = OSDP_CREATE(struct osdp_connection);
                current_connection = sdp->connection;
            }
            if (current_connection == NULL) {
                fbreak;
            }
        }

        connection_field =
            "c=" %create_connection
            token >{ begin[0] = fpc; } %{ current_connection->network_type = osdp_copy(begin[0], fpc); } " "
            token >{ begin[0] = fpc; } %{ current_connection->address_type = osdp_copy(begin[0], fpc); } " "
            (multicast_address | unicast_address >{ begin[0] = fpc; }
                                                 %{ current_connection->address = osdp_copy(begin[0], fpc); }) crlf;

        action create_bandwidth {
            current_bandwidth = NULL;
            if (current_media_descr != NULL) {
                if (osdp_resize((void**)&current_media_descr->bandwidths,
                                &current_media_descr->n_bandwidths,
                                sizeof(struct osdp_bandwidth)) != NULL)
                {
                    current_bandwidth = current_media_descr->bandwidths + (current_media_descr->n_bandwidths - 1);
                }
            } else {
                if (osdp_resize((void**)&sdp->bandwidths,
                                &sdp->n_bandwidths,
                                sizeof(struct osdp_bandwidth)) != NULL)
                {
                    current_bandwidth = sdp->bandwidths + (sdp->n_bandwidths - 1);
                }
            }
            if (current_bandwidth != NULL) {
                memset(current_bandwidth, 0, sizeof(struct osdp_bandwidth));
            } else {
                fbreak;
            }
        }

        bandwidth_field =
            "b=" %create_bandwidth
            token >{ begin[0] = fpc; }
                  %{ current_bandwidth->type = osdp_copy(begin[0], fpc); } ":"
            digit+ >{ current_bandwidth->value = 0; }
                   @{ OSDP_ADD_DIGIT(current_bandwidth->value); }
            crlf;

        session_descr =
            protocol_version_field
            origin_field
            name_field
            information_field?
            uri_field?
            email_field*
            phone_field*
            connection_field?
            bandwidth_field*;

        main :=
            session_descr;
    }%%

    %% write init;
    %% write exec;

    /* System error, return -errno. */
    if (errno != 0) {
        return -errno;
    }

    /* Parser error, return position. */
    if (cs < osdp_first_final) {
        return (p - str) + 1;
    }

    return 0;
}

void
osdp_reset_attribute(struct osdp_attribute* attribute)
{
    if (attribute == NULL) {
        return;
    }

    osdp_free(attribute->name);
    attribute->name = NULL;

    osdp_free(attribute->value);
    attribute->value = NULL;
}

void
osdp_reset_bandwidth(struct osdp_bandwidth* bandwidth)
{
    if (bandwidth == NULL) {
        return;
    }

    osdp_free(bandwidth->type);
    bandwidth->type = NULL;

    bandwidth->value = -1;
}

void
osdp_reset_connection(struct osdp_connection* connection)
{
    if (connection == NULL) {
        return;
    }

    osdp_free(connection->network_type);
    connection->network_type = NULL;

    osdp_free(connection->address_type);
    connection->address_type = NULL;

    osdp_free(connection->address);
    connection->address = NULL;

    connection->ttl = -1;

    connection->n_addresses = -1;
}

void
osdp_reset_email(struct osdp_email* email)
{
    if (email == NULL) {
        return;
    }

    osdp_free(email->address);
    email->address = NULL;

    osdp_free(email->name);
    email->name = NULL;
}

void
osdp_reset_key(struct osdp_key* key)
{
    if (key == NULL) {
        return;
    }

    osdp_free(key->method);
    key->method = NULL;

    osdp_free(key->value);
    key->value = NULL;
}

void
osdp_reset_media(struct osdp_media* media)
{
    if (media == NULL) {
        return;
    }

    osdp_free(media->type);
    media->type = NULL;

    media->port = -1;

    media->n_ports = -1;

    osdp_free(media->protocol);
    media->protocol = NULL;

    OSDP_FREE_ARRAY(media->formats, media->n_formats);
}

void
osdp_reset_media_descr(struct osdp_media_descr* media_descr)
{
    if (media_descr == NULL) {
        return;
    }

    osdp_reset_media(media_descr->media);
    osdp_free(media_descr->media);
    media_descr->media = NULL;

    osdp_free(media_descr->information);
    media_descr->information = NULL;

    OSDP_RESET_ARRAY(media_descr->connections,
                     media_descr->n_connections,
                     osdp_reset_connection);

    OSDP_RESET_ARRAY(media_descr->bandwidths,
                     media_descr->n_bandwidths,
                     osdp_reset_bandwidth);

    osdp_reset_key(media_descr->key);
    osdp_free(media_descr->key);
    media_descr->key = NULL;

    OSDP_RESET_ARRAY(media_descr->attributes,
                     media_descr->n_attributes,
                     osdp_reset_attribute);
}

void
osdp_reset_origin(struct osdp_origin* origin)
{
    if (origin == NULL) {
        return;
    }

    osdp_free(origin->username);
    origin->username = NULL;

    origin->session_id = 0ULL;

    origin->session_version = 0ULL;

    osdp_free(origin->network_type);
    origin->network_type = NULL;

    osdp_free(origin->address_type);
    origin->address_type = NULL;

    osdp_free(origin->address);
    origin->address = NULL;
}

void
osdp_reset_phone(struct osdp_phone* phone)
{
    if (phone == NULL) {
        return;
    }

    osdp_free(phone->number);
    phone->number = NULL;

    osdp_free(phone->name);
    phone->name = NULL;
}

void
osdp_reset_repeat_time(struct osdp_repeat_time* repeat_time)
{
    if (repeat_time == NULL) {
        return;
    }

    repeat_time->interval = 0ULL;

    repeat_time->duration = 0ULL;

    osdp_free(repeat_time->offsets);
    repeat_time->offsets = NULL;
    repeat_time->n_offsets = 0;
}

void
osdp_reset_session_descr(struct osdp_session_descr* session_descr)
{
    if (session_descr == NULL) {
        return;
    }

    session_descr->protocol_version = -1;

    osdp_reset_origin(session_descr->origin);
    osdp_free(session_descr->origin);
    session_descr->origin = NULL;

    osdp_free(session_descr->name);
    session_descr->name = NULL;

    osdp_free(session_descr->information);
    session_descr->information = NULL;

    osdp_free(session_descr->uri);
    session_descr->uri = NULL;

    OSDP_RESET_ARRAY(session_descr->emails,
                     session_descr->n_emails,
                     osdp_reset_email);

    OSDP_RESET_ARRAY(session_descr->phones,
                     session_descr->n_phones,
                     osdp_reset_phone);

    osdp_reset_connection(session_descr->connection);
    osdp_free(session_descr->connection);
    session_descr->connection = NULL;

    OSDP_RESET_ARRAY(session_descr->bandwidths,
                     session_descr->n_bandwidths,
                     osdp_reset_bandwidth);

    OSDP_RESET_ARRAY(session_descr->times,
                     session_descr->n_times,
                     osdp_reset_time);

    osdp_free(session_descr->time_zones);
    session_descr->time_zones = NULL;
    session_descr->n_time_zones = 0;

    osdp_reset_key(session_descr->key);
    osdp_free(session_descr->key);
    session_descr->key = NULL;

    OSDP_RESET_ARRAY(session_descr->attributes,
                     session_descr->n_attributes,
                     osdp_reset_attribute);

    OSDP_RESET_ARRAY(session_descr->media_descrs,
                     session_descr->n_media_descrs,
                     osdp_reset_media_descr);
}

void
osdp_reset_time(struct osdp_time* time)
{
    if (time == NULL) {
        return;
    }

    time->start = 0ULL;

    time->stop = 0ULL;

    OSDP_RESET_ARRAY(time->repeats,
                     time->n_repeats,
                     osdp_reset_repeat_time);
}

void
osdp_reset_time_zone(struct osdp_time_zone* time_zone)
{
    if (time_zone == NULL) {
        return;
    }

    time_zone->adjustment_time = 0ULL;

    time_zone->offset = 0;
}
