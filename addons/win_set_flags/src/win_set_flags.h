#pragma once

#include <godot_cpp/classes/object.hpp>

using namespace godot;

class WinSetFlags : public Object {
    GDCLASS(WinSetFlags, Object);

    static WinSetFlags* singleton;

protected:
    static void _bind_methods();

public:
    WinSetFlags();
    ~WinSetFlags();

    static WinSetFlags* get_singleton();

    void win_set_flag(int64_t window_id, int64_t flag, bool enabled);
};