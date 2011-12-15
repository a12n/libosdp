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

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#if defined(_MSC_VER)
typedef unsigned __int64 osdp_uint64_t;
#elif defined(__GNUC__)
#   if defined(__LP64__)
typedef unsigned long osdp_uint64_t;
#   else /* defined(__LP64__) */
typedef unsigned long long osdp_uint64_t;
#   endif /* defined(__LP64__) */
#endif /* defined(_MSC_VER) */

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
struct osdp_time_zone;


/**
 * Parse Session Description Protocol message from a text buffer.
 *
 * @param session_descr Pointer to initialized session description
 * object. It must be initialized with OSDP_SESSION_DESCR_INIT macro
 * or by call to osdp_reset_session_descr if object is reused.
 * @param str TODO
 * @param str_sz TODO
 * @return Returns 0 on success. In case of system error, -errno value
 * will be returned (e.g. -ENOMEM). If syntax error is detected,
 * positive offset (starting from 1) into the input string is
 * returned.
 */
int
osdp_parse_session_descr(struct osdp_session_descr*, const char*, size_t);

void
osdp_reset_attribute(struct osdp_attribute*);

void
osdp_reset_bandwidth(struct osdp_bandwidth*);

void
osdp_reset_connection(struct osdp_connection*);

void
osdp_reset_email(struct osdp_email*);

void
osdp_reset_key(struct osdp_key*);

void
osdp_reset_media(struct osdp_media*);

void
osdp_reset_media_descr(struct osdp_media_descr*);

void
osdp_reset_origin(struct osdp_origin*);

void
osdp_reset_phone(struct osdp_phone*);

void
osdp_reset_repeat_time(struct osdp_repeat_time*);

/**
 * Reset session description object.
 *
 * Frees all memory allocated during osdp_parse_session_descr and
 * reinitializes session description object.
 *
 * @param session_descr Pointer to session description object.
 */
void
osdp_reset_session_descr(struct osdp_session_descr*);

void
osdp_reset_time(struct osdp_time*);

void
osdp_reset_time_zone(struct osdp_time_zone*);


extern void (*osdp_free)(void*);

extern void* (*osdp_calloc)(size_t, size_t);

extern void* (*osdp_realloc)(void*, size_t);


struct osdp_attribute
{
    char* name;

    char* value;
};
#define OSDP_ATTRIBUTE_INIT                     \
    { NULL, NULL }

struct osdp_bandwidth
{
    char* type;

    int value;
};
#define OSDP_BANDWIDTH_INIT                     \
    { NULL, -1 }

struct osdp_connection
{
    char* network_type;

    char* address_type;

    char* address;

    int ttl;

    int n_addresses;
};
#define OSDP_CONNECTION_INIT                    \
    { NULL, NULL, NULL, -1, -1 }

struct osdp_email
{
    char* address;

    char* name;
};
#define OSDP_EMAIL_INIT                         \
    { NULL, NULL }

struct osdp_key
{
    char* method;

    char* value;
};
#define OSDP_KEY_INIT                           \
    { NULL, NULL }

struct osdp_media
{
    char* type;

    int port;

    int n_ports;

    char* protocol;

    char** formats;
    size_t n_formats;
};
#define OSDP_MEDIA_INIT                         \
    { NULL, -1, -1, NULL, NULL, 0 }

struct osdp_media_descr
{
    struct osdp_media* media;

    char* information;

    struct osdp_connection* connections;
    size_t n_connections;

    struct osdp_bandwidth* bandwidths;
    size_t n_bandwidths;

    struct osdp_key* key;

    struct osdp_attribute* attributes;
    size_t n_attributes;
};
#define OSDP_MEDIA_DESCR_INIT                       \
    { NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, 0 }

struct osdp_origin
{
    char* username;

    osdp_uint64_t session_id;

    osdp_uint64_t session_version;

    char* network_type;

    char* address_type;

    char* address;
};
#define OSDP_ORIGIN_INIT                        \
    { NULL, 0, 0, NULL, NULL, NULL }

struct osdp_phone
{
    char* number;

    char* name;
};
#define OSDP_PHONE_INIT                         \
    { NULL, NULL }

struct osdp_repeat_time
{
    osdp_uint64_t interval;

    osdp_uint64_t duration;

    int* offsets;
    size_t n_offsets;
};
#define OSDP_REPEAT_TIME_INIT                   \
    { 0, 0, NULL, 0 }

struct osdp_session_descr
{
#ifdef __cplusplus
    osdp_session_descr() :
        protocol_version(-1),
        origin(0),
        name(0),
        information(0),
        uri(0),
        emails(0),
        n_emails(0),
        phones(0),
        n_phones(0),
        connection(0),
        bandwidths(0),
        n_bandwidths(0),
        times(0),
        n_times(0),
        time_zones(0),
        n_time_zones(0),
        key(0),
        attributes(0),
        n_attributes(0),
        media_descrs(0),
        n_media_descrs(0)
    {
    }

    ~osdp_session_descr()
    {
        osdp_reset_session_descr(this);
    }
#endif /* __cplusplus */

    int protocol_version;

    struct osdp_origin* origin;

    char* name;

    char* information;

    char* uri;

    struct osdp_email* emails;
    size_t n_emails;

    struct osdp_phone* phones;
    size_t n_phones;

    struct osdp_connection* connection;

    struct osdp_bandwidth* bandwidths;
    size_t n_bandwidths;

    struct osdp_time* times;
    size_t n_times;

    struct osdp_time_zone* time_zones;
    size_t n_time_zones;

    struct osdp_key* key;

    struct osdp_attribute* attributes;
    size_t n_attributes;

    struct osdp_media_descr* media_descrs;
    size_t n_media_descrs;
};
#define OSDP_SESSION_DESCR_INIT                                         \
    { -1, NULL, NULL, NULL, NULL, NULL, 0, NULL, 0, NULL, NULL, 0,      \
            NULL, 0, NULL, 0, NULL, NULL, 0, NULL, 0 }

struct osdp_time
{
    osdp_uint64_t start;

    osdp_uint64_t stop;

    struct osdp_repeat_time* repeats;
    size_t n_repeats;
};
#define OSDP_TIME_INIT                          \
    { 0, 0, NULL, 0 }

struct osdp_time_zone
{
    osdp_uint64_t adjustment_time;

    int offset;
};
#define OSDP_TIME_ZONE_INIT                     \
    { 0, 0 }

#ifdef __cplusplus
} // extern "C"
#endif /* __cplusplus */

#endif /* __OSDP_H_INCLUDED__ */
