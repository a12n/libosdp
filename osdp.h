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

#pragma once

#ifndef __OSDP_H_INCLUDED__
#define __OSDP_H_INCLUDED__

/* FIXME */
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

struct osdp_attribute;
struct osdp_bandwidth;
struct osdp_connection;
struct osdp_email;
struct osdp_key;
struct osdp_media;
struct osdp_media_descr;
struct osdp_origin;
struct osdp_phone;
struct osdp_repeat_time;
struct osdp_session_descr;
struct osdp_time;
struct osdp_time_zones;

struct osdp_attribute
{
    char* name;                 /* {1} */

    char* value;                /* ? */
};
#define OSDP_ATTRIBUTE_INIT                     \
    { NULL, NULL }

struct osdp_bandwidth
{
    char* type;                 /* {1} */

    int value;                  /* {1} */
};
#define OSDP_BANDWIDTH_INIT                     \
    { NULL, -1 }

struct osdp_connection
{
    char* network_type;         /* {1} */

    char* address_type;         /* {1} */

    char* address;              /* {1} */

    int ttl;                    /* ? -1 */

    int n_addresses;            /* ? -1 */
};
#define OSDP_CONNECTION_INIT                    \
    { NULL, NULL, NULL, -1, -1 }

struct osdp_email
{
    char* address;              /* {1} */

    char* name;                 /* ? */
};
#define OSDP_EMAIL_INIT                         \
    { NULL, NULL }

struct osdp_key
{
    char* method;               /* {1} */

    char* value;                /* ? */
};
#define OSDP_KEY_INIT                           \
    { NULL, NULL }

struct osdp_media
{
    char* type;                 /* {1} */

    int port;                   /* {1} */

    int n_ports;                /* ? -1 */

    char* protocol;             /* {1} */

    char** formats;             /* {1,} */
    size_t formats_size;
};
#define OSDP_MEDIA_INIT                         \
    { NULL, -1, -1, NULL, NULL, 0 }.

struct osdp_media_descr
{
    struct osdp_media* media;   /* {1} */

    char* information;          /* {1} */

    struct osdp_connection* connection; /* ? */

    struct osdp_bandwidth* bandwidths; /* * */
    size_t bandwidths_size;

    struct osdp_key* key;       /* ? */

    struct osdp_attribute* attributes; /* * */
    size_t attributes_size;
};
#define OSDP_MEDIA_DESCR_INIT                       \
    { NULL, NULL, NULL, NULL, 0, NULL, NULL, 0 }

struct osdp_origin
{
    char* username;             /* {1} */

    uint64_t session_id;        /* {1} */

    uint64_t session_version;   /* {1} */

    char* network_type;         /* {1} */

    char* address_type;         /* {1} */

    char* address;              /* {1} */
};
#define OSDP_ORIGIN_INIT                        \
    { NULL, 0UL, 0UL, NULL, NULL, NULL }

struct osdp_phone
{
    char* number;               /* {1} */

    char* name;                 /* ? */
};
#define OSDP_PHONE_INIT                         \
    { NULL, NULL }

struct osdp_repeat_time
{
    uint64_t interval;          /* {1} */

    uint64_t duration;          /* {1} */

    uint64_t* offsets;          /* * */
    size_t offsets_size;
};
#define OSDP_REPEAT_TIME_INIT                   \
    { 0UL, 0UL, NULL, 0 }

struct osdp_session_descr
{
    int protocol_version;       /* {1} */

    struct osdp_origin* origin; /* {1} */

    char* name;                 /* {1} */

    char* information;          /* ? */

    char* uri;                  /* ? */

    struct osdp_email* emails;  /* * */
    size_t emails_size;

    struct osdp_phone* phones;  /* * */
    size_t phones_size;

    struct osdp_connection* connection; /* ? */

    struct osdp_bandwidth* bandwidths; /* * */
    size_t bandwidths_size;

    struct osdp_time* times;    /* + */
    size_t times_size;

    struct osdp_time_zones* time_zones; /* ? */

    struct osdp_key* key;       /* ? */

    struct osdp_attribute* attributes; /* * */
    size_t attributes_size;

    struct osdp_media_descr* media_descrs; /* * */
    size_t media_descrs_size;
};
#define OSDP_SESSION_DESCR_INIT                                         \
    { -1, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, 0,      \
            NULL, 0, NULL, NULL, NULL, 0, NULL, 0 }

struct osdp_time
{
    uint64_t start;             /* {1} */

    uint64_t stop;              /* {1} */

    struct osdp_repeat_time* repeats; /* * */
    size_t repeats_size;
};
#define OSDP_TIME_INIT                          \
    { 0UL, 0UL, NULL, 0 }

struct osdp_time_zones
{
    uint64_t* adjustment_times; /* + */
    size_t adjustment_times_size;

    uint64_t* offsets;          /* + */
    size_t offsets_size;
};
#define OSDP_TIME_ZONES_INIT                    \
    { NULL, 0, NULL, 0 }


extern void (*osdp_free)(void*);

extern void* (*osdp_realloc)(void*, size_t);


int
osdp_format(const struct osdp_session_descr*, char**, size_t*);

/* Allowed for freshly created osdp_session_descr or after osdp_reset. */
int
osdp_parse(struct osdp_session_descr*, const char*, size_t);

void
osdp_reset(struct osdp_session_descr*);

#ifdef __cplusplus
} // extern "C"
#endif /* __cplusplus */

#endif /* __OSDP_H_INCLUDED__ */
