#ifndef LVS_ENGINE_BRIDGE_H
#define LVS_ENGINE_BRIDGE_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool lvs_engine_prepare(const char *pairing_path,
                        const char *tunnel_ip,
                        int tunnel_port,
                        void **out_handle);

bool lvs_engine_set_location(void *handle,
                             double latitude,
                             double longitude,
                             double altitude,
                             double speed,
                             double course);

void lvs_engine_clear_location(void *handle);
void lvs_engine_destroy(void *handle);

#ifdef __cplusplus
}
#endif

#endif
