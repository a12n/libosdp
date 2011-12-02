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

#include <stdlib.h>
#include <string.h>

#include "osdp.h"

%% machine osdp;
%% write data;

void (*osdp_free)(void*) = free;

void* (*osdp_realloc)(void*, size_t) = realloc;

static char*
osdp_mkstr(const char* begin, const char* end)
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

    const char* aux = NULL;
    int ok = 0;

    /* Current char as a digit */
#define fcd (*p - '0')

    %%{
        action save_aux { aux = fpc; }

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


        uri =
            (alnum | [:/.])+;

        username =
            alnum+;

        unicast_address =
            (alnum | ".")+;



        uri_field =
            ("u=" uri crlf)?;

        information_field =
            ("i=" text >save_aux %{ sdp->information = osdp_mkstr(aux, fpc); } crlf)?;

        session_name_field =
            "s=" text >save_aux %{ sdp->name = osdp_mkstr(aux, fpc); } crlf;

        origin_field =
            "o=" username >save_aux %{ sdp->origin->username = osdp_mkstr(aux, fpc); } " "
            sess_id >{ sdp->origin->session_id = 0; } @{ sdp->origin->session_id = sdp->origin->session_id * 10 + (uint64_t)fcd; } " "
            sess_version >{ sdp->origin->session_version = 0; } @{ sdp->origin->session_version = sdp->origin->session_version * 10 + (uint64_t)fcd; } " "
            nettype >save_aux %{ sdp->origin->network_type = osdp_mkstr(aux, fpc); } " "
            addrtype >save_aux %{ sdp->origin->address_type = osdp_mkstr(aux, fpc); } " "
            unicast_address >save_aux %{ sdp->origin->address = osdp_mkstr(aux, fpc); } crlf;

        proto_version =
            "v=" digit+ >{ sdp->protocol_version = 0; } @{ sdp->protocol_version = sdp->protocol_version * 10 + fcd; } crlf;

        session_description =
            proto_version
            origin_field >{ sdp->origin = osdp_realloc(NULL, sizeof(struct osdp_origin)); }
            session_name_field
            information_field
            uri_field
            ;

        main :=
            session_description %{ ok = 1; };
    }%%

    %% write init;
    %% write exec;

#undef fcd

    return ok ? 0 : (p - str) + 1;
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
        /* TODO */
    }
    sdp->emails = NULL;
    sdp->emails_size = 0;

    for (i = 0; i < sdp->phones_size; ++i) {
        /* TODO */
    }
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
