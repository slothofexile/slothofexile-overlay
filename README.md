<img width="1923" height="1083" alt="image" src="https://github.com/user-attachments/assets/a75514c0-18a2-4532-ad92-f2f106ea1a2b" />

[![Watch the video](https://youtube.com)](https://youtu.be/nuFQWeiMySc)

<br>
<br>
<br>


**About this project:**

I started playing Path of Exile (some time around Legacy league) and I had always wanted to play with a character overlay (like the streamers did) but couldn't find one, so I made one -- first in Autoit using GDI+ then rewritten from the ground up in Godot 4.

As of this writing (3.29 Allflame League on PoE1 ), the model I have on it is Cheems the Shiba, on a boat with a fishing rod, complete with pirate flag, pirate hat and eyepatch. _I can see all that getting updated with every new league if this project turns out to be a long term thing._

<br>

**Anyway, these things are neither new, nor unique to Path of Exile.**

This is inspired partly by these **static** player/streamer overlays that go on top of your menu, health globes, potions, to "skin" the game UI:

&emsp;(This particular example is from 10 years ago [from reddit user Musti_A](url).)
  
&emsp;<img width="320" height="180" alt="image" src="https://github.com/user-attachments/assets/00ab18ab-dee1-4c42-bea2-b7bb29184a41" />

This is also inspired by these newer **animated/interactive** player/streamer overlays that react to something else.

&emsp;This slime character on the lower right talks when the [player/streamer](url) talks:
  
&emsp;<img width="320" height="180" alt="image" src="https://github.com/user-attachments/assets/32b03cb6-440f-49cc-9bd6-37a495de3246" />


&emsp;Just like this animated/interactive [character/avatar](url) that also talks/moves:
  
&emsp;<img width="320" height="180" alt="image" src="https://github.com/user-attachments/assets/00620ba9-c223-4338-8dae-351b29070b18" />

  
My overlay doesn't talk, but it does move. Functionally, it interacts with the Windows OS (not with the game) to figure out where the mouse is and rotates in place to follow the pointer. Architecturally, it's its own transparent "game" that just so happens to also be transparent to mouse clicks, allowing those clicks to pass through to which ever window is under it.


The only actual interaction with the game is when _reading_ the game text logs to figure out what area you're in. Many of the 3rd-party tools also do this, like [CurrencyCop from way back](url) (which I used 8-9 years ago), and newer ones like [Awakened PoE Trade](url) (which I still use), or [Lailoken's ExileUI](url).

It doesn't mess with the game or any other players (which is more that I can say for some MTX out there, like that damned Goblin Band). 

Only you and your audience can see the overlay.


<br>
<br>

**Warning, here be dragons.**

It's been slow going because I've had to learn Blender and Godot from scratch, and I've only managed to learn it enough to get something out that just barely works and doesn't explode (so far). I don't think it's good enough yet and I have so much to do -- area timer, client.txt parsing, area presets, etc... This is also my first time using Github. 

Just check out this mess of 3d asset imports into Godot. All I know for now is that it works, so I don't dare clean it up and have something break.

<img width="323" height="568" alt="image" src="https://github.com/user-attachments/assets/4dab5f0e-d66a-4774-901c-d1e694ddbc92" />




<br>
<br>
<br>

**Any AI use?**

Lots! _But probably not where and how you think it's been used. _

If you program at all, you'll recognize that the basic logic for something like this is simple high-school level math. Like mouse tracking is just arctan formulas to get angles, then rotate models by XYZ degrees, etc... It's the same logic whether on the original AutoIT or in Godot. 

AI is absolutely useful in parts that aren't code -- specifically nuances in how things are implemented in a specific platform/environment. Like how Godot implements something like shadows or handles the whole environment. Knowing how to render a 2d sprite in AutoIT + Windows GDI API, doesn't translate well to Godot outside of the pure/basic math. 

Shader Materials? Shadow Planes? Ambient Lighting? All Greek without AI to help me get something working.

It's with these nuances that would have taken forever to learn, that's _not_ coding, , where AI was 120% helpful.

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
