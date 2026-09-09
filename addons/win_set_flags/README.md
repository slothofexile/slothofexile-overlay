Setting the window flags WS_EX_LAYERED and WS_EX_TRANSPARENT allows the overlay to effectively be transparent to mouse hover and mouse clicks. 

My original overlay proofs-of-concept (both written in AutoIT) called the Windows API natively (using a UDF on top of DllCall) to set those flags, but Godot cannot. 

This C++ binary sets those same flags by calling the same exact APIs Win32/User32.dll from inside Godot. (That API can actually set many more flags but For now, only those 2 flags are needed for the overlay to work as intended.)

More info in the Microsoft KB for the curious: https://learn.microsoft.com/en-us/windows/win32/winmsg/extended-window-styles
