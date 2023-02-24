toupeiras-own [elapsed-time health]
planta-relvas-own [stock]
breed [planta-relvas planta-relva]
breed [toupeiras toupeira]

to setup
  clean_field
  create-planta-relvas 1 [
    if Modo_de_Plantar = "Serpentina" [ set heading 0 ]
    if Modo_de_Plantar = "Para a frente" [ set heading one-of [0 90 180 270] ]
    set size 2.5
    set shape "agricultor"
    set stock world-width * world-height ; o necessário para plantar o campo todo
  ]

  create-turtles 1 [
    setxy 1 1
    set size 2.5
    set shape "grass-restocker"
  ]

  reset-ticks
end

to plantar
  ask planta-relvas [
    set label stock
    set label-color black

    if Modo_de_Plantar = "Para a frente" [
      if not (any? patches with [pcolor = brown]) [
        set Modo_de_Plantar "Manutenção"
        stop
      ]

      ask patch-here [ set pcolor green ]
      set stock stock - 1
      if [pcolor] of patch-ahead 1 = green [ right 90 ]
      forward 1
    ]

    if Modo_de_Plantar = "Serpentina" [
      if not (any? patches with [pcolor = brown]) [
        set Modo_de_Plantar "Manutenção"
        stop
      ]

      ask patch-here [ set pcolor green ]
      set stock stock - 1

      if xcor = max-pxcor and ycor = max-pycor [ stop ]

      if heading = 0 and ycor = max-pycor [
        right 90
        forward 1
        ask patch-here [ set pcolor green ]
        set stock stock - 1
        right 90
      ]

      if heading = 180 and ycor = 0 [
        left 90
        forward 1
        ask patch-here [ set pcolor green ]
        set stock stock - 1
        left 90
      ]

      forward 1
    ]

    if Modo_de_Plantar = "Manutenção" [
      ; atividade das toupeiras
      ask toupeiras [
        set label health
        set label-color black
        set elapsed-time elapsed-time + 1

        if any? planta-relvas-here [ die ]

        ifelse [pcolor] of patch-here = green [
            ask patch-here [ set pcolor brown ]

            ifelse health <= 90 [ set health health + 5 ]
            [ set health 100 ]
        ]
        [ set health health - 1 ]

          if health = 0 [ die ]

        if prob Prob_toupeira [
          if count toupeiras-here = 2 and elapsed-time >= default-time [
            hatch 1 [
              set heading random 360
              set elapsed-time 0
            ]
            set elapsed-time 0
          ]

          let it 0
          while [it < max-iter and not(any? toupeiras-on patch-ahead 1)
            and [pcolor] of patch-ahead 1 = brown] [
            set it it + 1
            set heading random 360
          ]
          forward 1
        ]
      ]
    ; atividade do planta-relva

      ask toupeiras-here [ die ]

      ifelse stock = 0 [
        facexy 1 1
        forward 1
        if count turtles-here with [shape = "grass-restocker"] = 1
        [ set stock int (world-width * world-height / 3) ]
      ]
      [ if [pcolor] of patch-here = brown [
          set pcolor green
          set stock stock - 1
        ]

        let it2 0
        while [it2 < max-iter and not(any? toupeiras-on patch-ahead 1)
          and [pcolor] of patch-ahead 1 = green] [
          set it2 it2 + 1
          set heading random 360
        ]
        forward 1
      ]
    ]
  ]
  tick
end

to insere_toupeira
  create-toupeiras 1 [
    setxy random-xcor random-ycor
    set heading random 360
    set size 2
    set shape "toupeira"
    set color 32
    set elapsed-time default-time
    set health 100
  ]
end

to-report prob[x]
  report (random-float 1 < x)
end

to clean_field
  clear-all
  ask patches [ set pcolor brown ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
0
32
0
32
1
1
1
ticks
30.0

BUTTON
21
77
181
110
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
236
184
269
Limpar Campo
clean_field
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
21
129
182
162
Plantar
plantar
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
23
16
181
61
Modo_de_Plantar
Modo_de_Plantar
"Para a frente" "Serpentina" "Manutenção"
2

BUTTON
21
181
184
214
Inserir toupeira
insere_toupeira
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
21
298
184
331
Prob_toupeira
Prob_toupeira
0
1
0.2
0.1
1
NIL
HORIZONTAL

MONITOR
657
330
870
375
Toupeiras
count toupeiras
17
1
11

MONITOR
657
26
858
71
Terreno Plantado
count patches with [pcolor = green]
17
1
11

PLOT
659
400
972
608
População de toupeiras
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot count toupeiras"

PLOT
657
92
964
307
Terreno plantado
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "plot count patches with [pcolor = green]"

SLIDER
18
355
184
388
default-time
default-time
10
100
50.0
10
1
ticks
HORIZONTAL

SLIDER
18
412
184
445
max-iter
max-iter
1
20
2.0
1
1
testes
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

agricultor
true
14
Polygon -2064490 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -2064490 true false 110 5 80
Rectangle -2064490 true false 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -1184463 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -7500403 false 225 90 270 90
Line -7500403 false 225 15 225 90
Line -7500403 false 270 15 270 90
Line -7500403 false 247 15 247 90
Rectangle -7500403 true false 240 90 255 300

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant 2
true
0
Polygon -13345367 true false 150 19 120 30 120 45 130 66 144 81 127 96 129 113 144 134 136 185 121 195 114 217 120 255 135 270 165 270 180 255 188 218 181 195 165 184 157 134 170 115 173 95 156 81 171 66 181 42 180 30
Polygon -13791810 true false 150 167 159 185 190 182 225 212 255 257 240 212 200 170 154 172
Polygon -13791810 true false 161 167 201 150 237 149 281 182 245 140 202 137 158 154
Polygon -13791810 true false 155 135 185 120 230 105 275 75 233 115 201 124 155 150
Line -11221820 false 120 36 75 45
Line -11221820 false 75 45 90 15
Line -11221820 false 180 35 225 45
Line -11221820 false 225 45 210 15
Polygon -13791810 true false 145 135 115 120 70 105 25 75 67 115 99 124 145 150
Polygon -13791810 true false 139 167 99 150 63 149 19 182 55 140 98 137 142 154
Polygon -13791810 true false 150 167 141 185 110 182 75 212 45 257 60 212 100 170 146 172

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

grass-restocker
false
0
Polygon -16777216 true false 150 285 270 225 270 90 150 150
Polygon -6459832 true false 150 150 30 90 150 30 270 90
Polygon -16777216 true false 30 90 30 225 150 285 150 150
Line -1 false 150 150 150 285
Line -1 false 150 285 30 225
Line -1 false 30 225 30 90
Line -1 false 30 90 150 150
Line -1 false 150 150 270 90
Line -1 false 270 90 270 225
Line -1 false 270 225 150 285
Line -1 false 270 90 150 30
Line -1 false 150 30 30 90
Polygon -6459832 true false 105 120
Polygon -14835848 true false 105 120 45 60 60 30 75 75 90 15 105 75 120 15 135 75 150 45 165 75 180 30 195 45 225 30 195 75 240 60 210 90 240 90 195 120 150 135 105 120

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

rabbit
true
0
Polygon -1 true false 61 150 76 180 91 195 103 214 91 240 76 255 61 270 76 270 106 255 132 209 151 210 181 210 211 240 196 255 181 255 166 247 151 255 166 270 211 270 241 255 240 210 270 225 285 165 256 135 226 105 166 90 91 105
Polygon -1 true false 75 164 94 104 70 82 45 89 19 104 4 149 19 164 37 162 59 153
Polygon -1 true false 64 98 96 87 138 26 130 15 97 36 54 86
Polygon -1 true false 49 89 57 47 78 4 89 20 70 88
Circle -2674135 true false 37 103 16
Line -16777216 false 44 150 104 150
Line -16777216 false 39 158 84 175
Line -16777216 false 29 159 57 195
Polygon -2064490 true false 0 150 15 165 15 150
Polygon -2064490 true false 76 90 97 47 130 32
Line -16777216 false 180 210 165 180
Line -16777216 false 165 180 180 165
Line -16777216 false 180 165 225 165
Line -16777216 false 180 210 210 240

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

toupeira
true
0
Polygon -2064490 true false 90 255 60 270 75 255 60 255 75 240 60 240 75 225 60 210 90 225 105 255 90 255
Polygon -2064490 true false 90 75 60 60 75 75 60 75 75 90 60 90 75 105 60 120 90 105 105 75 90 75
Polygon -2064490 true false 210 255 240 270 225 255 240 255 225 240 240 240 225 225 240 210 210 225 195 255 210 255
Polygon -2064490 true false 210 75 240 60 225 75 240 75 225 90 240 90 225 105 240 120 210 105 195 75 210 75
Polygon -2064490 true false 150 15 180 45 150 15 135 30 120 45 180 45 165 30 150 15 150 30
Circle -7500403 true true 75 120 150
Circle -7500403 true true 90 30 120
Polygon -7500403 true true 90 90 75 180 105 135 120 135 90 90
Polygon -7500403 true true 75 180 75 195 90 180 90 165 90 150 75 180
Polygon -7500403 true true 210 90 225 195 165 150 210 90
Polygon -7500403 true true 90 120 90 105 90 75 105 75
Polygon -7500403 true true 210 120 210 105 210 75 195 75
Polygon -7500403 true true 105 255 90 255 90 225
Polygon -7500403 true true 135 255 150 300 165 255
Polygon -7500403 true true 195 255 210 255 210 225
Polygon -7500403 true true 105 255 90 255 90 225

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -1184463 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -1184463 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -1184463 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -1184463 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -1184463 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
