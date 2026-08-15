#include "register_types.h"
#include "win_set_flags.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

using namespace godot;

static WinSetFlags* win_set_flags_singleton = nullptr;

void initialize_win_set_flags_module(
    ModuleInitializationLevel p_level
) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    GDREGISTER_CLASS(WinSetFlags);

    win_set_flags_singleton = memnew(WinSetFlags);

    Engine::get_singleton()->register_singleton(
        "WinSetFlags",
        win_set_flags_singleton
    );
}

void uninitialize_win_set_flags_module(
    ModuleInitializationLevel p_level
) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    Engine::get_singleton()->unregister_singleton(
        "WinSetFlags"
    );

    memdelete(win_set_flags_singleton);
    win_set_flags_singleton = nullptr;
}

extern "C" {

    GDExtensionBool GDE_EXPORT win_set_flags_init(
        GDExtensionInterfaceGetProcAddress p_get_proc_address,
        const GDExtensionClassLibraryPtr p_library,
        GDExtensionInitialization* r_initialization
    ) {
        GDExtensionBinding::InitObject init_obj(
            p_get_proc_address,
            p_library,
            r_initialization
        );

        init_obj.register_initializer(
            initialize_win_set_flags_module
        );

        init_obj.register_terminator(
            uninitialize_win_set_flags_module
        );

        init_obj.set_minimum_library_initialization_level(
            MODULE_INITIALIZATION_LEVEL_SCENE
        );

        return init_obj.init();
    }

}