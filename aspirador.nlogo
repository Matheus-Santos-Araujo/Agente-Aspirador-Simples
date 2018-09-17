breed [dirties dirty]
breed [walls wall]
breed [vacuum cleaner]
vacuum-own [
  percmax-x
  percmin-x
  percmax-y
  percmin-y
  refposx
  refposy
  curposx
  curposy
  score
  gave-up-at
  count-possib
  possib-whites
  dir
]
globals [
  stress-results
  valid-corx
  valid-cory
  usable-area
  unoperating
]
to setup
  clear-all
  set-patch-size 16 * zoom / 100
  let counter pxmin
  set valid-corx [ ]
  set valid-cory [ ]
  while [counter <= pxmax]
  [
    set valid-corx lput counter valid-corx
    set counter counter + 2
  ]
  set counter pymin
  while [counter <= pymax]
  [
    set valid-cory lput counter valid-cory
    set counter counter + 2
  ]
  set usable-area (length valid-corx * length valid-cory)
  set-default-shape vacuum "car"
  set-default-shape dirties "circle"
  set-default-shape walls "square"
  setup-room
  ask turtles [set size 2.5]
  reset-ticks
  set stress-results 0
end

to setup-room
  ask patches [ set pcolor 9 ]
  setup-obstacles
  setup-dirties
  setup-vacuum one-of valid-corx one-of valid-cory
end

to setup-obstacles
  create-walls round (20 * usable-area / 100) [ setxy one-of valid-corx one-of valid-cory
    set color black
    while [any? other turtles-here ]
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end
to reset-vacuum
  ask self [
    set heading one-of [ 45 90 135 180 ]
    set heading heading * one-of [ 1 -1 ]
    set curposx 0
    set curposy 0
    set percmax-x 0
    set percmin-x 0
    set percmax-y 0
    set percmin-y 0
    set score 0
    set gave-up-at 0
    set refposx 0
    set refposy 0
    set count-possib 0
    set dir one-of [ 1 -1 ]
    set possib-whites [ ]
  ]
end
to setup-vacuum [ ?1 ?2 ]
  create-vacuum quant-cleaners [ setxy ?1 ?2
    set heading 90
    set color ((who - 1) * 10) + 15
    reset-vacuum
    while [any? other walls-here or any? other vacuum-here]
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end

to setup-dirties
  create-dirties round ((dirty-quant / 100) * (80 * usable-area / 100)) [ setxy one-of valid-corx one-of valid-cory
    set color 5
    while [ any? other turtles-here ]
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end

to re-run
  if ticks > 1 [
    ifelse stress-results != 0
    [ set stress-results ((stress-results + ticks) / 2) ]
    [ set stress-results ticks]
  ]
  reset-perspective
  reset-ticks
  clear-plot
  set-patch-size 16 * zoom / 100
  let counter 0
  while [ counter < quant-cleaners ] [ ask cleaner (counter + count walls + count dirties) [
    setxy (xcor - ( 2 * curposx )) (ycor - ( 2 * curposy ))
    reset-vacuum
    ]
    set counter counter + 1
  ]
  set unoperating 0
  ask dirties [ set color 5 ]
end

to get-dirty [ ? ]
  ask cleaner ? [
    ask dirties-here [
      set color 8
      ;can change deterministic behavior
    ]
    set score score + 1
  ]
end

to go
  if not any? dirties with [color = 5] or ticks = 144000 or not any? vacuum or unoperating >= quant-cleaners
  [
    if count vacuum > 1 [      watch item (quant-cleaners - 1) (sort-on [score] vacuum)    ]
    stop
  ]
  tick
  let counter 0
  while [ counter < quant-cleaners ]
  [
    ask cleaner (counter + count walls + count dirties) [
      if (gave-up-at = 0)[
        ifelse ((score / ticks) < (0.25 * dirty-quant / 100))
        and ticks >= round((2 * (1 + percmax-x - percmin-x) * (1 + percmax-y - percmin-y)) + handcap) and not any? dirties-here with [color = 5][
          set gave-up-at ticks
          set unoperating unoperating + 1
        ]
        [
          ifelse any? dirties-here with [color = 5]
          [ get-dirty (counter + count walls + count dirties) ]
          [ ifelse smart-moves?
            [ ifelse intel-level > 0 and count-possib = 0 [move-smartA (counter + count walls + count dirties) ]
              [move-smart (counter + count walls + count dirties) 1]
            ]
            [move-random (counter + count walls + count dirties) 0]
          ]
        ]
      ]
    ]
    set counter counter + 1
  ]
end

to move-random [ ? ?1 ]
  ask cleaner ? [
    let max-count 0
    let extraspc 0
    let check-dirties 0
    if member? heading [ 45 315 225 135 ]
    [ set extraspc 1 ]
    while [(any? walls-on patch-ahead (2 + extraspc) or any? vacuum-on patch-ahead (2 + extraspc)
      or not (member? ([pxcor] of patch-ahead (2 + extraspc)) valid-corx
        and member? ([pycor] of patch-ahead (2 + extraspc)) valid-cory))
      or (smart-moves? = false and intel-level = 1 and (not any? (dirties-on patch-ahead (2 + extraspc)) with [color = 5] and max-count < 8))
     ]
    [
      set heading heading - 45
      set extraspc 0
      if member? heading [ 45 315 225 135 ]
      [ set extraspc 1 ]
      set max-count max-count + 1
    ]
    if max-count != 4 [
      ifelse max-count != 4 and member? heading [ 0 90 180 270 360 ][
        move-to patch-ahead 2
        set curposx curposx + round (sin heading)
        set curposy curposy + round (cos heading)
      ]
      [
        move-to patch-ahead (2 + extraspc)
        set curposx curposx + round (sin heading / sin 45)
        set curposy curposy + round (cos heading / sin 45)
      ]
      ifelse curposx > percmax-x
              [ set percmax-x curposx ]
      [
        if curposx < percmin-x
        [ set percmin-x curposx ]
      ]
      ifelse curposy > percmax-y
      [ set percmax-y curposy ]
      [
        if curposy < percmin-y
        [ set percmin-y curposy ]
      ]
      if ?1 = 0 [
        set heading heading - one-of [45 90 135 180 225 270]
      ]
    ]
  ]
end

to move-smart [ ? ?1]
  ask cleaner ? [
    ifelse ?1 < 8[
      let extraspc 0
      if member? heading [ 45 315 225 135 ]
      [ set extraspc 1 ]
      ifelse ((any? walls-on patch-ahead (2 + extraspc) or any? vacuum-on patch-ahead (2 + extraspc)
        or not (member? ([pxcor] of patch-ahead (2 + extraspc)) valid-corx
          and member? ([pycor] of patch-ahead (2 + extraspc)) valid-cory))
      or any? (dirties-on patch-ahead (2 + extraspc)) with [color = 8] or not any? turtles-on patch-ahead (2 + extraspc))
      or ((((extraspc = 0 and (curposx + round (sin heading) > refposx + sin heading and curposy + round (cos heading) > refposy + cos heading))
        or (extraspc = 1 and (curposx + round (sin heading / sin 45) > refposx + round (sin heading / sin 45)
          and curposy + round (cos heading / sin 45) > refposy + round (cos heading / sin 45))))) and count-possib > 0)
      [
        set heading heading - 45 * dir
        move-smart ? (?1 + 1)
      ]
      [
        move-random ? 1
        if extraspc = 1 [
          ifelse ?1 = 2 [set heading heading + 90 ]
          [if ?1 = 3 [set heading heading + 180 ]]
        ]
        if count-possib != 0 [
          set count-possib count-possib - 1
        ]
      ]
    ]
    [
      ifelse intel-level > 0 and length possib-whites != 0 [ set heading one-of possib-whites
      move-random ? 1]
      [move-random ? 0]
    ]
  ]
end

to move-smartA [ ? ]
  let counter 0
  let hipposx 0
  let hipposy 0
  let possibW [ ]
  let possib [ ]
  ask cleaner ? [
    while [ counter < 8 ] [
      let extraspc 0
      if member? heading [ 45 315 225 135 ]
      [ set extraspc 1 ]
      if not (any? walls-on patch-ahead (2 + extraspc) or any? vacuum-on patch-ahead (2 + extraspc)
        or not (member? ([pxcor] of patch-ahead (2 + extraspc)) valid-corx
          and member? ([pycor] of patch-ahead (2 + extraspc)) valid-cory))
      [
        ifelse any? (dirties-on patch-ahead (2 + extraspc)) with [color = 8] [set possibW lput heading possibW]
        [set possib lput heading possib
          ifelse extraspc = 0 [
            set hipposx curposx + round (sin heading)
            set hipposy curposy + round (cos heading)
          ]
          [
            set hipposx curposx + round (sin heading / sin 45)
            set hipposy curposy + round (cos heading / sin 45)
          ]
          ifelse hipposx > percmax-x
          [ set percmax-x hipposx ]
          [
            if hipposx < percmin-x
            [ set percmin-x hipposx ]
          ]
          ifelse hipposy > percmax-y
          [ set percmax-y hipposy ]
          [
            if hipposy < percmin-y
            [ set percmin-y hipposy ]
          ]
        ]
      ]
      set heading heading - 45
      set counter counter + 1
    ] ; verifies 8 neighbors
    if ((1 + percmax-x - percmin-x) * (1 + percmax-y - percmin-y)) = 1 and length possibW = 0[
      set gave-up-at ticks
      set unoperating unoperating + 1
    ]
    set count-possib length possib
    set possib-whites possibW
    set refposx curposx
    set refposy curposy
  ]
  move-smart ? 1
end
