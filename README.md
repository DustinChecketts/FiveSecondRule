# FiveSecondRule
A Turtle WoW addon that tracks the five-second rule (FSR or 5SR), mana ticks (MP5), and mana gains for mana-using classes.

This is a simple, lightweight, and elegant addon for TurtleWoW that tracks the "five-second rule" countdown, "ticks", and mana gained (each tick). A small vertical line, or "spark", moves horizontally across the mana bar. When moving right-to-left, it is counting down the "five-second rule". When moving left-to-right, it times each "tick". As each "tick" expires, the amount of mana gained is calculated and displayed to the right of the mana bar and fades out quickly, similar to floating combat text.

<h4>Features</h4>

- Tracks the "five-second-rule"* (FSR or 5SR) countdown as movement right-to-left
- Tracks mana "ticks"** as movement left-to-right
- Simple vertical line or "spark" that moves horizontally (left or right) across the mana bar
- Displays the mana gained each tick to the right of the mana bar as "+50"
- Simple, lightweight, elegant, and compatible with the default UI
- Compatible with Turtle Dragonflight UI

<h4>Acknowledgements</h4>

- Concept taken from [FiveSecondRule](https://github.com/smp4903/FiveSecondRule) by [smp4903](https://github.com/smp4903), but all code is my own

<h4>Known-Issues/ToDo</h4>

- Thorough testing across all classes still needed.
- Extend the addon to support Rage and Energy timings.
- If the map is resized, the "spark" and mana gain elements can appear atop the map strata.

Updated, uploaded, and maintained by [StormtrooperTK421](https://discordapp.com/users/237746068844969994) on [GitHub](https://github.com/DustinChecketts/FiveSecondRule).
Please submit issues and I'll do my best to troubleshoot, replicate, and resolve issues as my limited abilities allow.

<h4>Vocabulary</h4>

- *The "five-second-rule" refers to the necessary time to elapse after spending mana before mana regeneration will resume.
- **A "tick" is a measure of time used for over-time effects. Mana regeneration uses 2-second "ticks".
