Setting the window flags WS_EX_LAYERED and WS_EX_TRANSPARENT allows the overlay to effectively be transparent to mouse hover and mouse clicks. My original overlay proofs-of-concept (both written in AutoIT) would call Windows API somewhat natively with a UDF to set those flags, but Godot cannot. 

This C++ binary sets those same flags using Win32/User32.dll from inside Godot. (For now, only those 2 flags are needed for the overlay to work as intended.)

More info in the Microsoft KB for the curious: https://learn.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
