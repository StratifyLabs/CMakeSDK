#ifndef SDK_API_H
#define SDK_API_H

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
  int (*set_key)(void *context, const unsigned char *key, u32 keybits,
                 u32 bits_per_word);

  int (*encrypt_ecb)(void *context, const unsigned char input[16],
                     unsigned char output[16]);

  int (*decrypt_ecb)(void *context, const unsigned char input[16],
                     unsigned char output[16]);

  int (*encrypt_cbc)(void *context, u32 length, unsigned char iv[16],
                     const unsigned char *input, unsigned char *output);

  int (*decrypt_cbc)(void *context, u32 length, unsigned char iv[16],
                     const unsigned char *input, unsigned char *output);

  int (*encrypt_ctr)(void *context, u32 length, u32 *nc_off,
                     unsigned char nonce_counter[16],
                     unsigned char stream_block[16], const unsigned char *input,
                     unsigned char *output);

  int (*decrypt_ctr)(void *context, u32 length, u32 *nc_off,
                     unsigned char nonce_counter[16],
                     unsigned char stream_block[16], const unsigned char *input,
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
  //mbedtls only
  CRYPT_ECC_KEY_PAIR_SECP192R1,
  CRYPT_ECC_KEY_PAIR_SECP224R1,

  //supported by tinycrypt and mbedtls
  CRYPT_ECC_KEY_PAIR_SECP256R1,

  //mbedtls only
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
    void * context, 
    crypt_ecc_key_pair_t type, 
    u8 * public_key, u32 * public_key_capacity);
  //use public key from remote device, use private key from this device
  int (*dh_calculate_shared_secret)(void *context,
    const u8 *public_key, u32 public_key_length,
    u8 *secret, u32 secret_length);

  //EC - DSA - digital signature algorithm  
  int (*dsa_create_key_pair)(void * context, 
          crypt_ecc_key_pair_t type, 
    u8 * public_key, u32 * public_key_capacity,
    u8 * private_key, u32 * private_key_capacity);

  int (*dsa_set_key_pair)(void * context, 
    const u8 * public_key, u32 public_key_capacity,
    const u8 * private_key, u32 private_key_capacity);

  int (*dsa_sign)(void * context, const u8 * message_hash,
	      u32 hash_size, u8 *p_signature, u32 * signature_length);
  
  int (*dsa_verify)(void * context, const u8 * message_hash,
		u32 hash_size, const u8 * signature, u32 signature_length);

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


#endif // SDK_API_H
