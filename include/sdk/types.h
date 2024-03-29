// Copyright Stratify Labs, See LICENSE for details

#ifndef CMSDK_SDK_TYPES_H_
#define CMSDK_SDK_TYPES_H_

#include <stdbool.h>
#include <stdint.h>

#if !defined __link

#include <sys/stat.h>

#define F32X "%lX"
#define F3208X "%08lX"
#define F32D "%ld"
#define F32U "%lu"
#define FINTD "%d"
#define FINTU "%u"
#else
#define F32X "%X"
#define F3208X "%08X"
#define F32D "%d"
#define F32U "%u"
#define FINTD "%d"
#define FINTU "%u"
#endif

#include "ioctl.h"

typedef uint8_t u8;
typedef int8_t s8;
typedef int8_t i8;
typedef uint16_t u16;
typedef int16_t s16;
typedef uint32_t u32;
typedef int32_t s32;
typedef uint64_t u64;
typedef int64_t s64;

#ifdef __cplusplus
extern "C" {
#endif

#define CMSDK_ALIAS(f) __attribute__((weak, alias(#f)))
#define CMSDK_WEAK __attribute__((weak))
#define CMSDK_UNUSED __attribute__((unused))
#define CMSDK_UNUSED_ARGUMENT(arg) ((void)arg)
#define CMSDK_NO_RETURN __attribute((noreturn))
#define CMSDK_STRINGIFY2(x) #x
#define CMSDK_STRINGIFY(x) CMSDK_STRINGIFY2(x)

#if defined CMSDK_BUILD_GIT_HASH
#define CMSDK_GIT_HASH CMSDK_STRINGIFY(CMSDK_BUILD_GIT_HASH)
#else
#define CMSDK_GIT_HASH "0000000"
#endif

#if defined __MINGW32__
#define CMSDK_PACK __attribute__((packed, gcc_struct))
#else
#define CMSDK_PACK __attribute__((packed))
#endif

#define CMSDK_NAKED __attribute__((naked))
#define CMSDK_ALIGN(x) __attribute__((aligned(x)))
#define CMSDK_ALWAYS_INLINE __attribute__((always_inline))
#define CMSDK_NEVER_INLINE __attribute__((noinline))
#define CMSDK_ARRAY_COUNT(x) (sizeof(x) / sizeof(x[0]))
#define CMSDK_TEST_BIT(x, y) ((x) & (1 << (y)))
#define CMSDK_SET_BIT(x, y) ((x) |= (1 << (y)))
#define CMSDK_SET_MASK(x, y) ((x) |= (y))
#define CMSDK_CLR_BIT(x, y) ((x) &= ~(1 << (y)))
#define CMSDK_CLR_MASK(x, y) ((x) &= ~(y))
#define CMSDK_API_REQUEST_CODE(a, b, c, d) (a << 24 | b << 16 | c << 8 | d)
#define CMSDK_REQUEST_CODE(a, b, c, d) (a << 24 | b << 16 | c << 8 | d)
#define CMSDK_PI_FLOAT (3.14159265358979323846f)

typedef struct CMSDK_PACK {
  u32 o_events /*! Event or events that happened */;
  void *data /*! A pointer to the device specific event data */;
} mcu_event_t;

typedef enum {
  MCU_EVENT_FLAG_NONE = 0,
  MCU_EVENT_FLAG_DATA_READY /*! Data have been received and is ready to read */
  = (1 << 0),
  MCU_EVENT_FLAG_WRITE_COMPLETE /*! A write operation has completed */
  = (1 << 1),
  MCU_EVENT_FLAG_CANCELED /*! An operation was canceled */ = (1 << 2),
  MCU_EVENT_FLAG_RISING /*! Specifies a rising edge */ = (1 << 3),
  MCU_EVENT_FLAG_FALLING /*! Specifies a falling edge */ = (1 << 4),
  MCU_EVENT_FLAG_SET_PRIORITY /*! If set, I_X_SETACTION requests will adjust the
                                 interrupt priority */
  = (1 << 5),
  MCU_EVENT_FLAG_ERROR /*! An error occured during */ = (1 << 6),
  MCU_EVENT_FLAG_ADDRESSED /*! The device has been addressed (I2C for example)
                            */
  = (1 << 7),
  MCU_EVENT_FLAG_OVERFLOW /*! An overflow condition has occurred */ = (1 << 8),
  MCU_EVENT_FLAG_UNDERRUN /*! An underrun condition has occurred */ = (1 << 9),
  MCU_EVENT_FLAG_HIGH /*! High event */ = (1 << 10),
  MCU_EVENT_FLAG_LOW /*! Low event (used with external interrupts) */
  = (1 << 11),
  MCU_EVENT_FLAG_SETUP /*! USB Setup event */ = (1 << 12),
  MCU_EVENT_FLAG_INDEX /*! Index event for QEI and similar (Setup alias) */
  = MCU_EVENT_FLAG_SETUP,
  MCU_EVENT_FLAG_STALL /*! Stall event */ = (1 << 13),
  MCU_EVENT_FLAG_STOP /*! Stop event (Stall alias) */ = MCU_EVENT_FLAG_STALL,
  MCU_EVENT_FLAG_DIRECTION_CHANGED /*! Direction change for QEI an similar
                                      (Stall alias) */
  = MCU_EVENT_FLAG_STALL,
  MCU_EVENT_FLAG_RESET /*! Reset event */ = (1 << 14),
  MCU_EVENT_FLAG_POWER /*! Power event */ = (1 << 15),
  MCU_EVENT_FLAG_SUSPEND /*! Suspend event */ = (1 << 16),
  MCU_EVENT_FLAG_RESUME /*! Resume event */ = (1 << 17),
  MCU_EVENT_FLAG_DEBUG /*! Debug event */ = (1 << 18),
  MCU_EVENT_FLAG_WAKEUP /*! Wakeup event */ = (1 << 19),
  MCU_EVENT_FLAG_SOF /*! Start of frame event */ = (1 << 20),
  MCU_EVENT_FLAG_MATCH /*! Match event */ = (1 << 21),
  MCU_EVENT_FLAG_ALARM /*! Alarm event (match alias) */ = MCU_EVENT_FLAG_MATCH,
  MCU_EVENT_FLAG_COUNT /*! Count event */ = (1 << 22),
  MCU_EVENT_FLAG_HALF_TRANSFER /*! The transfer is halfway complete (used with
                                  MCU_EVENT_FLAG_WRITE_COMPLETE and
                                  MCU_EVENT_FLAG_DATA_READY with circular DMA)
                                */
  = (1 << 23),
  MCU_EVENT_FLAG_STREAMING /*! The transfer is streaming data and will continue
                              until stopped */
  = (1 << 24)
} mcu_event_flag_t;

typedef enum {
  MCU_ERROR_NONE /*! 0: No Error */,
  MCU_ERROR_INVALID_PIN_ASSINGMENT /*! 1: Invalid Pin Assignment */,
  MCU_ERROR_INVALID_FREQUENCY /*! 2: Invalid Frequency */,
  MCU_ERROR_INVALID_CHANNEL_LOCATION /*! 3: Invalid Channel Location */,
  MCU_ERROR_INVALID_CHANNEL_VALUE /*! 4: Invalid Channel Value */,
  MCU_ERROR_I2C_ACK_ERROR /*! 6: I2C Ack Error */
} mcu_error_t;

typedef enum { MCU_CHANNEL_FLAG_IS_INPUT = 0x80 } mcu_channel_flag_t;

typedef int (*mcu_callback_t)(void *, const mcu_event_t *);

typedef struct {
  mcu_callback_t callback;
  void *context;
} mcu_event_handler_t;

/*! \details This attribute can be applied to RAM so
 * that it is stored in system memory that is universally
 * readable but can only be written in privileged mode.
 *
 * Example:
 * \code
 * static char buffer[512] MCU_SYS_MEM;
 * \endcode
 */
#define MCU_SYS_MEM __attribute__((section(".sysmem"))) CMSDK_ALIGN(4)
#define MCU_BACKUP_MEM __attribute__((section(".backup"))) CMSDK_ALIGN(4)

#ifdef __link
#define MCU_ROOT_CODE
#define MCU_PRIV_CODE
#else
#define MCU_ROOT_CODE __attribute__((section(".priv_code")))
#define MCU_PRIV_CODE MCU_ROOT_CODE
#endif

#ifdef __link
#define MCU_ROOT_EXEC_CODE
#define MCU_PRIV_EXEC_CODE
#else
#define MCU_ROOT_EXEC_CODE __attribute__((section(".priv_exec_code")))
#define MCU_PRIV_EXEC_CODE MCU_ROOT_EXEC_CODE
#endif

/*! \details This structure defines an action
 * to take when an asynchronous event occurs (such as
 * a pin change interrupt).
 *
 */
typedef struct {
  u8 channel /*! The channel (a GPIO pin or timer channel) */;
  s8 prio /*! The interrupt priority */;
  u32 o_events /*! The peripheral specific event */;
  mcu_event_handler_t handler /*! Event handler */;
} mcu_action_t;

/*! \brief MCU Pin
 *
 */
typedef struct CMSDK_PACK {
  u8 port /*! Port */;
  u8 pin /*! Pin number */;
} mcu_pin_t;

static inline int mcu_is_port_valid(u8 port) { return (port != 0xff); }

static inline mcu_pin_t mcu_invalid_pin() {
  mcu_pin_t pin;
  pin.port = 0xff;
  pin.pin = 0xff;
  return pin;
}

static inline mcu_pin_t mcu_pin(u8 port, u8 num) {
  mcu_pin_t pin;
  pin.port = port;
  pin.pin = num;
  return pin;
}

#define MCU_PIN_ASSIGNMENT_COUNT(type) (sizeof(type) / sizeof(mcu_pin_t))
#define MCU_CONFIG_PIN_ASSIGNMENT(type, handle)                                \
  (handle->config ? &(((type *)(handle->config))->attr.pin_assignment) : 0)

typedef struct CMSDK_PACK {
  u32 loc;
  u32 value;
} mcu_channel_t;

static inline mcu_channel_t mcu_channel(u32 loc, u32 value) {
  mcu_channel_t channel;
  channel.loc = loc;
  channel.value = value;
  return channel;
}

#define I_MCU_GETVERSION 0
#define I_MCU_GETINFO 1
#define I_MCU_SETATTR 2
#define I_MCU_SETACTION (3 | _IOCTL_ROOT)
#define I_MCU_TOTAL 4

typedef struct {
  u32 sn[4];
} mcu_sn_t;

struct mcu_timeval {
  u32 tv_sec;  // SCHEDULER_TIMEVAL_SECONDS seconds each
  u32 tv_usec; // up to 1000000 * SCHEDULER_TIMEVAL_SECONDS
};

#define MCU_RAM_PAGE_SIZE 1024

typedef struct CMSDK_PACK {
  u32 core_osc_freq;
  u32 core_cpu_freq;
  u32 core_periph_freq;
  u32 usb_max_packet_zero;
  u32 o_flags /*! MCU flags such as CMSDK_BOARD_CONFIG_FLAG_LED_ACTIVE_HIGH */;
#if defined __link
  u32 event_handler /*! A callback to an event handler that gets, for example,
                       CMSDK_BOARD_CONFIG_EVENT_FATAL on a fatal event */
    ;
  u32 arch_config /*! A pointer to MCU architecture specific data, for example,
                     stm32_arch_config_t */
    ;
  u32 secret_key_address /*! A pointer to the secret cryptographic keys to be
                            protected from application access. */
    ;
#else

  void (*event_handler)(
    int,
    void *) /*! A callback to an event handler that gets, for example,
               CMSDK_BOARD_CONFIG_EVENT_FATAL on a fatal event */
    ;

  const void *arch_config /*! A pointer to MCU architecture specific data, for
                             example, stm32_arch_config_t */
    ;
  const void *secret_key_address /*! A pointer to the secret cryptographic keys
                                    to be protected from application access. */
    ;
#endif
  u32 secret_key_size /*! The size in bytes of the secret key region (must be
                         MPU compatible). */
    ;
  u32 o_mcu_debug /*! Debugging flags (only used when linking to debug libraries
                   */
    ;
  u32 os_mpu_text_mask /*! Mask to apply to _text when setting the kernel memory
                          protection 0x0000ffff to ignore bottom 16-bits */
    ;
  mcu_pin_t led /*! A pin on the board that drives an LED. Use {0xff, 0xff} if
                   not available. */
    ;
  u8 debug_uart_port /*! The port used for the UART debugger. This is only used
                        for _debug builds */
    ;
  u8 resd;
} mcu_board_config_t;

// legacy definitions
#define MCU_ALIAS(f) CMSDK_ALIAS(f)
#define MCU_WEAK CMSDK_WEAK
#define MCU_UNUSED CMSDK_UNUSED
#define MCU_UNUSED_ARGUMENT(arg) CMSDK_UNUSED_ARGUMENT(arg)
#define MCU_NO_RETURN CMSDK_NO_RETURN
#define MCU_STRINGIFY(x) CMSDK_STRINGIFY2(x)
#define MCU_API_REQUEST_CODE(a, b, c, d) CMSDK_API_REQUEST_CODE(a, b, c, d)
#define MCU_REQUEST_CODE(a, b, c, d) CMSDK_REQUEST_CODE(a, b, c, d)
#define MCU_PI_FLOAT CMSDK_PI_FLOAT
#define MCU_TEST_BIT(x, y) CMSDK_TEST_BIT(x, y)
#define MCU_SET_BIT(x, y) CMSDK_SET_BIT(x, y)
#define MCU_SET_MASK(x, y) CMSDK_SET_MASK(x, y)
#define MCU_CLR_BIT(x, y) CMSDK_CLR_BIT(x, y)
#define MCU_CLR_MASK(x, y) CMSDK_CLR_MASK(x, y)
#define SOS_GIT_HASH CMSDK_GIT_HASH
#define MCU_PACK CMSDK_PACK
#define MCU_NAKED CMSDK_NAKED
#define MCU_ALIGN(x) CMSDK_ALIGN(x)
#define MCU_ALWAYS_INLINE CMSDK_ALWAYS_INLINE
#define MCU_NEVER_INLINE CMSDK_NEVER_INLINE
#define MCU_ARRAY_COUNT(x) CMSDK_ARRAY_COUNT(x)

#ifdef __cplusplus
}
#endif

#endif /* _SDK_TYPES_H_ */
