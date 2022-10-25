// Copyright Stratify Labs, See LICENSE for details

#ifndef CMSDK_SDK_API_H
#define CMSDK_SDK_API_H

#include <sdk/types.h>

typedef struct {
  const char *name;
  u32 version;
  const char *git_hash;
} api_t;

typedef struct {
  api_t sos_api;
  int (*init)(void **context);
  void (*deinit)(void **context);
  int (*set_key)(
    void *context,
    const unsigned char *key,
    u32 keybits,
    u32 bits_per_word);

  int (*encrypt_ecb)(
    void *context,
    const unsigned char input[16],
    unsigned char output[16]);

  int (*decrypt_ecb)(
    void *context,
    const unsigned char input[16],
    unsigned char output[16]);

  int (*encrypt_cbc)(
    void *context,
    u32 length,
    unsigned char iv[16],
    const unsigned char *input,
    unsigned char *output);

  int (*decrypt_cbc)(
    void *context,
    u32 length,
    unsigned char iv[16],
    const unsigned char *input,
    unsigned char *output);

  int (*encrypt_ctr)(
    void *context,
    u32 length,
    u32 *nc_off,
    unsigned char nonce_counter[16],
    unsigned char stream_block[16],
    const unsigned char *input,
    unsigned char *output);

  int (*decrypt_ctr)(
    void *context,
    u32 length,
    u32 *nc_off,
    unsigned char nonce_counter[16],
    unsigned char stream_block[16],
    const unsigned char *input,
    unsigned char *output);
  u32 (*get_context_size)();

} crypt_aes_api_t;

// Can be used for SHA256
typedef struct {
  api_t sos_api;
  int (*init)(void **context);
  void (*deinit)(void **context);
  int (*start)(void *context);
  int (*update)(void *context, const unsigned char *input, u32 size);
  int (*finish)(void *context, unsigned char *output, u32 size);
  u32 (*get_context_size)();
} crypt_hash_api_t;

typedef enum {
  // mbedtls only
  CRYPT_ECC_KEY_PAIR_SECP192R1,
  CRYPT_ECC_KEY_PAIR_SECP224R1,

  // supported by tinycrypt and mbedtls
  CRYPT_ECC_KEY_PAIR_SECP256R1,

  // mbedtls only
  CRYPT_ECC_KEY_PAIR_SECP384R1,
  CRYPT_ECC_KEY_PAIR_SECP521R1,
  CRYPT_ECC_KEY_PAIR_BP256R1,
  CRYPT_ECC_KEY_PAIR_BP384R1,
  CRYPT_ECC_KEY_PAIR_BP512R1,
  CRYPT_ECC_KEY_PAIR_CURVE25519,
  CRYPT_ECC_KEY_PAIR_SECP192K1,
  CRYPT_ECC_KEY_PAIR_SECP224K1,
  CRYPT_ECC_KEY_PAIR_SECP256K1,
  CRYPT_ECC_KEY_PAIR_CURVE448
} crypt_ecc_key_pair_t;

typedef struct {
  api_t sos_api;
  int (*init)(void **context);
  void (*deinit)(void **context);

  int (*dh_create_key_pair)(
    void *context,
    crypt_ecc_key_pair_t type,
    u8 *public_key,
    u32 *public_key_capacity);
  // use public key from remote device, use private key from this device
  int (*dh_calculate_shared_secret)(
    void *context,
    const u8 *public_key,
    u32 public_key_length,
    u8 *secret,
    u32 secret_length);

  // EC - DSA - digital signature algorithm
  int (*dsa_create_key_pair)(
    void *context,
    crypt_ecc_key_pair_t type,
    u8 *public_key,
    u32 *public_key_capacity,
    u8 *private_key,
    u32 *private_key_capacity);

  int (*dsa_set_key_pair)(
    void *context,
    const u8 *public_key,
    u32 public_key_capacity,
    const u8 *private_key,
    u32 private_key_capacity);

  int (*dsa_sign)(
    void *context,
    const u8 *message_hash,
    u32 hash_size,
    u8 *p_signature,
    u32 *signature_length);

  int (*dsa_verify)(
    void *context,
    const u8 *message_hash,
    u32 hash_size,
    const u8 *signature,
    u32 signature_length);

  u32 (*get_context_size)();

} crypt_ecc_api_t;

typedef struct {
  api_t sos_api;
  int (*init)(void **context);
  void (*deinit)(void **context);
  int (*seed)(void *context, const unsigned char *data, u32 data_len);
  int (*random)(void *context, unsigned char *output, u32 output_length);
  u32 (*get_context_size)();
} crypt_random_api_t;

#if !defined __link
#define CRYPT_SHA256_API_REQUEST MCU_API_REQUEST_CODE('s', '2', '5', '6')
#define CRYPT_SHA512_API_REQUEST MCU_API_REQUEST_CODE('s', '5', '1', '2')
#define CRYPT_RANDOM_API_REQUEST MCU_API_REQUEST_CODE('r', 'a', 'n', 'd')
#define CRYPT_AES_API_REQUEST MCU_API_REQUEST_CODE('a', 'e', 's', '!')
#define CRYPT_ECC_API_REQUEST MCU_API_REQUEST_CODE('e', 'c', 'c', '!')
#define CRYPT_ECC_ROOT_API_REQUEST MCU_API_REQUEST_CODE('r', 'e', 'c', 'c')
#define CRYPT_SHA256_ROOT_API_REQUEST MCU_API_REQUEST_CODE('r', '2', '5', '6')
#define CRYPT_AES_ROOT_API_REQUEST MCU_API_REQUEST_CODE('r', 'a', 'e', 's')
#define CRYPT_RANDOM_ROOT_API_REQUEST MCU_API_REQUEST_CODE('r', 'r', 'a', 'n')
#endif

#ifndef SOS_API_WIFI_API_H
#define SOS_API_WIFI_API_H

#define SDK_API_WIFI_API_T 1

enum {
  WIFI_SECURITY_INVALID,
  WIFI_SECURITY_OPEN,
  WIFI_SECURITY_WEP,
  WIFI_SECURITY_WPA_PSK,
  WIFI_SECURITY_802_1X,
};

enum { WIFI_SCAN_REGION_ASIA, WIFI_SCAN_REGION_NORTH_AMERICA };

// SSID is 32 characters

typedef struct MCU_PACK {
  u8 channel;
  u8 slot_count;
  u8 slot_time_ms;
  u8 probe_count;
  s8 rssi_threshold;
  u8 scan_region;
  u8 is_passive;
} wifi_scan_attributes_t;

typedef struct MCU_PACK {
  char ssid[32];
  u8 bssid[6]; // mac address
  u8 idx;
  u8 channel;
  u8 security;
  s8 rssi;
  u8 resd[2];
} wifi_ssid_info_t;

typedef struct MCU_PACK {
  u8 password[64];
} wifi_auth_info_t;

typedef struct MCU_PACK {
  u32 ip_address;
  u32 gateway_address;
  u32 dns_address;
  u32 subnet_mask;
  u32 lease_time_s;
} wifi_ip_info_t;

#define WIFI_API_INFO_RESD (0x55)

#if !defined NETIF_MAX_MAC_ADDRESS_SIZE
#define NETIF_MAX_MAC_ADDRESS_SIZE 16
#endif

typedef struct MCU_PACK {
  char ssid[32];
  u8 security;
  u8 rssi;
  u8 is_connected;
  u8 resd0;
  wifi_ip_info_t ip;
  u8 mac_address[NETIF_MAX_MAC_ADDRESS_SIZE];
} wifi_info_t;

#undef NETIF_MAX_MAC_ADDRESS_SIZE

// WPS is wifi protected setup

typedef struct {
  api_t sos_api;
  int (*init)(void **context);
  void (*deinit)(void **context);

  int (*connect)(
    void *context,
    const wifi_ssid_info_t *ssid_info,
    const wifi_auth_info_t *auth);
  int (*disconnect)(void *context);
  int (*start_scan)(void *context, const wifi_scan_attributes_t *attributes);
  int (*get_scan_count)(void *context);
  int (*get_ssid_info)(void *context, u8 idx, wifi_ssid_info_t *dest);
  int (*get_info)(void *context, wifi_info_t *info);
  int (*set_mode)(void *context);
  int (*set_mac_address)(void *context, u8 mac_address[6]);
  int (*get_mac_address)(void *context, u8 mac_address[6]);
  int (*get_factory_mac_address)(void *context, u8 mac_address[6]);
  int (*set_ip_address)(void *context, const wifi_ip_info_t *static_ip_address);

  int (*set_sleep_mode)(void *context);
  int (*sleep)(void *context, u32 sleep_time_ms);
  int (*set_device_name)(void *context, const char *name);
  int (*set_tx_power)(void *context, u8 power_level);

  // DHCP mode, STA, AP, P2P modes monitor modes
  // SNTP (time syncing)
  // set system time
  // get system time

} wifi_api_t;

extern const wifi_api_t wifi_api;

#if !defined __link
#define WIFI_API_REQUEST MCU_API_REQUEST_CODE('w', 'i', 'f', 'i')
#else
#define WIFI_API_REQUEST &wifi_api
#endif

#endif

#endif // SDK_API_H
