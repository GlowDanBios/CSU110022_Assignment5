# PASTE LINK TO TEAM VIDEO BELOW
#
#

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global Main
  .global  SysTick_Handler
  .global EXTI0_IRQHandler

  @ Definitions are in definitions.s to keep this file "clean"
  .include "./src/definitions.s"

  .equ    BLINK_PERIOD, 250

  .section .text

Main:
  PUSH  {R4-R5,LR}

  LDR   R4, =game_stage
  LDR   R5, =0
  STR   R5, [R4]

  @
  @ Prepare GPIO Port E Pin 9 for output (LED LD3)
  @ We'll blink LED LD3 (the orange LED)
  @

  @ Enable GPIO port E by enabling its clock
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << (RCC_AHBENR_GPIOEEN_BIT))
  STR     R5, [R4]

  @ Configure all LEDs for output
  @   by setting bits 27:26 of GPIOE_MODER to 01 (GPIO Port E Mode Register)
  @   (by BIClearing then ORRing)
  LDR     R4, =GPIOE_MODER
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD3_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD3_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write 
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD4_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD4_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write 
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD5_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD5_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write 
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD6_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD6_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD7_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD7_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD8_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD8_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD9_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD9_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write
  LDR     R5, [R4]                    @ Read ...
  BIC     R5, #(0b11<<(LD10_PIN*2))    @ Modify ...
  ORR     R5, #(0b01<<(LD10_PIN*2))    @ write 01 to bits 
  STR     R5, [R4]                    @ Write     

  @ Initialise the first countdown

  LDR     R4, =blink_countdown
  LDR     R5, =BLINK_PERIOD
  STR     R5, [R4]  

  @ Configure SysTick Timer to generate an interrupt every 1ms

  LDR     R4, =SCB_ICSR               @ Clear any pre-existing interrupts
  LDR     R5, =SCB_ICSR_PENDSTCLR     @
  STR     R5, [R4]                    @

  LDR     R4, =SYSTICK_CSR            @ Stop SysTick timer
  LDR     R5, =0                      @   by writing 0 to CSR
  STR     R5, [R4]                    @   CSR is the Control and Status Register
  
  LDR     R4, =SYSTICK_LOAD           @ Set SysTick LOAD for 1ms delay
  LDR     R5, =7999                   @ Assuming 8MHz clock
  STR     R5, [R4]                    @ 

  LDR     R4, =SYSTICK_VAL            @   Reset SysTick internal counter to 0
  LDR     R5, =0x1                    @     by writing any value
  STR     R5, [R4]

  LDR     R4, =SYSTICK_CSR            @   Start SysTick timer by setting CSR to 0x7
  LDR     R5, =0x7                    @     set CLKSOURCE (bit 2) to system clock (1)
  STR     R5, [R4]                    @     set TICKINT (bit 1) to 1 to enable interrupts
                                        @     set ENABLE (bit 0) to 1



  @
  @ Prepare external interrupt Line 0 (USER pushbutton)
  @ We'll count the number of times the button is pressed
  @


  @ Configure USER pushbutton (GPIO Port A Pin 0 on STM32F3 Discovery
  @   kit) to use the EXTI0 external interrupt signal
  @ Determined by bits 3..0 of the External Interrrupt Control
  @   Register (EXTIICR)
  LDR     R4, =SYSCFG_EXTIICR1
  LDR     R5, [R4]
  BIC     R5, R5, #0b1111
  STR     R5, [R4]

  @ Enable (unmask) interrupts on external interrupt Line0
  LDR     R4, =EXTI_IMR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Set falling edge detection on Line0
  LDR     R4, =EXTI_FTSR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Enable NVIC interrupt #6 (external interrupt Line0)
  LDR     R4, =NVIC_ISER
  MOV     R5, #(1<<6)
  STR     R5, [R4]

  @ Nothing else to do in Main
  @ Idle loop forever (welcome to interrupts!!)
Idle_Loop:
   
  B     Idle_Loop
  
End_Main:
  POP   {R4-R5,PC}



@
@ SysTick interrupt handler (blink LED LD3)
@
  .type  SysTick_Handler, %function
SysTick_Handler:

  PUSH  {R4-R8, LR}

  LDR   R4, =random_value           @ Load random value
  LDR   R5, [R4]                    @ 
  ADD   R5, R5, #1                  @ random++
  STR   R5, [R4]                    @ Store random value


  LDR   R4, =blink_countdown        @ if (countdown != 0) {
  LDR   R5, [R4]                    @
  CMP   R5, #0                      @
  BEQ   .LelseFire                  @

  SUB   R5, R5, #1                  @   countdown = countdown - 1;
  STR   R5, [R4]                    @

  B     .LendIfDelay                @ }

.LelseFire:                         @ else {
  LDR     R4, =game_stage           @     Load game_stage 
  LDR     R4, [R4]                  @
  CMP     R4, #0                    @     if(game_stage!=0){
  BEQ     .LendIfDelay              @
  LDR     R4, =GPIOE_ODR            @         Invert LD3
  LDR     R5, [R4]                  @
  LDR     R8, =target               @         Load target value
  LDR     R8, [R8]                  @ 
  ADD     R8, R8, #8                @         target = target+8
  MOV     R9, #1                    @
  MOV     R9, R9, LSL R8            @
  EOR     R5, R9                    @       GPIOE_ODR = GPIOE_ODR ^ (1<<target);
  STR     R5, [R4]                  @ 

  LDR     R4, =blink_countdown      @       countdown = BLINK_PERIOD;
  LDR     R5, =BLINK_PERIOD         @
  STR     R5, [R4]                  @
  LDR     R6, =demo_blink_count     @       load blink_count
  LDR     R7, [R6]                  @
  ADD     R7, R7, #1                @       blink_count++
  STR     R7, [R6]                  @
  CMP     R7, #10                   @       if(blink_count>10){
  BLO     .LendIfDelay              @
  LDR     R4, =2                    @
  LDR     R5, =game_stage           @           game_stage = 2
  STR     R4, [R5]                  @
  LDR     R4, =SYSTICK_CSR          @           Stop SysTick timer
  LDR     R5, =0                    @       }
  STR     R5, [R4]                  @     }

.LendIfDelay:                       @ }

  LDR     R4, =SCB_ICSR             @ Clear (acknowledge) the interrupt
  LDR     R5, =SCB_ICSR_PENDSTCLR   @
  STR     R5, [R4]                  @

  @ Return from interrupt handler
  POP  {R4-R8, PC}



@
@ External interrupt line 0 interrupt handler
@   (count button presses)
@
  .type  EXTI0_IRQHandler, %function
EXTI0_IRQHandler:

  PUSH  {R4-R6,LR}

  LDR   R5, =game_stage           @  
  LDR   R4, [R5]                  @
  CMP   R4, #0                    @ if(game_stage == 0){
  BEQ   .Lstart_game              @
  B     .Lreturn                  @

.Lstart_game:
  LDR   R6, =random_value         @   Load random value
  LDR   R6, [R6]                  @   
  AND   R4, R6, #0b111            @

  LDR   R6, =target               @    target = random value & 0b111
  STR   R4, [R6]                  @
  LDR   R6, =1                    @    game_stage = 1
  STR   R6, [R5]                  @ }

  B     .Lreturn

  @ Return from interrupt handler
.Lreturn:
  POP  {R4-R6,PC}



  .section .data
  
game_stage:
  .space 4

demo_blink_count:
  .space 4

target:
  .space 4  

blink_countdown:
  .space  4

random_value:
  .space 4


  .end