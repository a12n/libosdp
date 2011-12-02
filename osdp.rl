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

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include "osdp.h"

%% machine osdp;
%% write data;

void (*osdp_free)(void*) = free;

void* (*osdp_realloc)(void*, size_t) = realloc;

int
osdp_format_session_descr(const struct osdp_session_descr* sdp, char** str_ptr, size_t* sz_ptr)
{
    (void)sdp;
    (void)str_ptr;
    (void)sz_ptr;

    /* TODO */

    return -1;
}

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

int
osdp_parse_session_descr(struct osdp_session_descr* sdp, const char* str, size_t sz)
{
    const char* p = str;
    const char* pe = p + sz;
    const char* eof = pe;
    int cs;

    const char* begin_1 = NULL;
    const char* begin_2 = NULL;
    const char* end_1 = NULL;
    const char* end_2 = NULL;
    int ok = 0;

    struct osdp_bandwidth* bandwidths_back;
    struct osdp_email* emails_back;
    struct osdp_phone* phones_back;

    errno = 0;

    /* Current char as a digit */
#define fcd (*p - '0')

    %%{
        action save_begin_1 { begin_1 = fpc; }
        action save_begin_2 { begin_2 = fpc; }
        action save_end_1 { end_1 = fpc; }
        action save_end_2 { end_2 = fpc; }

        crlf =
            "\n" | "\r\n";

        text =
            [^\0\r\n]+;

        sess_id =
            digit+;

        sess_version =
            digit+;

        token =
            [!#$%&´*+\-.0-9A-Z^_`a-z]+;

        nettype =
            token;

        addrtype =
            token;

        bwtype =
            token;

        # FIXME
        addr_spec =
            (alnum | [@.])+;

        phone =
            "+"? digit [ \-0-9]+;

        email_safe =
            [^\0\r\n()<>];

        phone_number =
            (phone >save_begin_1 %save_end_1 " "+ "(" email_safe+ >save_begin_2 %save_end_2 ")")
             %{ phones_back->number = osdp_copy(begin_1, end_1);
                phones_back->name = osdp_copy(begin_2, end_2); } |
            (email_safe+ >save_begin_2 %save_end_2 " "+ "<" phone >save_begin_1 %save_end_1 ">")
             %{ phones_back->number = osdp_copy(begin_1, end_1);
                phones_back->name = osdp_copy(begin_2, end_2); } |
            phone >save_begin_1 %{ phones_back->number = osdp_copy(begin_1, fpc); };

        email_address =
            (addr_spec >save_begin_1 %save_end_1 " "+ "(" email_safe+ >save_begin_2 %save_end_2 ")")
             %{ emails_back->address = osdp_copy(begin_1, end_1);
                emails_back->name = osdp_copy(begin_2, end_2); } |
            (email_safe+ >save_begin_2 %save_end_2 " "+ "<" addr_spec >save_begin_1 %save_end_1 ">")
             %{ emails_back->address = osdp_copy(begin_1, end_1);
                emails_back->name = osdp_copy(begin_2, end_2); } |
            addr_spec >save_begin_1 %{ emails_back->address = osdp_copy(begin_1, fpc); };


        # FIXME
        uri =
            (alnum | [:/.])+;


        non_ws_string =
            print+;

        username =
            non_ws_string;

        extn_addr =
            non_ws_string;

        fqdn =
            (alnum | [\-.]){4,};

        integer =
            [1-9] digit*;

        decimal_uchar =
            digit | ([1-9] digit) | ("1" digit{2}) | ("2" [01234] digit) | ("25" [012345]);

        b1 =
            decimal_uchar;

        ip4_address =
            b1 ("." decimal_uchar){3};

        ttl =
            ([1-9] digit{,2}) | "0";

        m1 =
            ("22" [456789]) | ("23" digit);

        ip4_multicast =
            m1 ("." decimal_uchar){3} "/" ttl ("/" integer)?;

        hex4 =
            xdigit{1,4};

        hexseq =
            hex4 (":" hex4)*;

        hexpart =
            hexseq | (hexseq "::" hexseq?) | ("::" hexseq?);

        ip6_multicast =
            hexpart ("/" integer)?;

        ip6_address =
            hexpart (":" ip4_address)?;

        multicast_address =
            ip4_multicast | ip6_multicast | fqdn | extn_addr;

        unicast_address =
            ip4_address | ip6_address | fqdn | extn_addr;

        connection_address =
            multicast_address | unicast_address;


        time =
            [1-9] digit{9,};

        start_time =
            time | "0";

        stop_time =
            time | "0";

        fixed_len_time_unit =
            "d" | "h" | "m" | "s";

        typed_time =
            digit+ fixed_len_time_unit;

        repeat_interval =
            [1-9] digit* fixed_len_time_unit;

        zone_adjustements =
            "z=" time " " "-"? typed_time (" " time " " "-"? typed_time)*;

        repeat_fields =
            "r=" repeat_interval " " typed_time (" " typed_time)+;

        time_fields =
            ("t=" start_time " " stop_time (crlf repeat_fields)* crlf)+
            ("z=" zone_adjustements crlf)?;

        action new_bandwidth {
            size_t new_sz = sdp->bandwidths_size + 1;
            void* new_ptr;

            new_ptr = osdp_realloc(sdp->bandwidths, new_sz * sizeof(struct osdp_bandwidth));
            if (new_ptr != NULL) {
                sdp->bandwidths = new_ptr;
                sdp->bandwidths_size = new_sz;
                bandwidths_back = sdp->bandwidths + (sdp->bandwidths_size - 1);
            } else {
                fbreak;
            }
        }

        bandwidth_fields =
            ("b=" %new_bandwidth bwtype >save_begin_1 %{ bandwidths_back->type = osdp_copy(begin_1, fpc); } ":"
             digit+ >{ bandwidths_back->value = 0; } @{ bandwidths_back->value = bandwidths_back->value * 10 + fcd; } crlf)*;

        action new_connection {
            sdp->connection = osdp_realloc(NULL, sizeof(struct osdp_connection));
            if (sdp->connection == NULL) {
                fbreak;
            }
        }

        connection_field =
            ("c=" %new_connection
             nettype >save_begin_1 %{ sdp->connection->network_type = osdp_copy(begin_1, fpc); } " "
             addrtype >save_begin_1 %{ sdp->connection->address_type = osdp_copy(begin_1, fpc); } " "
             connection_address >save_begin_1 %{ sdp->connection->address = osdp_copy(begin_1, fpc); } crlf)?;

        action new_phone {
            size_t new_sz = sdp->phones_size + 1;
            void* new_ptr;

            new_ptr = osdp_realloc(sdp->phones, new_sz * sizeof(struct osdp_phone));
            if (new_ptr != NULL) {
                sdp->phones = new_ptr;
                sdp->phones_size = new_sz;
                phones_back = sdp->phones + (sdp->phones_size - 1);
            } else {
                fbreak;
            }
        }

        phone_fields =
            ("p=" %new_phone phone_number crlf)*;

        action new_email {
            size_t new_sz = sdp->emails_size + 1;
            void* new_ptr;

            new_ptr = osdp_realloc(sdp->emails, new_sz * sizeof(struct osdp_email));
            if (new_ptr != NULL) {
                sdp->emails = new_ptr;
                sdp->emails_size = new_sz;
                emails_back = sdp->emails + (sdp->emails_size - 1);
            } else {
                fbreak;
            }
        }

        email_fields =
            ("e=" %new_email email_address crlf)*;

        uri_field =
            ("u=" uri >save_begin_1 %{ sdp->uri = osdp_copy(begin_1, fpc); } crlf)?;

        information_field =
            ("i=" text >save_begin_1 %{ sdp->information = osdp_copy(begin_1, fpc); } crlf)?;

        session_name_field =
            "s=" text >save_begin_1 %{ sdp->name = osdp_copy(begin_1, fpc); } crlf;

        action new_origin {
            sdp->origin = osdp_realloc(NULL, sizeof(struct osdp_origin));
            if (sdp->origin == NULL) {
                fbreak;
            }
        }

        origin_field =
            "o=" %new_origin
            username >save_begin_1 %{ sdp->origin->username = osdp_copy(begin_1, fpc); } " "
            sess_id >{ sdp->origin->session_id = 0; } @{ sdp->origin->session_id = sdp->origin->session_id * 10 + (uint64_t)fcd; } " "
            sess_version >{ sdp->origin->session_version = 0; } @{ sdp->origin->session_version = sdp->origin->session_version * 10 + (uint64_t)fcd; } " "
            nettype >save_begin_1 %{ sdp->origin->network_type = osdp_copy(begin_1, fpc); } " "
            addrtype >save_begin_1 %{ sdp->origin->address_type = osdp_copy(begin_1, fpc); } " "
            unicast_address >save_begin_1 %{ sdp->origin->address = osdp_copy(begin_1, fpc); } crlf;

        proto_version =
            "v=" digit+ >{ sdp->protocol_version = 0; } @{ sdp->protocol_version = sdp->protocol_version * 10 + fcd; } crlf;

        session_description =
            proto_version
            origin_field
            session_name_field
            information_field
            uri_field
            email_fields
            phone_fields
            connection_field
            bandwidth_fields
            time_fields
            ;

        main :=
            session_description %{ ok = 1; };
    }%%

    %% write init;
    %% write exec;

#undef fcd

    /* System error, return -errno. */
    if (errno != 0) {
        return -errno;
    }

    /* Parser error, return position. */
    if (!ok) {
        return (p - str) + 1;
    }

    return 0;
}

static void
osdp_reset_origin(struct osdp_origin* origin)
{
    if (origin != NULL) {
        osdp_free(origin->username);
        osdp_free(origin->network_type);
        osdp_free(origin->address_type);
        osdp_free(origin->address);
        osdp_free(origin);
    }
}

static void
osdp_reset_connection(struct osdp_connection* connection)
{
    if (connection != NULL) {
        osdp_free(connection->network_type);
        osdp_free(connection->address_type);
        osdp_free(connection->address);
        osdp_free(connection);
    }
}

static void
osdp_reset_bandwidths(struct osdp_bandwidth* bandwidths, size_t size)
{
    size_t i;

    for (i = 0; i < size; ++i) {
        osdp_free(bandwidths[i].type);
    }
    osdp_free(bandwidths);
}

static void
osdp_reset_key(struct osdp_key* key)
{
    if (key != NULL) {
        osdp_free(key->method);
        osdp_free(key->value);
        osdp_free(key);
    }
}

static void
osdp_reset_attributes(struct osdp_attribute* attributes, size_t size)
{
    size_t i;

    for (i = 0; i < size; ++i) {
        osdp_free(attributes[i].name);
        osdp_free(attributes[i].value);
    }
    osdp_free(attributes);
}

static void
osdp_reset_media(struct osdp_media* media)
{
    if (media != NULL) {
        size_t i;

        osdp_free(media->type);
        osdp_free(media->protocol);
        for (i = 0; i < media->formats_size; ++i) {
            osdp_free(media->formats[i]);
        }
        osdp_free(media->formats);
        osdp_free(media);
    }
}

static void
osdp_reset_media_descrs(struct osdp_media_descr* media_descrs, size_t size)
{
    size_t i;

    for (i = 0; i < size; ++i) {
        osdp_reset_media(media_descrs[i].media);
        osdp_free(media_descrs[i].information);
        osdp_reset_connection(media_descrs[i].connection);
        osdp_reset_bandwidths(media_descrs[i].bandwidths, media_descrs[i].bandwidths_size);
        osdp_reset_key(media_descrs[i].key);
        osdp_reset_attributes(media_descrs[i].attributes, media_descrs[i].attributes_size);
    }
    osdp_free(media_descrs);
}

void
osdp_reset_session_descr(struct osdp_session_descr* sdp)
{
    size_t i, j;

    sdp->protocol_version = -1;

    osdp_reset_origin(sdp->origin);
    sdp->origin = NULL;

    osdp_free(sdp->name);
    sdp->name = NULL;

    osdp_free(sdp->information);
    sdp->information = NULL;

    osdp_free(sdp->uri);
    sdp->uri = NULL;

    for (i = 0; i < sdp->emails_size; ++i) {
        osdp_free(sdp->emails[i].address);
        osdp_free(sdp->emails[i].name);
    }
    osdp_free(sdp->emails);
    sdp->emails = NULL;
    sdp->emails_size = 0;

    for (i = 0; i < sdp->phones_size; ++i) {
        osdp_free(sdp->phones[i].number);
        osdp_free(sdp->phones[i].name);
    }
    osdp_free(sdp->phones);
    sdp->phones = NULL;
    sdp->phones_size = 0;

    osdp_reset_connection(sdp->connection);
    sdp->connection = NULL;

    osdp_reset_bandwidths(sdp->bandwidths, sdp->bandwidths_size);
    sdp->bandwidths = NULL;
    sdp->bandwidths_size = 0;

    for (i = 0; i < sdp->times_size; ++i) {
        for (j = 0; j < sdp->times[i].repeats_size; ++j) {
            osdp_free(sdp->times[i].repeats[j].offsets);
        }
        osdp_free(sdp->times[i].repeats);
    }
    osdp_free(sdp->times);
    sdp->times = NULL;
    sdp->times_size = 0;

    if (sdp->time_zones != NULL) {
        osdp_free(sdp->time_zones->adjustment_times);
        osdp_free(sdp->time_zones->offsets);
        osdp_free(sdp->time_zones);
        sdp->time_zones = NULL;
    }

    osdp_reset_key(sdp->key);
    sdp->key = NULL;

    osdp_reset_attributes(sdp->attributes, sdp->attributes_size);
    sdp->attributes = NULL;
    sdp->attributes_size = 0;

    osdp_reset_media_descrs(sdp->media_descrs, sdp->media_descrs_size);
    sdp->media_descrs = NULL;
    sdp->media_descrs_size = 0;
}
