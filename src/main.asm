.INCLUDE "header.asm"

.SEGMENT "ZEROPAGE"

.INCLUDE "registers.inc"

; game constants

STARTING_POS= $CF
P1XPOS = $58
P2XPOS = $A0
STATETITLE     = $00  ; displaying title screen
STATEPLAYING   = $01  ; move paddles/ball, check for collisions
STATEGAMEOVER  = $02  ; displaying game over screen

;variable
pointerLo: .res 1   ; pointer variables are declared in RAM
pointerHi:  .res 1   ; low byte first, high byte immediately after
buttons1: .res 1
buttons2: .res 1
posYP1: .res 1
posYP1Width: .res 1
posXP1: .res 1
posYP2: .res 1
posYP2Width: .res 1
posXP2: .res 1
curr_sprite: .res 1
row_first_tile: .res 1 ; la frame de la première rangée
temp: .res 1
drawX_left: .res 1
nbRow: .res 1
temp2: .res 1
x1: .res 1
x2: .res 1
x3: .res 1
x4: .res 1
x5: .res 1
x6: .res 1
x7: .res 1
x8: .res 1
x9: .res 1
x10: .res 1
x11: .res 1
x12: .res 1
x13: .res 1
x14: .res 1
x15: .res 1
x16: .res 1
score1: .res 1
score1Hi: .res 1
score2: .res 1
score2Hi: .res 1
timer: .res 1
scrolly: .res 1
gamestate: .res 1
triangle: .res 1

.SEGMENT "STARTUP"

RESET:
  .INCLUDE "init.asm"

.SEGMENT "CODE"

  JSR LoadPalette
  JSR LoadBackground
  JSR UnloadBackground1

  LDA #$0F
  STA APU_STATUS

  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK

forever:
  JMP forever

NMI:
  LDA #$00
  STA PPU_OAM_ADDR
  LDA #$02
  STA OAM_DMA

  JSR DrawScore

  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK
  LDA #$00          ; scroll x
  STA PPU_SCROLL
  LDA scrolly          ; scroll y
  STA PPU_SCROLL

  ;;;all graphics updates done by PPU here
  JSR ReadController1  ;;get the current button data for player 1
  JSR ReadController2  ;;get the current button data for player 2

GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen
    
  LDA gamestate
  CMP #STATEGAMEOVER
  BEQ EngineGameOver  ;;game is displaying ending screen
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing
GameEngineDone:  

  RTI


EngineTitle:
  JSR LoadBackground1
  ; initialise les variables
  LDA #$00
  STA score1Hi
  STA score1
  STA score2Hi
  STA score2
  LDA #STARTING_POS
  STA posYP1
  STA posYP2
  LDA #STARTING_POS+19
  STA posYP1Width
  STA posYP2Width
  LDA #P1XPOS
  STA posXP1
  LDA #P2XPOS
  STA posXP2

  LDA #$EE
  STA scrolly

  JSR setTimer

  JSR LoadPositionPiece

titleloop:  
  LDX buttons1
  CPX #$10
  BNE GameEngineDone
jeuState:
  LDA #STATEPLAYING
  STA gamestate
  JSR UnloadBackground1
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JSR LoadBackground2
  JSR LoadNoSprite
EndingLoop:
  LDX buttons1
  CPX #$10
  BNE GameEngineDone
titleState:
  LDA #STATETITLE
  STA gamestate
  JMP GameEngineDone
 
;;;;;;;;;;;

EnginePlaying:
  JSR LoadSprite
  JSR LoadSprite2
  JSR LoadObstacles

  JSR MovePieceRight
  JSR MovePieceLeft
  JSR checkCollision1
  JSR checkCollision2

  JSR decreaseTimer


ReadUp:
  LDX buttons1
  CPX #$08
  BNE checkPlayer2Up
checkPlayer1Up:
  LDA posYP1
  CMP #$D5
  BCC napasFranchi1
  CMP #$D7
  BCS napasencore1
  LDA score1
  CMP #$09
  BCC plusUnPointP1
  LDA #$00
  STA score1
  INC score1Hi
  JMP napasencore1
plusUnPointP1:
  INC score1
  JSR play_noteB5
napasencore1:
napasFranchi1:
  LDA posYP1
  SEC
  SBC #$02
  STA posYP1
  LDA posYP1Width
  SEC
  SBC #$02
  STA posYP1Width
checkPlayer2Up:
  LDX buttons2
  CPX #$08
  BNE doneReadUp
  LDA posYP2
  CMP #$D5
  BCC napasFranchi2
  CMP #$D7
  BCS napasencore2
  LDA score2
  CMP #$09
  BCC plusUnPointP2
  LDA #$00
  STA score2
  INC score2Hi
  JMP napasencore2
plusUnPointP2:
  INC score2
  JSR play_noteB5
napasencore2:
napasFranchi2:
  LDA posYP2
  SEC
  SBC #$02
  STA posYP2
  LDA posYP2Width
  SEC
  SBC #$02
  STA posYP2Width
doneReadUp:

ReadDown:
  LDX buttons1
  CPX #$04
  BNE checkPlayer2Down
checkPlayer1Down:
  LDA posYP1
  CMP #$D3
  BCC posP1plusPetit
  STA posYP1
  JMP checkPlayer2Down
posP1plusPetit:
  CLC
  ADC #$02
  STA posYP1
  LDA posYP1Width
  CLC
  ADC #$02
  STA posYP1Width
checkPlayer2Down:
  LDX buttons2
  CPX #$04
  BNE doneReadDown
  LDA posYP2
  CMP #$D3
  BCC posP2plusPetit
  STA posYP2
  JMP doneReadDown
posP2plusPetit:
  CLC
  ADC #$02
  STA posYP2
  LDA posYP2Width
  CLC
  ADC #$02
  STA posYP2Width
doneReadDown:
  JMP GameEngineDone


;----------subroutines---------------


VBlankWait:
  BIT PPU_STATUS
  BPL VBlankWait
  RTS

LoadPalette:
  LDA #$3F
  STA PPU_ADDRESS
  LDA #$00
  STA PPU_ADDRESS
  LDX #$00
LoadPaletteLoop:
  LDA paletteData,x
  STA PPU_DATA
  INX
  CPX #$20
  BNE LoadPaletteLoop
  RTS

LoadNoSprite:
  LDA #$00
  LDX #$00
NoSpriteLoop:
  STA SPRITE_ADDR,x
  INX
  CPX #$70
  BNE NoSpriteLoop
  RTS

LoadPositionPiece:
  LDX #$00
LoopPiece:
  LDA randomX,x
  STA x1,X
  INX
  CPX #$10
  BNE LoopPiece
  RTS

MovePieceRight:
  LDX #$00
LoopMoveRight:
  LDA x1,X
  CLC
  ADC #$01
  STA x1,X
  INX
  INX
  CPX #$10
  BNE LoopMoveRight
  RTS

MovePieceLeft:
  LDX #$01
LoopMoveLeft:
  LDA x1,X
  SEC
  SBC #$01
  STA x1,X
  INX
  INX
  CPX #$11
  BNE LoopMoveLeft
  RTS

ReadController1:
  LDA #$01
  STA JOY1
  LDA #$00
  STA JOY1
  LDX #$08
ReadController1Loop:
  LDA JOY1
  LSR A
  ROL buttons1
  DEX
  BNE ReadController1Loop
  RTS

ReadController2:
  LDA #$01
  STA JOY2_FRAME
  LDA #$00
  STA JOY2_FRAME
  LDX #$08
ReadController2Loop:
  LDA JOY2_FRAME
  LSR A
  ROL buttons2
  DEX
  BNE ReadController2Loop
  RTS

LoadSprite:
  LDA posYP1
  STA temp
  LDX #$00
  LDA #$03
  STA nbRow
  LDA posXP1
  STA drawX_left
  LDA #$00
  STA row_first_tile
nextRow:
  LDY #$02
  LDA row_first_tile
  STA curr_sprite
  LDA drawX_left
  STA temp2
LoadSpritesLoop:
  LDA temp
  STA SPRITE_ADDR, X
  LDA curr_sprite
  INC curr_sprite
  STA SPRITE_ADDR+1,X
  LDA #$00
  STA SPRITE_ADDR+2,X
  LDA temp2
  STA SPRITE_ADDR+3, X
  CLC
  ADC #$08
  STA temp2
  INX
  INX
  INX
  INX
  DEY
  BNE LoadSpritesLoop
  LDA temp
  CLC
  ADC #$08
  STA temp
  LDA row_first_tile
  CLC
  ADC #$02
  STA row_first_tile
  DEC nbRow
  BNE nextRow
  RTS

LoadSprite2:
  LDA posYP2
  STA temp
  LDX #$18
  LDA #$03
  STA nbRow
  LDA posXP2
  STA drawX_left
  LDA #$00
  STA row_first_tile
nextRow2:
  LDY #$02
  LDA row_first_tile
  STA curr_sprite
  LDA drawX_left
  STA temp2
LoadSpritesLoop2:
  LDA temp
  STA SPRITE_ADDR, X
  LDA curr_sprite
  INC curr_sprite
  STA SPRITE_ADDR+1,X
  LDA #$00
  STA SPRITE_ADDR+2,X
  LDA temp2
  STA SPRITE_ADDR+3, X
  CLC
  ADC #$08
  STA temp2
  INX
  INX
  INX
  INX
  DEY
  BNE LoadSpritesLoop2
  LDA temp
  CLC
  ADC #$08
  STA temp
  LDA row_first_tile
  CLC
  ADC #$02
  STA row_first_tile
  DEC nbRow
  BNE nextRow2
  RTS

LoadObstacles:
  LDX #$30
  LDY #$00
LoadObstaclesLoop:
  LDA randomY,y
  STA SPRITE_ADDR,X
  INX
  LDA #$06
  STA SPRITE_ADDR,X
  INX
  LDA #$00
  STA SPRITE_ADDR,X
  INX
  LDA x1,y
  STA SPRITE_ADDR,X
  INX
  INY
  CPY #$10
  BNE LoadObstaclesLoop
  RTS
  
checkCollision1:
  LDX #$00
checkCollisionLoop1:
  LDA x1,x
  CMP #P1XPOS
  BCC Xpluspetit1
  CMP #P1XPOS+8
  BCS Xplusgrand1
  LDA randomY,X
  CMP posYP1
  BCC Ypluspetit1
  CMP posYP1Width
  BCS Yplusgrand1
  JSR play_noteENoise
  LDA #STARTING_POS
  STA posYP1
  LDA #STARTING_POS+19
  STA posYP1Width
Yplusgrand1:
Ypluspetit1:
Xplusgrand1:
Xpluspetit1:
  INX
  CPX #$10
  BNE checkCollisionLoop1
  RTS

checkCollision2:
  LDX #$00
checkCollisionLoop2:
  LDA x1,x
  CMP #P2XPOS
  BCC Xpluspetit2
  CMP #P2XPOS+8
  BCS Xplusgrand2
  LDA randomY,X
  CMP posYP2
  BCC Ypluspetit2
  CMP posYP2Width
  BCS Yplusgrand2
  JSR play_noteENoise
  LDA #STARTING_POS
  STA posYP2
  LDA #STARTING_POS+19
  STA posYP2Width
Yplusgrand2:
Ypluspetit2:
Xplusgrand2:
Xpluspetit2:
  INX
  CPX #$10
  BNE checkCollisionLoop2
  RTS



play_noteENoise:
    LDA #$1F
    STA NOISE_VOL
    LDA #$BF             ;read the low byte of the period
    STA NOISE_LO           ;write to noise_LO
    LDA #$13             ;read the high byte of the period
    STA NOISE_HI           ;write to noise_HI
    RTS

play_noteB5:
    LDA #$8F    ;Duty 02, Volume F
    STA SQ1_VOL
    LDA #$08    ;Set Negate flag so low notes aren't silenced
    STA SQ1_SWEEP
    
    LDA #$70             ;read the low byte of the period
    STA SQ1_LO           ;write to SQ1_LO
    LDA #$00             ;read the high byte of the period
    STA SQ1_HI           ;write to SQ1_HI
    RTS



LoadBackground1:
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$80
  STA PPU_ADDRESS
  LDX #$00
Background1Loop:
  LDA Background1, X
  STA PPU_DATA
  INX
  CPX #$60
  BNE Background1Loop
LoadAttribute:
  LDA PPU_STATUS         ; read PPU status to reset the high/low latch
  LDA #$23
  STA PPU_ADDRESS        ; write the high byte of $23C0 address
  LDA #$C0
  STA PPU_ADDRESS        ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA PPU_DATA           ; write to PPU
  INX                   ; X = X + 1
  CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop
  RTS

UnloadBackground1:
  LDA #$00
  STA PPU_CTRL
  STA PPU_MASK
  LDA PPU_STATUS
  LDA #$20
  STA PPU_ADDRESS
  LDA #$00
  STA PPU_ADDRESS
  LDX #$00
  LDY #$00
UnloadLoopOut:
UnloadLoop:
  LDA #$FF
  STA PPU_DATA
  INX
  BNE UnloadLoop
  INY
  CPY #$04
  BNE UnloadLoopOut
  LDA #%10010000
  STA PPU_CTRL
  LDA #%00011110
  STA PPU_MASK
  RTS

LoadBackground2:
  LDA PPU_STATUS
  LDA #$21
  STA PPU_ADDRESS
  LDA #$80
  STA PPU_ADDRESS
  LDX #$00
Background2Loop:
  LDA Background2, X
  STA PPU_DATA
  INX
  CPX #$60
  BNE Background2Loop
  JSR LoadAttribute
  RTS

LoadBackground:
  LDA PPU_STATUS        ; read PPU status to reset the high/low latch
  LDA #$28
  STA PPU_ADDRESS       ; write the high byte of $2000 address
  LDA #$00
  STA PPU_ADDRESS       ; write the low byte of $2000 address

  LDA #<background
  STA pointerLo         ; put the low byte of the address of background into pointer
  LDA #>background
  STA pointerHi         ; put the high byte of the address into pointer
  
  LDX #$00              ; start at pointer + 0
  LDY #$00
OutsideLoop:
  
InsideLoop:
  LDA (pointerLo), y  ; copy one background byte from address in pointer plus Y
  STA PPU_DATA        ; this runs 256 * 4 times
  
  INY                 ; inside loop counter
  CPY #$00
  BNE InsideLoop      ; run the inside loop 256 times before continuing down
  
  INC pointerHi       ; low byte went 0 to 256, so high byte needs to be changed now
  
  INX
  CPX #$04
  BNE OutsideLoop     ; run the outside loop 256 times before continuing down
  RTS



DrawScore:
  LDA #$18
  STA $02F8
  STA $02F0

  LDA score1
  CLC
  ADC #$07
  STA $02F9
  
  LDA #$20
  STA $02FA
  
  LDA #$78
  STA $02FB
   
  LDA score1Hi
  CLC
  ADC #$07
  STA $02F1

  LDA #$20
  STA $02F2

  LDA #$70
  STA $02F3


  LDA #$18
  STA $02FC
  STA $02F4

  LDA score2
  CLC
  ADC #$07
  STA $02FD
  
  LDA #$20
  STA $02FE
  
  LDA #$90
  STA $02FF

  LDA score2Hi
  CLC
  ADC #$07
  STA $02F5
  
  LDA #$20
  STA $02F6
  
  LDA #$88
  STA $02F7
  RTS

setTimer:
  LDA #$40
  STA timer
  RTS

decreaseTimer:
  DEC timer
  BEQ eraseAbackgroundSprite
  RTS
eraseAbackgroundSprite:
  LDX #$10
  LDA #$00
  STA background,x
decreaseTimerHi:
  JSR processcrolling
  JSR setTimer
  RTS

processcrolling:
    LDA scrolly
    SEC
    SBC #$02
    STA scrolly
    CMP #$10
    BNE donescroll
    LDA #$10
    STA scrolly
    LDA #STATEGAMEOVER
    STA gamestate
donescroll:
    RTS

Background1:
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $14,$2B,$1C,$1E,$20,$40,$13,$1C,$1E,$20
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

Background2:
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $08,$1C,$28,$20,$40,$10,$31,$20,$2D 
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

background:
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 1
  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 2
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 3
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 4
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 5
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 6
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 7
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 8
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 9
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 10
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 11
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 12
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 13
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 14
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 15
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 16
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 17
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 18
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 19
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 20
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 21
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 22
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 23
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 24
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 25
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 26
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 27
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 28
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 29
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

  .BYTE $00,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00  ;;row 30
  .BYTE $01,$00,$00,$00,$00,$00,$00,$00, $00,$00,$00,$00,$00,$00,$00,$00

attribute:
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .BYTE %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

paletteData:
  .BYTE $0F,$30,$30,$30,  $0F,$30,$30,$30,  $0F,$30,$30,$30,  $0F,$30,$30,$30   ;;background palette
  .BYTE $0F,$30,$30,$30,  $0F,$30,$30,$30,  $0F,$30,$30,$30,  $0F,$30,$30,$30   ;;sprite palette

randomY:
  .BYTE $4A, $A3, $55, $31, $84, $09, $15, $4F, $6B, $2F, $92, $A8, $76, $26, $23, $63

randomX:
  .BYTE $A4, $93, $55, $13, $4D, $90, $51, $F4, $CC, $40, $27, $D4, $61, $65, $A6, $72

.SEGMENT "CHARS"
.INCLUDE "charset.asm"