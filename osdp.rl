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

void* (*osdp_realloc)(void*, size_t) = realloc;

/* static char* */
/* osdp_copy(const char* begin, const char* end) */
/* { */
/*     size_t size = (size_t)(end - begin); */
/*     char* result; */
/*  */
/*     result = osdp_realloc(NULL, size + 1); */
/*     if (result != NULL) { */
/*         memcpy(result, begin, size); */
/*         result[size] = '\0'; */
/*     } */
/*  */
/*     return result; */
/* } */
/*  */
/* static void* */
/* osdp_resize(void** ptr, size_t* n, size_t new_n, size_t size) */
/* { */
/*     void* new_ptr; */
/*  */
/*     new_ptr = osdp_realloc(ptr, new_n * size); */
/*     if (new_ptr != NULL) { */
/*         *ptr = new_ptr; */
/*         *n = new_n; */
/*     } */
/*  */
/*     return new_ptr; */
/* } */

int
osdp_parse_session_descr(struct osdp_session_descr* sdp, const char* str, size_t sz)
{
    const char* p = str;
    const char* pe = p + sz;
    const char* eof = pe;
    int cs;

    const char* begin[8];
    const char* end[8];

    int ok = 0;

    errno = 0;

    %%{
        # TODO
        session_description =
            any*;

        main :=
            session_description %{ ok = 1; };
    }%%

    %% write init;
    %% write exec;

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
