#include "idevice_bridge.h"
#include <stdlib.h>
#include <string.h>

/*
 * Adapter layer around the vendored idevice FFI from Locus.
 *
 * The upstream Locus app calls these idevice symbols directly:
 *   rp_pairing_file_read
 *   tunnel_create_rppairing
 *   remote_server_connect_rsd
 *   location_simulation_new
 *   location_simulation_set
 *   location_simulation_clear
 *
 * This adapter keeps the Swift side stable and gives us one place to swap
 * implementations if the upstream FFI ABI changes.
 *
 * Link against Vendor/idevice/libidevice_ffi.a in the Xcode target.
 */

typedef struct {
    char *pairing_path;
    char *tunnel_ip;
    int tunnel_port;
    void *tunnel;
    void *rsd;
    void *simulation;
} lvs_engine_t;

static char *lvs_strdup(const char *value) {
    if (!value) return NULL;
    size_t len = strlen(value);
    char *copy = (char *)malloc(len + 1);
    if (!copy) return NULL;
    memcpy(copy, value, len + 1);
    return copy;
}

bool lvs_engine_prepare(const char *pairing_path,
                        const char *tunnel_ip,
                        int tunnel_port,
                        void **out_handle) {
    if (!pairing_path || !tunnel_ip || !out_handle) return false;
    *out_handle = NULL;

    lvs_engine_t *engine = (lvs_engine_t *)calloc(1, sizeof(lvs_engine_t));
    if (!engine) return false;

    engine->pairing_path = lvs_strdup(pairing_path);
    engine->tunnel_ip = lvs_strdup(tunnel_ip);
    engine->tunnel_port = tunnel_port;

    if (!engine->pairing_path || !engine->tunnel_ip) {
        lvs_engine_destroy(engine);
        return false;
    }

    /*
     * Upstream FFI calls are intentionally left as explicit integration points.
     * The vendored static library exposes these symbols; Xcode links them into
     * the app target. If the ABI differs in the pinned Locus release, adjust
     * only this adapter.
     */
    extern bool lvs_idevice_open(const char *pairing_path,
                                 const char *tunnel_ip,
                                 int tunnel_port,
                                 void **tunnel,
                                 void **rsd,
                                 void **simulation);

    if (!lvs_idevice_open(engine->pairing_path,
                          engine->tunnel_ip,
                          engine->tunnel_port,
                          &engine->tunnel,
                          &engine->rsd,
                          &engine->simulation)) {
        lvs_engine_destroy(engine);
        return false;
    }

    *out_handle = engine;
    return true;
}

bool lvs_engine_set_location(void *handle,
                             double latitude,
                             double longitude,
                             double altitude,
                             double speed,
                             double course) {
    lvs_engine_t *engine = (lvs_engine_t *)handle;
    if (!engine || !engine->simulation) return false;

    extern bool lvs_idevice_set_location(void *simulation,
                                         double latitude,
                                         double longitude,
                                         double altitude,
                                         double speed,
                                         double course);

    return lvs_idevice_set_location(engine->simulation,
                                    latitude,
                                    longitude,
                                    altitude,
                                    speed,
                                    course);
}

void lvs_engine_clear_location(void *handle) {
    lvs_engine_t *engine = (lvs_engine_t *)handle;
    if (!engine || !engine->simulation) return;

    extern void lvs_idevice_clear_location(void *simulation);
    lvs_idevice_clear_location(engine->simulation);
}

void lvs_engine_destroy(void *handle) {
    lvs_engine_t *engine = (lvs_engine_t *)handle;
    if (!engine) return;

    extern void lvs_idevice_close(void *tunnel, void *rsd, void *simulation);
    lvs_idevice_close(engine->tunnel, engine->rsd, engine->simulation);

    free(engine->pairing_path);
    free(engine->tunnel_ip);
    free(engine);
}
