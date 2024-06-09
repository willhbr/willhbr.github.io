---
title: "Repairing My Roborock S6"
image: /images/2024/henry.webp
---

About three weeks ago my previously-trusty [Roborock S6](https://global.roborock.com/pages/roborock-s6) (named Henry) stopped halfway through a clean. Usually this means that he found a tasty looking cable or shoelace and got tangled up, but when I got home he was just sitting in the hallway unobstructed. I popped him on his base, and didn't think much of it. The next time he was scheduled to clean up I got a notification saying that the laser distance sensor had malfunctioned, and that I should remove any obstructions and retry. That was cause for more concern.

I sat him in the middle of the floor and turned him on, and sure enough the LiDAR sensor (housed in the knob on top of the vacuum) didn't spin. After trying and failing to start three times, I got the error notification again.

After a look online, this seems to be a reasonably common failure, and the official advice is to contact customer support. So I dutifully contacted Roborock and explained the failure, and eventually they quoted me $70 for an "assessment" of whether it was repairable, and then estimated that a repair could cost $60-200. I'd also have to pay for shipping either way, which I'd conservatively estimate at $35 each way.

Customer service also pointed out that because the S6 was "phased out", including spare parts. I was not particularly thrilled at the prospect of paying $140 to send Henry off to someone who didn't have the parts needed to do the repair.

Naturally, I disassembled Henry to see if I could notice anything obviously wrong—my concern was that something had just got lodged and was preventing the LiDAR from spinning. Disassembly was straightforward, the only trick being that you have to pry the front cover off with a little bit more force than I'd be comfortable with if I didn't know that was the correct procedure.

![Henry with his top off](/images/2024/henry.webp){:loading="lazy"}

The LiDAR "laser distance sensor" module is the black and orange unit in the centre.
{:class="caption"}

This didn't reveal any obvious failures, but it did give me confidence in replacing the LiDAR unit myself. It's a self-contained slide-in component—you just undo some screws and it disconnects from a single port that connects it to the rest of the vacuum.

Now that I knew what the part looked like, and that doing the replacement would be easy, I found a replacement part on AliExpress for $70 (with shipping included). I don't think I would've trusted the compatibility advertised in the description if I didn't know the shape of the component I was looking for. The shape and screw locations matched, and it would be weird for Roborock to make two seemingly self-contained parts that are physically identical but incompatible in software.

The part arrived after about a week, and it had some subtle differences in the design but not in the overall shape. It turned out the new part was coded `LDS01RR` but the broken one was `LDS02RR`, so perhaps this was made for the S5 originally. I slotted it in, booted the vacuum up (sans top) and it worked perfectly. After putting the top back on, Henry was able to catch up on all the vacuuming he'd missed in the last three weeks.

I'm glad the repair worked so I didn't have to spend money buying a new part *and* shipping Henry off to Roborock. It's not great that this part can seemingly fail spontaneously, I've looked for any blown out components but haven't seen anything. Naturally, I will hoard the old broken part in case the new one fails and I have to Frankenstein them together to get Henry going again.
