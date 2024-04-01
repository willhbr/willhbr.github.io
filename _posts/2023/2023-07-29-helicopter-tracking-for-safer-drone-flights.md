---
title: "Helicopter Tracking for Safer Drone Flights"
image: /images/2023/dronemapsample.jpeg
tags: projects photography
---

Avid readers will know that I like to fly [my drone](/2023/06/11/dji-mini-3-pro/) around the beaches in Sydney. The airspace is fairly heavily trafficked, and so I take [the drone rules](https://www.casa.gov.au/knowyourdrone) very seriously. This means no flying in restricted airspace (leading to [other solutions for getting photos in these areas](https://youtu.be/gflq7LcE65I)), no flying in airport departure or arrival paths, and no flying above the 120m ceiling (or 90m in certain areas). This is easily tracked with a drone safety app (I'm a big fan of [ok2fly](https://ok2fly.com.au)).

What is more difficult is flying a drone in an area that may have other aircraft nearby. The [drone rules state](https://www.casa.gov.au/knowyourdrone/drone-rules):

> If you're near a helicopter landing site or smaller aerodrome without a control tower, you can fly your drone within 5.5 kilometres. If you become aware of manned aircraft nearby, you must manoeuvre away and land your drone as quickly and safely as possible.

This basically means that if a helicopter turns up, you should get the drone as low as possible and land as quickly as possible. In theory, crewed aircraft should be above 150m (500ft), with a 30m (100ft) vertical gap between them and the highest drones. However on the occasions where there have been helicopters passing by, to my eye they seem to be much closer than that, which makes me anxious—I want my drone to remain well clear of any helicopters.

Virtually all aircraft carry an [ADS-B transmitter][adsb] which broadcasts their GPS location to nearby planes and ground stations. They use this location to avoid running into each other, especially in low-visibility conditions. Flight-tracking services like [flightradar24](http://flightradar24.com) aggregate this data globally and present it on a map.

[adsb]: https://en.wikipedia.org/wiki/Automatic_Dependent_Surveillance–Broadcast

My first idea was to write an app that would stream the ADS-B data from a service like flightradar24 for any aircraft in the nearby airspace, and sound an alert if an aircraft was on a trajectory that would intersect with my location. This would be great, but it would be a lot of work, require some kind of API key and agreement from the data provider, and ongoing use would require paying the annual $99USD/$150AUD Apple developer program fee.[^no-sideload]

[^no-sideload]: I could install it on my phone with a free developer account, but that requires re-installing the app from Xcode every week.

![a drone photo of waves coming in to a beach](https://pics.willhbr.net/photos/2023-06-17.jpeg){:loading="lazy"}
{:class="small-img"}

I realise that I'm a few paragraphs into a post about drone photography and haven't included a drone photo yet. Here you go.
{:class="caption"}

The next best idea was to setup a [_Stratux_](https://stratux.co) ADS-B receiver using a Raspberry Pi. This would either allow me to pull data from it to my phone (no need to deal with API keys and suchlike) or do all the processing on the Pi (no need to deal with developer restrictions). While this would have been cool, it would have also cost a bit to get all the components, and working out some kind of interface to an otherwise-headless RPi seemed like a frustrating challenge.

After considering these two options for a while I settled on a completely different third option. Instead of building something to alert me in real time, I could just work out which beaches would have nearby aircraft at what times of day, and avoid flying during those times. This is when I came across the [_OpenSky Network_][opensky], a network of ADS-B receivers that provides free access to aircraft locations for research purposes. So all I had to do was get the data from Opensky for aircraft in Sydney, and then visualise it to understand the flight patterns around the beaches.

[opensky]: https://opensky-network.org

Opensky has a [historical API](https://opensky-network.org/data/impala) with an SQL-like query interface, as well as a [live API](https://openskynetwork.github.io/opensky-api/) with a JSON REST interface. I requested access to the historical data, but was informed that they only provide access to research institutions due to the cost of querying it. So to make do I wrote a simple program that would periodically fetch the positions of aircraft within the Sydney area. This data was then saved to a local SQLite database so I could query it again later. Since the drone rules also forbid flights during the night, I only needed to fetch data during civil daylight hours.

To visualise the data, I used my hackathon-approved map rendering solution: get a screenshot of Open Street Map and naively transform latitude/longitudes to x/y coordinates. After messing up the calculation a bunch, I got a map with a line for every flight, which looked something like this:

![map of Sydney Harbour showing many paths taken by aircraft over the harbour](/images/2023/dronemapsample.jpeg){:loading="lazy"}

Eventually after staring at this map[^not-this-map] for a long time, I realised that most helicopter (or _rotorcraft_ as they are referred to in the API) routes went from north from the airport, passed along the western side of the city, directly over the Harbour Bridge, did a few loops over the harbour (as seen in the map above), exited the harbour by Watson's Bay, then turned south and hugged the coastline along the beaches, before finally turning west at Maroubra to get back to the airport.

[^not-this-map]: Well not _this_ map, the full-size map with way more lines on it.

I finally had the realisation that probably should have been fairly obvious a long time before this—all these helicopters are tourist flights, repeating the same route over and over again. Sure enough if I search for "helicopter sight seeing Sydney" I find the website for a helicopter tour company that does the exact route I saw plastered over my map. Optimistically I emailed them asking how many flights they usually flew in a day, and what time their earliest flight was—this would give me enough information to make a reasonably informed decision about when was best to fly my drone. Sadly they said they couldn't share this information with me.

Ok so I would have to do some more data visualisation to work this out for myself. First of all I filtered out any data points that were above 200 metres, since they would be well clear of any drones.

![map of Sydney and beaches from the southern head of the harbour down to Cronulla, including Botany Bay](/images/2023/dronesallbeaches.jpeg){:loading="lazy"}

There are some interesting things in this map:

- The arrival and departure paths for commercial aircraft are _very_ accurate.
- Helicopters arrive and depart from the eastern part of the airport.
- Rose Bay is where a lot of seaplanes take off from, so you can see tracks starting and stopping there.
- By far the densest route is between Bondi and Maroubra, hugging the coast.
- Planes flying the [_Victor 1_ VFR route][victor-1] are further from the coast.
- There's obviously a strict route for aircraft flying over the inner harbour (west of the bridge) creating an aerial highway.

[victor-1]: https://wanderwisdom.com/travel-destinations/How-to-Create-a-Navigation-Plan-for-a-VFR-flight

I then compared that with the same view over the northern beaches:

![map of Sydney's northern beaches, from the harbour entrance up to Barrenjoey head](/images/2023/dronesnorthernbeaches.jpeg){:loading="lazy"}

It's worth noting that all the maps contain data for just over one month of flights. There is definitely still a large number of flights going up the coast, but they thin out significantly as you get further north, especially past Long Reef—the headland south of Collaroy beach. I was surprised to see that no aircraft fly over the harbour side of Manly, they instead follow the water out the harbour entrance.

A friend suggested a nice way of visualising the data: plot the time of day on one axis, and the position down the coast on the other, and create a heatmap of the highly-trafficked times/areas. In theory you should be able to see a line for each flight flying down the coast. Sadly my `matplotlib` skills aren't that good, so this is the best I could come up with:

![histogram of latitude to time in the day](/images/2023/dronehistogram.png){:loading="lazy"}

The left axis is the latitude (limited in range from Bondi to Maroubra) and the bottom axis is the fraction of the day (eg 0.5 is midday). Using this we can see that the bulk of flights start at 0.4, which is 9.6 hours into the day, or 9:36 AM. Which makes sense for tourist flights, since passengers presumably have to sign some waivers and do a safety briefing, and they're not going to want to get out of bed too early. I added the ability on my map to filter out flights past a certain time of day, and sure enough if I only look at flights before 10:00am, the sky is much clearer.

Armed with this new knowledge, I can make some more informed decisions about when to fly my drone around the beaches in Sydney. I'm just not going to bother flying during the middle of the day anywhere between Bondi and Maroubra, if I want to fly there I'll do it just after sunrise—which will give me better light[^worse-sleep] anyway. Flying in the further north beaches is still an option, but I will still want to position myself somewhere with a good view up and down the coast to see other aircraft coming. Since the flight paths are much more predictable than I had expected, if I did make some kind of alerting system, I could simply trigger whenever an aircraft exited the harbour, since their next move is likely to be up or down the coast.

[^worse-sleep]: Although it will give me worse sleep.

Of course the most important thing—and the lesson I hope you take away from this—is to follow the rules, always check airspace restrictions before flying, be aware of your surroundings, and if in doubt just descend and land as promptly as possible. Don't use a few map screenshots from someone's blog as guidance on where to fly your drone.

---

Map data &copy; [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.

Flight data from [OpenSky][opensky]:

> Bringing up OpenSky: A large-scale ADS-B sensor network for research
> Matthias Schäfer, Martin Strohmeier, Vincent Lenders, Ivan Martinovic, Matthias Wilhelm
> ACM/IEEE International Conference on Information Processing in Sensor Networks, April 2014
