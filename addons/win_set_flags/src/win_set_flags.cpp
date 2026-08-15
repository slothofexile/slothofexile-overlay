#include "win_set_flags.h"

#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/core/class_db.hpp>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

using namespace godot;

WinSetFlags* WinSetFlags::singleton = nullptr;

WinSetFlags* WinSetFlags::get_singleton() {
    return singleton;
}

WinSetFlags::WinSetFlags() {
    ERR_FAIL_COND(singleton != nullptr);
    singleton = this;
}

WinSetFlags::~WinSetFlags() {
    ERR_FAIL_COND(singleton != this);
    singleton = nullptr;
}

void WinSetFlags::_bind_methods() {
    ClassDB::bind_method(
        D_METHOD("win_set_flag", "window_id", "flag", "enabled"),
        &WinSetFlags::win_set_flag
    );

#ifdef _WIN32
    ClassDB::bind_integer_constant(
        get_class_static(),
        StringName(),
        StringName("WS_EX_TRANSPARENT"),
        WS_EX_TRANSPARENT
    );

    ClassDB::bind_integer_constant(
        get_class_static(),
        StringName(),
        StringName("WS_EX_LAYERED"),
        WS_EX_LAYERED
    );
#endif
}

void WinSetFlags::win_set_flag(
    int64_t window_id,
    int64_t flag,
    bool enabled
) {
#ifdef _WIN32

    int64_t hwnd_int =
        DisplayServer::get_singleton()->window_get_native_handle(
            DisplayServer::WINDOW_HANDLE,
            static_cast<int>(window_id)
        );

    HWND hwnd = reinterpret_cast<HWND>(
        static_cast<intptr_t>(hwnd_int)
        );

    if (!hwnd) {
        return;
    }

    LONG_PTR ex_style =
        GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    if (enabled) {
        ex_style |= static_cast<LONG_PTR>(flag);
    }
    else {
        ex_style &= ~static_cast<LONG_PTR>(flag);
    }

    SetWindowLongPtr(
        hwnd,
        GWL_EXSTYLE,
        ex_style
    );

    SetWindowPos(
        hwnd,
        nullptr,
        0,
        0,
        0,
        0,
        SWP_FRAMECHANGED |
        SWP_NOMOVE |
        SWP_NOSIZE |
        SWP_NOZORDER |
        SWP_NOACTIVATE
    );

#endif
}