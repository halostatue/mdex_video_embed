# YouTube Video Embed Examples

This document demonstrates various YouTube embed configurations using
MDExVideoEmbed.

## Local Mode (Click-to-Load with Consent)

### Crosby, Stills, Nash & Young - "Ohio"

```video-embed source=youtube
J9INnMMwvnk
title=Ohio by Crosby, Stills, Nash & Young
autoplay=true
```

### Walk Off the Earth - "Red Hands"

```video-embed source=youtube
1bt-FHaFVH8
title=Red Hands by Walk Off the Earth
```

### Frank Turner - "Photosynthesis"

```video-embed source=youtube
Tm7pZaT9EOs
title=Photosynthesis by Frank Turner
start=15
```

### Childish Gambino - "This Is America"

```video-embed source=youtube
VYOjWnS4cMY
title=This Is America by Childish Gambino
button-text=Watch **{{ title }}**
```

## Embedlite Mode (Direct Embed)

### Fatboy Slim - "Weapon of Choice" (feat. Christopher Walken)

```video-embed source=youtube
wCDIYvFmgW8
title=Weapon of Choice by Fatboy Slim
mode=embedlite
```

### Rage Against the Machine - "Killing in the Name"

```video-embed source=youtube
bWXazVhlyxQ
title=Killing in the Name by Rage Against the Machine
mode=embedlite
start=30
```

## Mixed Modes in One Document

### Crosby, Stills, Nash & Young - "Ohio"

```video-embed source=youtube
J9INnMMwvnk
title=Ohio by Crosby, Stills, Nash & Young
```

### Walk Off the Earth - "Hold On (The Break)"

```video-embed source=youtube
KfW7y_Qk0VY
title=Hold On (The Break) by Walk Off the Earth
mode=embedlite
```

## Advanced Options

### With Custom Button Text and Aria Label

```video-embed source=youtube
1bt-FHaFVH8
title=Red Hands
button-text=▶️ Play {{ title }}
button-aria-label=Start playing {{ title }}
```

### With Start and End Times

```video-embed source=youtube
Tm7pZaT9EOs
title=Frank Turner - Photosynthesis
start=30
end=90
```

### With Controls Hidden

```video-embed source=youtube
VYOjWnS4cMY
title=This Is America
controls=hide
```

### With Autoplay (Embedlite Mode)

```video-embed source=youtube
wCDIYvFmgW8
title=Weapon of Choice
mode=embedlite
autoplay=true
```
