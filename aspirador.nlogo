;; Elementos
breed [dirties dirty]
breed [walls wall]
breed [vacuum cleaner]
;; Aspirador
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
;; Variaveis globais uteis
globals [
  stress-results
  valid-corx
  valid-cory
  usable-area
  unoperating
]
;; Inicializado no setup
to setup
  ;; Limpa tela
  clear-all
  ;; Seta os patches
  set-patch-size 16 * zoom / 100
  ;; Inicia o contador X
  let counter pxmin
  ;; Inicializa os vetores em X e Y
  set valid-corx [ ]
  set valid-cory [ ]
  ;; Efetua enquanto o contador nao atingir o maximo
  while [counter <= pxmax]
  [
    ;; Atualiza o X 
    set valid-corx lput counter valid-corx
    ;; Incrementa o contador
    set counter counter + 2
  ]
  ;;S eta o contador Y
  set counter pymin
  ;; Efetua enquanto o contador nao atingir o maximo
  while [counter <= pymax]
  [
    ;; Atualiza o contador
    set valid-cory lput counter valid-cory
    ;; Incrementa o contador
    set counter counter + 2
  ]
  ;; Area utilizada é definida
  set usable-area (length valid-corx * length valid-cory)
  ;; Seta o carro
  set-default-shape vacuum "car"
  ;; Seta o circulo
  set-default-shape dirties "circle"
  ;; Seta o quadrado
  set-default-shape walls "square"
  ;; Seta o quarto com o tamanho das tartarugas
  setup-room
  ask turtles [set size 2.5]
  reset-ticks
  set stress-results 0
end
;; Ao setar o quarto, seta os obstaculos, o aspirador e a sujeira
to setup-room
  ask patches [ set pcolor 9 ]
  setup-obstacles
  setup-dirties
  setup-vacuum one-of valid-corx one-of valid-cory
end
;; Seta os obstaculos 
to setup-obstacles
  ;; Cria na posição determinada
  create-walls round (20 * usable-area / 100) [ setxy one-of valid-corx one-of valid-cory
    ;; Seta a cor preta
    set color black
   ;; Enquanto estiver vazio coloca tartarugas
    while [any? other turtles-here ]
    ;; Seta no X e y
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end
;; Reseta o aspirador, reinicializando as coordenadas
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
;; Seta aspirador
to setup-vacuum [ ?1 ?2 ]
  ;; Cria os aspiradores nas posicoes determinadas
  create-vacuum quant-cleaners [ setxy ?1 ?2
    set heading 90
    set color ((who - 1) * 10) + 15
    ;; Reseta o aspirador
    reset-vacuum
    ;; Enquanto estiver vazio coloca tartarugas
    while [any? other walls-here or any? other vacuum-here]
    ;; Seta no X e y
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end
;; Setas as sujeitas
to setup-dirties
  ;; Cria as sujeiras nas posicoes determinadas
  create-dirties round ((dirty-quant / 100) * (80 * usable-area / 100)) [ setxy one-of valid-corx one-of valid-cory
    ;; Seta a cor preta
    set color 5
    ;; Enquanto estiver vazio coloca tartarugas
    while [ any? other turtles-here ]
    ;; Seta no X e y
    [ setxy one-of valid-corx one-of valid-cory ]
  ]
end
;; Resultados
to re-run
  ;; Roda os resultados
  if ticks > 1 [
    ;; Se não tiver resultado
    ifelse stress-results != 0
    ;;; Seta o resultado por dois
    [ set stress-results ((stress-results + ticks) / 2) ]
    ;; Seta o resultado
    [ set stress-results ticks]
  ]
  ;; Reseta perspectiva
  reset-perspective
  ;; Reseta os movimentos
  reset-ticks
  ;; Limpa o plot
  clear-plot
  ;; Seta os patches
  set-patch-size 16 * zoom / 100
  ;; Inicializa o contador
  let counter 0
  ;; Enquanto o contador for menor que os cleaners 
  while [ counter < quant-cleaners ] [ ask cleaner (counter + count walls + count dirties) [
    ;; Seta xy com o novo valor
    setxy (xcor - ( 2 * curposx )) (ycor - ( 2 * curposy ))
    ;; Reseta o aspirador
    reset-vacuum
    ]
    ;; Incrementa o contador
    set counter counter + 1
  ]
  ;; Seta um naooperacional
  set unoperating 0
  ;; Seta a cor das sujeiras
  ask dirties [ set color 5 ]
end
;; Pega a sujeira
to get-dirty [ ? ]
  ;; Verifica se está limpo
  ask cleaner ? [
    ;;Verifica se tem sujeira
    ask dirties-here [
      ;;Seta a cor
      set color 8
      ;can change deterministic behavior
    ]
    ;; Incrementa o score
    set score score + 1
  ]
end
;; Inicializando
to go
  ;; Seta os componentes
  if not any? dirties with [color = 5] or ticks = 144000 or not any? vacuum or unoperating >= quant-cleaners
  [
    ;; Se o contador do aspirador for maior que um atualiza os cleaner e os scores
    if count vacuum > 1 [      watch item (quant-cleaners - 1) (sort-on [score] vacuum)    ]
    ;; Para
    stop
  ]
  tick
  ;; Inicializa o contador 
  let counter 0
  ;; Enquanto o contador for menor que a quantidade de cleaners
  while [ counter < quant-cleaners ]
  [
    ;; Incrementa contador quantidade de obstaculos e sujeiras
    ask cleaner (counter + count walls + count dirties) [
      ;; Se for igual a zero a desistencia
      if (gave-up-at = 0)[
        ;; Faz a logica de desempenho com score e movimentos
        ifelse ((score / ticks) < (0.25 * dirty-quant / 100))
        and ticks >= round((2 * (1 + percmax-x - percmin-x) * (1 + percmax-y - percmin-y)) + handcap) and not any? dirties-here with [color = 5][
          set gave-up-at ticks
          set unoperating unoperating + 1
        ]
        [
          ;; Verifica se esta vazio e seta a cor
          ifelse any? dirties-here with [color = 5]
          ;; Incrementa contador quantidade de obstaculos e sujeiras
          [ get-dirty (counter + count walls + count dirties) ]
          ;; Se for movimento inteligente
          [ ifelse smart-moves?
            ;; Realiza movimento
            [ ifelse intel-level > 0 and count-possib = 0 [move-smartA (counter + count walls + count dirties) ]
              [move-smart (counter + count walls + count dirties) 1]
            ]
            [move-random (counter + count walls + count dirties) 0]
          ]
        ]
      ]
    ]
    ;; Incrementa contador
    set counter counter + 1
  ]
end
;; Movimento aleatorio
to move-random [ ? ?1 ]
  ;; Verifica se esta limpo
  ask cleaner ? [
    ;; Variaveis uteis
    let max-count 0
    let extraspc 0
    let check-dirties 0
    ;; Verifica posições
    if member? heading [ 45 315 225 135 ]
    [ set extraspc 1 ]
    ;; Enquanto for possivel o movimento
    while [(any? walls-on patch-ahead (2 + extraspc) or any? vacuum-on patch-ahead (2 + extraspc)
      or not (member? ([pxcor] of patch-ahead (2 + extraspc)) valid-corx
        and member? ([pycor] of patch-ahead (2 + extraspc)) valid-cory))
      or (smart-moves? = false and intel-level = 1 and (not any? (dirties-on patch-ahead (2 + extraspc)) with [color = 5] and max-count < 8))
     ]
    [
      ;; Seta posições
      set heading heading - 45
      set extraspc 0
      ;; Verifica posições
      if member? heading [ 45 315 225 135 ]
      [ set extraspc 1 ]
      ;; Incrementa contador
      set max-count max-count + 1
    ]
    ;; Se o contador dor diferente de 0
    if max-count != 4 [
      ifelse max-count != 4 and member? heading [ 0 90 180 270 360 ][
        ;; Move o patch
        move-to patch-ahead 2
        ;; Angulo do movimento
        set curposx curposx + round (sin heading)
        set curposy curposy + round (cos heading)
      ]
      ;; Move o patch
      [
        move-to patch-ahead (2 + extraspc)
        ;; Angulo do movimento
        set curposx curposx + round (sin heading / sin 45)
        set curposy curposy + round (cos heading / sin 45)
      ]
      ;; Verificações de percurso
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
      ;; Se for 1, seta posições
      if ?1 = 0 [
        set heading heading - one-of [45 90 135 180 225 270]
      ]
    ]
  ]
end
;; Mover inteligente
to move-smart [ ? ?1]
  ;; Verifica se esta limpo
  ask cleaner ? [
    ;; Verifica se é menor que 8
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

;; Mover inteligenteA
to move-smartA [ ? ]
  ;; Inicia variaveis uteis
  let counter 0
  let hipposx 0
  let hipposy 0
  let possibW [ ]
  let possib [ ]
  ;; Verifica se esta limpo
  ask cleaner ? [
    ;; Enquanto for menor que 8
    while [ counter < 8 ] [
      let extraspc 0
      ;; 
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
