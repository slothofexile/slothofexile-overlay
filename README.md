<img width="1923" height="1083" alt="image" src="https://github.com/user-attachments/assets/a75514c0-18a2-4532-ad92-f2f106ea1a2b" />

[![Watch the video](https://youtube.com)](https://youtu.be/nuFQWeiMySc)



<br>
<br>
<br>


**About this project:**

I've been playing Path of Exile since Legacy league and I had always wanted to play with a character overlay but couldn't find one, so I made one -- first in Autoit using GDI+ then rewritten from the ground up in Godot 4.


As of this writing (1st week of 3.29 Allflame League), the model I have on it is Cheems the shiba, on a boat with a fishing rod, complete with pirate flag, pirate hat and eyepatch. I can see all that getting updated with every new league if this project turns out to be a long term thing.

<br>
<br>
<br>

**Why bad code?**

It's been slow going because I've had to learn Blender and Godot from scratch, and I've only managed to learn it enough to get something out that just barely works and doesn't explode (so far). I don't think it's good enough yet and I have so much to do -- area timer, client.txt parsing, area presets, etc... This is also my first time using Github. 

Just check out this mess of 3d asset imports into Godot. All I know for now is that it works, so I don't dare clean it up and have something break.

<img width="323" height="568" alt="image" src="https://github.com/user-attachments/assets/4dab5f0e-d66a-4774-901c-d1e694ddbc92" />




The biggest reason I'm releasing the exe anyway is because with the league just starting, releasing something now should give more people more time to find it, use it, have fun with it, or even just have a good laugh. 

<br>
<br>
<br>

**Any AI use?**

Lots! But probably not where and how you think it's been used. 

If you program at all, you'll recognize that the basic logic for something like this is simple high-school level math. Like mouse tracking is just arctan formulas to get angles, then rotate models by XYZ degrees, etc... It's the same logic whether on the original AutoIT or in Godot. 

AI is absolutely useful in parts that aren't code -- specifically nuances in how a platform/environment. Like how Godot implements something like shadows or handles the whole environment. Knowing how to render a 2d sprite in AutoIT + Windows GDI API, doesn't translate well to Godot outside of the pure/basic math. 

Shader Materials? Shadow Planes? Ambient Lighting? All Greek without AI to help me get something working.

It's with these nuances in the platform that would have taken forever to learn, that's _not_ coding, , where AI was 120% helpful.

<br>
<br>
<br>

**What's next?**

Right now, it has just one preset (lighting, shadows, color, etc...) so far, and that's coastal hideout (because of course that's my hideout). It takes soooo much work to make just one preset because you have to eyeball everything --- sun angles, ambient light intensity, shadow tints, etc...

When I get client.txt parsing working, I can start making other presets for the rest of the areas. As much as I'd love to work on this full time, I got a day job and a family, so they come 1st.

<br>
<br>
<br>

**How To:**

Just run the exe and the overlay should appear in your primary monitor. It should also appear on your taskbar.

<img width="167" height="59" alt="image" src="https://github.com/user-attachments/assets/8d0e2a61-8f0a-45af-85af-d45fd861080f" />

<br>
<br>
<br>

From there, just start Path of Exile and the Overlay should still stay on top of that window. Almost perfect position.

<img width="1921" height="1081" alt="image" src="https://github.com/user-attachments/assets/6c00a803-dc69-45bd-8e49-4807d84da8d6" />

**_If you have more than one monitor and the overlay appears on a different monitor than where you have Path of Exile playing, just use the Windows hotkey Win + Shift + Left (or Right) Arrow to move the overlay where you need it._

<br>
<br>

When you want to quit the overlay, just click on the taskbar icon(?) and click Close Window.

<img width="416" height="148" alt="image" src="https://github.com/user-attachments/assets/9e8d3736-c9ab-47c6-9f6f-c6eb6bb84e65" />
