;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Creating Intelligent Agents                        ;;
;; Dale K. Brearcliffe and Andrew Crooks              ;;
;; Copyright 2020                                     ;;
;; This work is licensed under a Creative Commons     ;;
;; Attribution-NonCommercial-ShareAlike 3.0 License.  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [ matrix ] ;; the matrix extension is used to hold the Q values
                      ;; this could have been done with lists, but matrices are what found in literature

breed [ group-A agent-A ] ;; two generic groups are used
breed [ group-B agent-B ]

globals [
  max-actions        ;; the Maximum number of actions that can be taken
  max-states         ;; the Maximum number of states an agent can be in
  max-ticks          ;; the Maximum number of ticks at which the simulaton will halt
  learning-rate      ;; the Learning Rate (0, 1] - larger number means faster learning
  gamma              ;; the Discount Rate (0, 1] - larger numer means look farther into future
  learning-period    ;; the range in ticks that defines an agent's period for trying new actions
  combat-agent-A-die ;; running sum of Group A combat deaths
  combat-agent-B-die ;; running sum of Group B combat deaths
  starve-agent-A-die ;; running sum of Group A starvation deaths
  starve-agent-B-die ;; running sum of Group B starvation deaths
  starting
]

turtles-own [
  sugar          ;; the amount of sugar this turtle has
  metabolism     ;; the amount of sugar that each turtles loses each tick
  vision         ;; the distance that this turtle can see in the horizontal and vertical directions
  vision-points  ;; the points that this turtle can see in relative to it's current position (based on vision)
  q-values       ;; the table of Q-Values
  epsilon        ;; the rate of Exploration
  state          ;; the current state of the agent
  action         ;; the current action of the agent
  age            ;; the number of ticks an agents has existed
]

patches-own [
  psugar     ;; the amount of sugar on a patch
  max-psugar ;; the maximum amount of sugar that can be on a patch
]

;;
;; Setup Procedures
;;

to setup
  clear-all
  random-seed new-seed
  ;;random-seed 1313
  set max-actions 4
  set max-states 3
  set max-ticks 20000
  set combat-agent-A-die 0
  set combat-agent-B-die 0
  set starve-agent-A-die 0
  set starve-agent-B-die 0
  set-default-shape group-A "circle"
  set-default-shape group-B "square"
  create-group-A initial-population [ agent-A-setup ]
  create-group-B initial-population [ agent-B-setup ]
  setup-patches
  set starting 0
  ;;hyper parameters
  set learning-rate 0.9
  set gamma 0.8
  set learning-period 10000
  ;;end hyper parametters
  reset-ticks
end

;; turtle procedure
;; commonly used items in initializing a turtle
to common-setup
  ;; States
  ;;  0: No Contact
  ;;  1: group is weak
  ;;  2: group is strong
  ;; Actions
  ;;  0: Stay
  ;;  1: Jump
  ;;  2: Retreat
  ;;  3: Attack
  set q-values matrix:make-constant max-states max-actions 0 ;; States versus Actions
  set epsilon 1.0
  set state -1
  set action -1
  set age 0
  set sugar random-in-range 5 25
  set metabolism random-in-range 1 4
  set vision random-in-range 1 6
  ;; turtles can look horizontally and vertically up to vision patches
  ;; but cannot look diagonally at all
  set vision-points []
  foreach (range 1 (vision + 1)) [ n ->
    set vision-points sentence vision-points (list (list 0 n) (list n 0) (list 0 (- n)) (list (- n) 0))
  ]
end

;; setup procedure
to agent-A-setup
  common-setup
  set color blue
  ifelse corner-start [
    move-to one-of patches with [not any? other turtles-here and pxcor < 21 and pycor < 21 ]
  ][
    move-to one-of patches with [not any? other turtles-here]
  ]
  run visualization
end

;; setup procedure
to agent-B-setup
  common-setup
  set color red
  ifelse corner-start [
    move-to one-of patches with [not any? other turtles-here and pxcor > 28 and pycor > 28 ]
  ][
    move-to one-of patches with [not any? other turtles-here ]
  ]
  run visualization
end

;; setup procedure
;; original code - create map from text file
to setup-patches
  file-open "symmetric-sugar-map.txt"
  foreach sort patches [ p ->
    ask p [
      set max-psugar file-read
      set psugar max-psugar
      patch-recolor
    ]
  ]
  file-close
end

;;
;; Runtime Procedures
;;

;; Main procedure
to go
  if starting = 0 [set starting 1 print sentence "Start: " date-and-time ]
  ;; is everyone in a breed dead? :(
  if not any? group-A or not any? group-B [
    print sentence "  End: " date-and-time
    stop
  ]
  ;; maximum amount of simulation time has been reached
  if ticks = max-ticks [ print sentence "  End: " date-and-time stop]
  ;; do patch stuff
  ask patches [
    patch-growback
    patch-recolor
  ]
  ;; do turtle stuff
  ask turtles [
    set age age + 1
    ;; do all Group A actions
    if breed = group-A [
      if group-A-action = "Q-Learning" [ turtle-learn-q ]
      if group-A-action = "SARSA" [ turtle-learn-s ]
      ;; evolutionary computing does not include staying in place
      if group-A-action = "EC" [
        ifelse combat [
          let enemy-check-action enemy-check
          if enemy-check-action = 2 [ turtle-attack ]
          if enemy-check-action = 1 [ turtle-retreat ]
          if enemy-check-action = 0 [ turtle-jump ]
        ][
          turtle-jump
        ]
      ]
      ;; without combat, this is the original action for Sugarscape
      if group-A-action = "Rule M" [
        ifelse combat [
          ifelse enemy-check = 2 [
            turtle-attack
          ][
            turtle-jump
          ]
        ][
          turtle-jump
        ]
      ]
    ]
    ;; do all Group B actions
    if breed = group-B [
      if group-B-action = "Q-Learning" [ turtle-learn-q ]
      if group-B-action = "SARSA" [ turtle-learn-s ]
      ;; evolutionary computing does not include staying in place
      if group-B-action = "EC" [
        ifelse combat [
          let enemy-check-action enemy-check
          if enemy-check-action = 2 [ turtle-attack ]
          if enemy-check-action = 1 [ turtle-retreat ]
          if enemy-check-action = 0 [ turtle-jump ]
        ][
          turtle-jump
        ]
      ]
      ;; without combat, this is the original action for Sugarscape
      if group-B-action = "Rule M" [
        ifelse combat [
          ifelse enemy-check = 2 [
            turtle-attack
          ][
            turtle-jump
          ]
        ][
          turtle-jump
        ]
      ]
    ]
    ;; feed the turtle
    turtle-eat
    ;; starved turtles die here
    if sugar <= 0
      [ if breed = group-A [ set starve-agent-A-die (starve-agent-A-die + 1) ]
        if breed = group-B [ set starve-agent-B-die (starve-agent-B-die + 1) ]
        die
    ]
    ;; if the replace dead turtle option is active then bring population back to the initial population level
    if replace-dead = true [
      if (count group-A) < initial-population [
        hatch-group-A (initial-population - count group-A) [
          ;; setup use same values as initial
          set q-values matrix:make-constant max-states max-actions 0 ;; States versus Actions
          set epsilon 1.0
          set state -1
          set action -1
          set color blue
          set age 0
          set sugar random-in-range 5 25
          set metabolism random-in-range 1 4
          set vision random-in-range 1 6
          ;; if evolutionary computing then do a cross over between two existing agents with the highest sugar
          if group-A-action = "EC" [
            ;; find the two "parents" and build lists of vision and metabolism
            ;; this will reset vision and metablism values
            let parent-vision []
            let parent-metabolism []
            ask max-n-of 2 group-A [ sugar ] [
              set parent-vision insert-item 0 parent-vision vision
              set parent-metabolism insert-item 0 parent-metabolism metabolism
            ]
            ;; randomly select 1 "gene" for each
            ;; this matches rule from Table III-1, Growing Artificial Societies
            set vision item random 2 parent-vision
            set metabolism item random 2 parent-metabolism
          ]
          set vision-points []
          foreach (range 1 (vision + 1)) [ n ->
            set vision-points sentence vision-points (list (list 0 n) (list n 0) (list 0 (- n)) (list (- n) 0))
          ]
          ;; either start in a corner or somewhere in the entire grid
          ifelse corner-start [
            ifelse one-of patches with [ not any? other turtles-here and pxcor < 21 and pycor < 21 ] != nobody [
              move-to one-of patches with [ not any? other turtles-here and pxcor < 21 and pycor < 21 ]
            ][
              move-to one-of patches with [ not any? other turtles-here ]
            ]
          ][
            move-to one-of patches with [ not any? other turtles-here ]
          ]
        ]
      ]
      if (count group-B) < initial-population [
        hatch-group-B (initial-population - count group-B) [
          ;; setup use same values as initial
          set q-values matrix:make-constant max-states max-actions 0 ;; States versus Actions
          set epsilon 1.0
          set state -1
          set action -1
          set color red
          set age 0
          set sugar random-in-range 5 25
          set metabolism random-in-range 1 4
          set vision random-in-range 1 6
          ;; if evolutionary computing then do a cross over between two existing agents with the highest sugar
          if group-B-action = "EC" [
            ;; find the two "parents" and build lists of vision and metabolism
            ;; this will reset vision and metablism values
            let parent-vision []
            let parent-metabolism []
            ask max-n-of 2 group-B [ sugar ] [
              set parent-vision insert-item 0 parent-vision vision
              set parent-metabolism insert-item 0 parent-metabolism metabolism
            ]
            ;; randomly select 1 "gene" for each
            ;; this matches rule from Table III-1, Growing Artificial Societies
            set vision item random 2 parent-vision
            set metabolism item random 2 parent-metabolism
          ]
          set vision-points []
          foreach (range 1 (vision + 1)) [ n ->
            set vision-points sentence vision-points (list (list 0 n) (list n 0) (list 0 (- n)) (list (- n) 0))
          ]
          ;; either start in a corner or somewhere in the entire grid
          ifelse corner-start [
            ifelse one-of patches with [ not any? other turtles-here and pxcor > 28 and pycor > 28 ] != nobody [
              move-to one-of patches with [ not any? other turtles-here and pxcor > 28 and pycor > 28 ]
            ][
              move-to one-of patches with [ not any? other turtles-here ]
            ]
          ][
            move-to one-of patches with [ not any? other turtles-here ]
          ]
        ]
      ]
    ]
    run visualization
  ]
  tick
end

;; turtle procedure
;; rule M - consider moving to unoccupied patches within vision
to turtle-jump
  let move-candidates (patch-set (patches at-points vision-points) with [ not any? turtles-here ])
  let possible-winners move-candidates with-max [ psugar ]
  if any? possible-winners [
    move-to min-one-of possible-winners [ distance myself ] ;; if there are any such patches move to one of the patches that is closest
  ]
end

;; turtle procedure
;; attack an enemy
to turtle-attack
  ;; consider moving to occupied patches in our vision with an enemy breed
  let move-candidates []
  if breed = group-A [
    set move-candidates (patch-set (patches at-points vision-points) with [ any? group-B-here ])
  ]
  if breed = group-B [
    set move-candidates (patch-set (patches at-points vision-points) with [ any? group-A-here ])
  ]
  let possible-winners move-candidates with-max [ psugar ] ;; if multiple candidates, one is picked at random
  if any? possible-winners [
    move-to min-one-of possible-winners [ distance myself ] ;; if there are any such patches move to one of the patches that is closest
  ]
  ;; find out who the other breed is and kill it
  if breed = group-A and any? group-B-here [
    ask group-B-here [ die ]
    set sugar sugar + max-psugar ;; give the agent a boost for winning
    set combat-agent-B-die (combat-agent-B-die + 1)
  ]
  if breed = group-B and any? group-A-here [
    ask group-A-here [ die ]
    set sugar sugar + max-psugar ;; give the agent a boost for winning
    set combat-agent-A-die (combat-agent-A-die + 1)
  ]
end

;; turtle procedure
;; retreat! - Bug out and teleport back to their corner
to turtle-retreat
  if breed = group-A [ move-to one-of patches with [ not any? other turtles-here and pxcor < 21 and pycor < 21 ] ]
  if breed = group-B [ move-to one-of patches with [ not any? other turtles-here and pxcor > 28 and pycor > 28 ] ]
end

;; turtle procedure
;; Q-Learning
to turtle-learn-q
  ;; Based on:
  ;;  Sutton & Barto Book (2018) Reinforcement Learning: An Introduction - http://incompleteideas.net/book/the-book-2nd.html
  ;;  David Silver Lecture #4 (2015) - https://www.youtube.com/watch?v=PnHCvfgC_ZA
  ;;  Madhu Sanjeevi Blog (2018) - https://medium.com/deep-math-machine-learning-ai/ch-12-1-model-free-reinforcement-learning-algorithms-monte-carlo-sarsa-q-learning-65267cb8d1b4

  ;; Determine current state
  set state enemy-check

  ;; Detemine current action using naive epsilon-greedy degradation
  set epsilon explore-probability age

  let action-probability get-action_epsilon-greedy state epsilon
  set action choose-action action-probability

  ;; Take current action
  ;; if action = 0 then do nothing
  if action = 1 [ turtle-jump ]    ;; Rule M
  if action = 2 [ turtle-retreat ] ;; Retreat
  if action = 3 [ turtle-attack ]  ;; Attack

  ;; Observe reward and new state
  let reward get-reward state action
  let new-state enemy-check

  ;; Update Q-Table for Q-Learning
  let next-action first argMax matrix:get-row q-values new-state
  let target-td reward + gamma * get-qvalue new-state next-action
  let error-td target-td - get-qvalue state action
  set-qvalue state action (get-qvalue state action) + learning-rate * error-td
  set state new-state
end

;; turtle procedure
;; SARSA Learning
to turtle-learn-s
  ;; Based on:
  ;;  Sutton & Barto Book (2018) Reinforcement Learning: An Introduction - http://incompleteideas.net/book/the-book-2nd.html
  ;;  David Silver Lecture #4 (2015) - https://www.youtube.com/watch?v=PnHCvfgC_ZA
  ;;  Madhu Sanjeevi Blog (2018) - https://medium.com/deep-math-machine-learning-ai/ch-12-1-model-free-reinforcement-learning-algorithms-monte-carlo-sarsa-q-learning-65267cb8d1b4

  ;; Determine current state
  set state enemy-check

  ;; Detemine current action using naive epsilon-greedy degradation
  set epsilon explore-probability age

  ;; next block runs only the first time for a new agent
  if action < 0 [
    let action-probability get-action_epsilon-greedy state epsilon
    set action choose-action action-probability
  ]

  ;; Take current action
  ;; if action = 0 then do nothing
  if action = 1 [ turtle-jump ]    ;; Rule M
  if action = 2 [ turtle-retreat ] ;; Retreat
  if action = 3 [ turtle-attack ]  ;; Attack

  ;; Observe reward and new state
  let reward get-reward state action
  ;;print sentence "State:  " state
  ;;print sentence "Action: " action
  ;;print sentence "Reward: " reward
  let new-state enemy-check
  ;;print sentence "Action2: " action
  ;; Update Q-Table for SARSA-Learning
  let action-probability-new-state get-action_epsilon-greedy new-state epsilon
  ;;print sentence "Action3: " action
  let next-action choose-action action-probability-new-state
  ;;print sentence "Action4: " action
  let target-td reward + gamma * get-qvalue new-state next-action
  ;;print sentence "Tgt-TD:  " target-td
  let error-td target-td - get-qvalue state action
  ;;print sentence "Err-TD:  " error-td
  ;;print sentence "Action6: " action
  ;;print sentence "New QV: " ((get-qvalue state action) + learning-rate * error-td)
  set-qvalue state action ((get-qvalue state action) + learning-rate * error-td)
  ;;show matrix:pretty-print-text q-values

  set state new-state
  set action next-action
end

;; turtle procedure
;; original code - metabolize some sugar, and eat all the sugar on the current patch
to turtle-eat
  set sugar (sugar - metabolism + psugar)
  set psugar 0
end

;; patch procedure
;; original code - color patches based on the amount of sugar they have
to patch-recolor
  set pcolor (yellow + 4.9 - psugar)
end

;; patch procedure
;; gradually grow back all of the sugar for the patch
to patch-growback
  set psugar min (list max-psugar (psugar + sugar-growback-rate))
end

;;
;; Utilities
;;

;; turtle procedure
;; return probability of exploration
to-report explore-probability [ an-age ]
  let prob 1 / (1 + exp ( (an-age - (learning-period / 2) ) / 1000 ) )
  if prob < 0.05 [ set prob 0.05 ]
  report prob
end

;; turtle procedure
;; original code - find random integer within numeric range
to-report random-in-range [ low high ]
  report low + random (high - low + 1)
end

;; turtle procedure
;; return a state based on the number of friendlies and enemies in vision range
to-report enemy-check
  let nearby-group-A count group-A-on (patch-set patch-here (patches at-points vision-points))
  let nearby-group-B count group-B-on (patch-set patch-here (patches at-points vision-points))
  let a-state 0
  if breed = group-A [
    if nearby-group-A <= nearby-group-B [ set a-state 1 ] ;; weak
    if nearby-group-A > nearby-group-B [ set a-state 2 ]  ;; strong
    if nearby-group-B = 0 [set a-state 0]                 ;; no contact
  ]
  if breed = group-B [
    if nearby-group-B <= nearby-group-A [ set a-state 1 ] ;; weak
    if nearby-group-B > nearby-group-A [ set a-state 2 ]  ;; strong
    if nearby-group-A = 0 [ set a-state 0 ]               ;; no contact
  ]
  report a-state
end

;; turtle procedure
;; return the column that holds the maximum value
;; if there are more than one column, then pick one at random
;; the column value is used in the program, but the maximum value is also returned for future use
to-report argmax [ a-list ]
  let index -1
  let column -1
  ;; find the maximum value
  let max-value max a-list
  ;; make a list of indexes that have the same maximum value
  let list-of-max [] ;; collection of index value
  repeat length a-list [
    set index (index + 1)
    if item index a-list = max-value [
      set list-of-max lput index list-of-max
    ]
  ]
  ;; pick one at random
  set column item random length list-of-max list-of-max
  report list column max-value
end

;; turtle procedure
;; return a list of action probabilities
to-report get-action_epsilon-greedy [ a-state an-epsilon ]
  let action-values matrix:make-constant 1 max-actions (an-epsilon / max-actions) ;; create a 1xAction vector with proportionated epsilon
  let best-action first argMax matrix:get-row q-values a-state ;; find best action index for the state
  matrix:set action-values 0 best-action (matrix:get action-values 0 best-action) + 1.0 - an-epsilon ;; enhance the chance for best action
  report matrix:get-row action-values 0
end

;; turtle procedure
;; return an action based on state probabilities
to-report choose-action [ action-probability ]
  let choice-prob random-float 1
  let index -1
  let cumulative-prob 0
  let an-action -1
  ;; step through action probabilities until choice propbability is less than the accumulated probability
  repeat length action-probability [
    set index (index + 1)
    set cumulative-prob (cumulative-prob + item index action-probability)
    if choice-prob < cumulative-prob [
      if an-action = -1 [ set an-action index ]
    ]
  ]
  report an-action
end

;; turtle procedure
;; return an agent's Q-Value for a state->action
to-report get-qvalue [ row column ]
  report matrix:get q-values row column
end

;; turtle procedure
;; set an agent's Q-Value state->action to a new value
to set-qvalue [ row column value ]
  ;;if value < 0 [ set value 0 ] ;; never store a negative q-value
  ;;if row = 0 and column >= 2 [ set value 0 ] ;; ensure state 0 (no contact) dosen't try to retreat or attack
  ;;print sentence "row: " row
  ;;print sentence "col: " column
  ;;print sentence "val: " value
  matrix:set q-values row column value
end

;; turtle procedure
;; given a state and action, return reward value
to-report get-reward [ a-state an-action ]
  let a-reward 0
  ;; no contact
  if a-state = 0 [
    if an-action = 0 [ set a-reward psugar ]
    if an-action = 1 [ set a-reward psugar ]
    if an-action = 2 [ set a-reward -100 ]
    if an-action = 3 [ set a-reward -100 ]
  ]
  ;; weak position
  if a-state = 1 [
    if an-action = 0 [ set a-reward psugar - max-psugar]
    if an-action = 1 [ set a-reward psugar + max-psugar ]
    if an-action = 2 [ set a-reward psugar + (max-psugar * 10) ]
    if an-action = 3 [ set a-reward psugar - (max-psugar * 2) ]
  ]
  ;; strong position
  if a-state = 2 [
    if an-action = 0 [ set a-reward psugar ]
    if an-action = 1 [ set a-reward psugar + max-psugar ]
    if an-action = 2 [ set a-reward psugar - (max-psugar * 2) ]
    if an-action = 3 [ set a-reward psugar + (max-psugar * 10) ]
  ]
  report a-reward
end

;;
;; Visualization Procedures
;;

;; turtle procedure
;; changes the turtle color to visualize agent metabolism
to no-visualization
  if breed = group-A [ set color blue ]
  if breed = group-B [ set color red ]
end

;; turtle procedure from original code
;; changes the turtle color to visualize agent vision distance
to color-agents-by-vision
  set color red - (vision - 3.5)
end

;; turtle procedure from original code
;; changes the turtle color to visualize agent metabolism
to color-agents-by-metabolism
  set color red + (metabolism - 2.5)
end

; Copyright 2020 Dale K. Brearcliffe and Andrew Crooks.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
300
10
708
419
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
49
0
49
1
1
1
ticks
30.0

BUTTON
10
55
90
95
NIL
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
100
55
190
95
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
200
55
290
95
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
10
105
290
150
visualization
visualization
"no-visualization" "color-agents-by-vision" "color-agents-by-metabolism"
0

PLOT
720
10
1000
165
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks count group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks count group-B"

SLIDER
10
15
290
48
initial-population
initial-population
1
400
400.0
1
1
NIL
HORIZONTAL

PLOT
720
175
1000
330
Mean Vision
NIL
NIL
0.0
10.0
0.0
6.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks mean [vision] of group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks mean [vision] of group-B"

PLOT
1010
175
1290
330
Mean Metabolism
NIL
NIL
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks mean [metabolism] of group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks mean [metabolism] of group-B"

MONITOR
5
285
147
334
Group A (Blue Circle)
count group-A
17
1
12

CHOOSER
25
340
120
385
group-A-action
group-A-action
"Rule M" "Q-Learning" "SARSA" "EC"
3

PLOT
1010
10
1290
165
Mean Wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks mean [sugar] of group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks mean [sugar] of group-B"

SWITCH
5
200
142
233
corner-start
corner-start
0
1
-1000

SLIDER
10
155
290
188
sugar-growback-rate
sugar-growback-rate
.1
1
1.0
.1
1
NIL
HORIZONTAL

MONITOR
145
285
297
334
Group B (Red Square)
count group-B
17
1
12

CHOOSER
175
340
270
385
group-B-action
group-B-action
"Rule M" "Q-Learning" "SARSA" "EC"
0

SWITCH
150
200
290
233
combat
combat
0
1
-1000

PLOT
720
340
1000
490
Mean Combat Deaths
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks combat-agent-a-die"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks combat-agent-b-die"

SWITCH
5
240
140
273
replace-dead
replace-dead
0
1
-1000

PLOT
1010
340
1290
490
Mean Starvation Deaths
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks starve-agent-a-die"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks starve-agent-b-die"

PLOT
1300
10
1580
165
Mean Age
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks sum [age] of group-A / count group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks sum [age] of group-B / count group-B"

PLOT
1300
175
1580
330
Mean Maximum Age
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Group A" 1.0 0 -13791810 true "" "plotxy ticks max [age] of group-A"
"Group B" 1.0 0 -2674135 true "" "plotxy ticks max [age] of group-B"

@#$#@#$#@
## WHAT IS IT?

This model was developed to test the usability of evolutionary computing and reinforcement learning by extending a well known agent-based model. Sugarscape (Epstein & Axtell, 1996) has been used to demonstrate migration, trade, wealth inequality, disease processes, sex, culture, and conflict. It is on conflict that this model is focused to demonstrate how machine learning methodologies could be applied.

The code is based on the Sugarscape 2 Constant Growback model, availble in the NetLogo models library. New code was added into the existing model while removing code that was not needed and modifying existing code to support the changes. Support for the original movement rule was retained while evolutionary computing, Q-Learning, and SARSA Learning were added. More information, including an Overview, Design concepts, and Details (ODD) description can be found at: https://tinyurl.com/ML-Agents

## HOW IT WORKS

This is a world in conflict. Group A (blue circles) and Group B (red squares) are in a constant struggle to obtain sugar and will attack the other to defend their territory. They start in the respective corners before looking for a fight.

Reinforcement learning agents will learn which actions provide the best (or worse) reward and apply those lessons to their future activities. Evolutionary computing agents attempt to enhance their capability to survive.

Each patch contains some sugar, the maximum amount of which is predetermined. At each tick, each patch regains sugar, until it reaches the maximum amount. The amount of sugar a patch currently contains is indicated by its color; the darker the yellow, the more sugar.

At setup, agents are placed at random within two corners of the world. Each agent can only see a certain distance horizontally and vertically. At each tick, each agent takes actions based upon its action type.

Based on an agent's action type, they may do one of the following actions (assumes COMBAT ON and REPLACE-DEAD ON):

* Action Rule M:
1) Jump to a high sugar location within range of their vision.
2) Attack when they can see more friendlies than enemies.

* Action EC (Evolutionary Computing):
1) Jump to a high sugar location within range of their vision.
2) Retreat (teleport home) when faced by a higher number of others.
3) Attack when they can see more friendlies than enemies.

* Actions SARSA and Q-Learning
1) Stay where they are (do nothing).
2) Jump to a high sugar location within range of their vision.
3) Retreat (teleport home) when faced by a higher number of others.
4) Attack when they can see more friendlies than enemies.

Agents also use (and thus lose) a certain amount of sugar each tick, based on their metabolism rates. If an agent runs out of sugar, it dies.

## HOW TO USE IT

Set the INITIAL-POPULATION slider before pressing SETUP. This determines the number of agents in the world.

Lower the SUGAR-GROWBACK-RATE to create a resource crisis and force movement (initially set to 1.0).

CORNER-START ON ensures the agents start in their home territories.

COMBAT controls peace or war.

REPLACE-DEAD ON ensure a constant flow of replacements and enables evolutionary computing to occur.

GROUP-A-ACTION and GROUP-B-ACTION is used to select which action rule each agent breed will use.

Press SETUP to populate the world with agents and import the sugar map data. GO will run the simulation continuously, while GO ONCE will run one tick.

The VISUALIZATION chooser gives different visualization options and may be changed while the GO button is pressed. When NO-VISUALIZATION is selected all the agents will be red. When COLOR-AGENTS-BY-VISION is selected the agents with the longest vision will be darkest and, similarly, when COLOR-AGENTS-BY-METABOLISM is selected the agents with the lowest metabolism will be darkest.

The eight plots show for each breed over time total world population, mean wealth (sugar), mean vision, mean metabolism, mean cumulative combat deaths, mean cumulative starvation deaths, mean age, and mean maximum age.

## THINGS TO NOTICE

Different combinations of GROUP-A-ACTION and GROUP-B-ACTION pit different learning methodologies against each other.

## THINGS TO TRY

Experiment with the rate of sugar growback to show how resource changes can affect agents.

## EXTENDING THE MODEL

Two hyper-paremeters control the reinforcement learning, learning rate and future discount. Can you tune them to improve the model?

The evolutionary computing is faithful to the original Sugarscape and does not include mutation. Does adding mutation improve the agent's capabilities?

## NETLOGO FEATURES

All of the Sugarscape models create the world by using `file-read` to import data from an external file, `sugar-map.txt`. This file defines both the initial and the maximum sugar value for each patch in the world.

Since agents cannot see diagonally we cannot use `in-radius` to find the patches in the agents' vision.  Instead, we use `at-points`.

## RELATED MODELS

Other models in the NetLogo Sugarscape suite include:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback
* Sugarscape 3 Wealth Distribution

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up.  Washington, D.C.: Brookings Institution Press.

Sutton & Barto Book (2018) Reinforcement Learning: An Introduction - http://incompleteideas.net/book/the-book-2nd.html

David Silver Lecture #4 (2015) - https://www.youtube.com/watch?v=PnHCvfgC_ZA

Madhu Sanjeevi Blog (2018) - https://medium.com/deep-math-machine-learning-ai/ch-12-1-model-free-reinforcement-learning-algorithms-monte-carlo-sarsa-q-learning-65267cb8d1b4

Li, J. and Wilensky, U. (2009).  NetLogo Sugarscape 2 Constant Growback model.  http://ccl.northwestern.edu/netlogo/models/Sugarscape2ConstantGrowback.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Brearcliffe, D. K. and Crooks, A.. (2020). Creating Intelligent Agents.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 Dale K. Brearcliffe and Andrew Crooks

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="https://licensebuttons.net/l/by-nc-sa/3.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License</a>.

<!-- 2020 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

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

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

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

dog
false
0
Polygon -7500403 true true 300 165 300 195 270 210 183 204 180 240 165 270 165 300 120 300 0 240 45 165 75 90 75 45 105 15 135 45 165 45 180 15 225 15 255 30 225 30 210 60 225 90 225 105
Polygon -16777216 true false 0 240 120 300 165 300 165 285 120 285 10 221
Line -16777216 false 210 60 180 45
Line -16777216 false 90 45 90 90
Line -16777216 false 90 90 105 105
Line -16777216 false 105 105 135 60
Line -16777216 false 90 45 135 60
Line -16777216 false 135 60 135 45
Line -16777216 false 181 203 151 203
Line -16777216 false 150 201 105 171
Circle -16777216 true false 171 88 34
Circle -16777216 false false 261 162 30

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
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Parameter Sweep - Pairwise Action" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>date-and-time</metric>
    <metric>mean [sugar] of group-A</metric>
    <metric>mean [sugar] of group-B</metric>
    <metric>mean [vision] of group-A</metric>
    <metric>mean [vision] of group-B</metric>
    <metric>mean [metabolism] of group-A</metric>
    <metric>mean [metabolism] of group-B</metric>
    <metric>combat-agent-a-die</metric>
    <metric>combat-agent-b-die</metric>
    <metric>starve-agent-a-die</metric>
    <metric>starve-agent-b-die</metric>
    <metric>mean [age] of group-A</metric>
    <metric>mean [age] of group-B</metric>
    <metric>max [age] of group-A</metric>
    <metric>max [age] of group-B</metric>
    <enumeratedValueSet variable="group-A-action">
      <value value="&quot;Rule M&quot;"/>
      <value value="&quot;EC&quot;"/>
      <value value="&quot;Q-Learning&quot;"/>
      <value value="&quot;SARSA&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="group-B-action">
      <value value="&quot;Rule M&quot;"/>
      <value value="&quot;EC&quot;"/>
      <value value="&quot;Q-Learning&quot;"/>
      <value value="&quot;SARSA&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
