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
osdp_format(const struct osdp_session_descr* sdp, char** str_ptr, size_t* sz_ptr)
{
    (void)sdp;
    (void)str_ptr;
    (void)sz_ptr;

    /* TODO */

    return -1;
}

int
osdp_parse(struct osdp_session_descr* sdp, const char* str, size_t sz)
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

    struct osdp_email* emails_back;
    struct osdp_phone* phones_back;

    /* Current char as a digit */
#define fcd (*p - '0')

    %%{
        action save_begin_1 { begin_1 = fpc; }
        action save_begin_2 { begin_2 = fpc; }
        action save_end_1 { end_1 = fpc; }
        action save_end_2 { end_2 = fpc; }

        crlf =
            ("\n" | "\r\n");

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

        # FIXME
        username =
            alnum+;

        # FIXME
        unicast_address =
            (alnum | ".")+;



        phone_fields =
            ("p=" phone_number >{
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
            } crlf)*;

        email_fields =
            ("e=" email_address >{
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
            } crlf)*;

        uri_field =
            ("u=" uri >save_begin_1 %{ sdp->uri = osdp_copy(begin_1, fpc); } crlf)?;

        information_field =
            ("i=" text >save_begin_1 %{ sdp->information = osdp_copy(begin_1, fpc); } crlf)?;

        session_name_field =
            "s=" text >save_begin_1 %{ sdp->name = osdp_copy(begin_1, fpc); } crlf;

        origin_field =
            "o=" username >save_begin_1 %{ sdp->origin->username = osdp_copy(begin_1, fpc); } " "
            sess_id >{ sdp->origin->session_id = 0; } @{ sdp->origin->session_id = sdp->origin->session_id * 10 + (uint64_t)fcd; } " "
            sess_version >{ sdp->origin->session_version = 0; } @{ sdp->origin->session_version = sdp->origin->session_version * 10 + (uint64_t)fcd; } " "
            nettype >save_begin_1 %{ sdp->origin->network_type = osdp_copy(begin_1, fpc); } " "
            addrtype >save_begin_1 %{ sdp->origin->address_type = osdp_copy(begin_1, fpc); } " "
            unicast_address >save_begin_1 %{ sdp->origin->address = osdp_copy(begin_1, fpc); } crlf;

        proto_version =
            "v=" digit+ >{ sdp->protocol_version = 0; } @{ sdp->protocol_version = sdp->protocol_version * 10 + fcd; } crlf;

        session_description =
            proto_version
            origin_field >{ sdp->origin = osdp_realloc(NULL, sizeof(struct osdp_origin)); }
            session_name_field
            information_field
            uri_field
            email_fields
            phone_fields
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

void
osdp_reset(struct osdp_session_descr* sdp)
{
    size_t i;

    sdp->protocol_version = -1;

    if (sdp->origin != NULL) {
        osdp_free(sdp->origin->username);
        osdp_free(sdp->origin->network_type);
        osdp_free(sdp->origin->address_type);
        osdp_free(sdp->origin->address);
        osdp_free(sdp->origin);
        sdp->origin = NULL;
    }

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

    /* TODO */
    sdp->connection = NULL;

    for (i = 0; i < sdp->bandwidths_size; ++i) {
        /* TODO */
    }
    sdp->bandwidths = NULL;
    sdp->bandwidths_size = 0;

    for (i = 0; i < sdp->times_size; ++i) {
        /* TODO */
    }
    sdp->times = NULL;
    sdp->times_size = 0;

    /* TODO */
    sdp->key = NULL;

    for (i = 0; i < sdp->attributes_size; ++i) {
        /* TODO */
    }
    sdp->attributes = NULL;
    sdp->attributes_size = 0;

    for (i = 0; i < sdp->media_descrs_size; ++i) {
        /* TODO */
    }
    sdp->media_descrs = NULL;
    sdp->media_descrs_size = 0;
}
