#!/bin/bash
#
#     Program: Gerbtris
#     Author:  Gerbil (@M_C_Stott)
#     Version: 1.1   16/11/2020
#        Removed local echo
#     Version: 1.0   02/10/2020
#     
#     Gerbtris is the Tetris game witten in bash.
#     Why have I done this? Why not? :P
#     This is very basic as you can imagine. There are flaws.
#     For example holding a key down may print it on the playing field.
#     And each keypress activates the "move down" gravity function along with the movement.
#     And it only rotates clockwise, I couldn't be bothered to do 
#     anti-clockwise too even though it would be really easy to do.
#     And the scoring is constant - 10 points per line.
#
#     Controls:
#        z     | left arrow key  : Move shape left
#        x     | right arrow key : Move shape right
#        SPACE | up arrow key    : Rotate shape clockwise
#        m     | down arrow key  : Move shape down 
#        q                       : Quit game
#    
#     Thanks and resources used:
#     Rotations: https://code.likeagirl.io/rotate-an-2d-matrix-90-degree-clockwise-without-create-another-array-49209ea8b6e6
#     This is a brilliant resource written by Ngoc (Alex) Vuong (@Dragonzal) that perfectly explains how to programatically rotate an array.
#     This is awesome! Thank you for writing this.
#
#     Also thanks to my good friend and colleague @csBlueChip for the awesome idea of getting the program to beep whenever a line is made. 
#     I salute you sir!
#
#     Enjoy the game.
#

trap "stty echo" EXIT  #Turns on local echo if script is exited/ended.
stty -echo #Turns off local echo so key press control chars aren't seen.

CONTROL_LIMIT=1   #Delay to accept key press
SHAPE_X=5 #position of shape. Default for new shape is [4,1]
SHAPE_Y=1
SHAPE_ID=1 #ID of current shape
NEXT_SHAPE=$((1 + RANDOM % 7)) #ID of next shape
PLAYFIELD_WIDTH=12 #dimensions including "walls"
PLAYFIELD_HEIGHT=21
SCORE=0

shape1data="0100111000000000" # T shape
shape2data="0220220000000000" # s shape
shape3data="3300033000000000" # z shape
shape4data="0040444000000000" # L shape
shape5data="5000555000000000" # ¬ shape
shape6data="0660066000000000" # square shape
shape7data="0000777700000000" # | shape

declare -A shape1=()
declare -A shape2=()
declare -A shape3=()
declare -A shape4=()
declare -A shape5=()
declare -A shape6=()
declare -A shape7=()
declare -A shape=()  #the "live" shape
declare -A playfield=() # the 'container' of shapes

setupplayfield(){ 

   for y in $( seq 0 $((PLAYFIELD_HEIGHT)) )
   do
      for x in $( seq 1 $((PLAYFIELD_WIDTH)) )
      do
         playfield[${x},${y}]=0
         [[ ${y} -eq $((${PLAYFIELD_HEIGHT})) ]] && {
            playfield[${x},$((${y}-1))]=8
         }          
      done
      playfield[0,${y}]=8
      playfield[$((${PLAYFIELD_WIDTH}-1)),${y}]=8
   done
   printplayfield
}

printnextbox(){
   posX=$1
   posY=$2
   boxsize=8
   shapeYpos=4
   
   [[ ${NEXT_SHAPE} -eq 7 ]] && shapeYpos=3 #move the shape up if it's the long one
   
   for y in $( seq 0 $((${boxsize}-1)) )
   do
      echo -ne "\033[$((${posY}+${y}));$((${posX}))H█" #reposition cursor     
      echo -ne "\033[$((${posY}+${y}));$((${posX}+${boxsize}-1))H█" #reposition cursor     
   done   
   for x in $( seq 0 $((${boxsize}-1)) )
   do
      echo -ne "\033[$((${posY}));$((${posX}+${x}))H█" #reposition cursor     
      echo -ne "\033[$((${posY}+${boxsize}-1));$((${posX}+${x}))H█" #reposition cursor     
   done
   echo -ne "\033[$((${posY}+2));$((${posX}+2))HNEXT"
   printnextshape ${NEXT_SHAPE} $((${posX}+2)) $((${posY}+${shapeYpos}))
   
}

printtitle(){
   posX=$1
   posY=$2

echo -ne "\033[$((${posY}));$((${posX}))H  ▄████ ██████  ██▀███   ▄▄▄▄   ▄▄▄██████ ██▀███   ███  ██████ "
echo -ne "\033[$((${posY}+1));$((${posX}))H ██▒ ▀█▒██   ▀ ███ ▒ ██▒██████▄ █  ██▒ █▒███ ▒ ██▒███▒▒██    ▒ "
echo -ne "\033[$((${posY}+2));$((${posX}))H▒██░▄▄▄░▒███   ███ ░▄█ ▒▒██▒ ▄██▒ ███░ ▒░███ ░▄█ ▒▒██▒░ ███▄   "
echo -ne "\033[$((${posY}+3));$((${posX}))H░██  ███▒██  ▄ ▒██▀▀█▄  ▒██░█▀  ░ ████ ░ ▒██▀▀█▄  ░██░  ▒   ██▒"
echo -ne "\033[$((${posY}+4));$((${posX}))H░▒████▀▒░▒████▒░███ ▒██▒░██  ▀██  ▒██▒ ░ ░███ ▒██▒░██░▒██████▒▒"
echo -ne "\033[$((${posY}+5));$((${posX}))H ░▒   ▒ ░░ ▒░ ░░ ▒█ ░▒█░░▒████▀▒  ▒ ░░   ░ ▒█ ░▒█░░█  ▒ ▒█▒ ▒ ░"
echo -ne "\033[$((${posY}+6));$((${posX}))H  ░   ░  ░ ░  ░  ░▒ ░ ▒░▒░▒   ░     ░      ░▒ ░ ▒░ ▒ ░░ ░▒  ░ ░"
echo -ne "\033[$((${posY}+7));$((${posX}))H░ ░   ░    ░     ░░   ░  ░    ░   ░        ░░   ░  ▒ ░░  ░  ░  "
echo -ne "\033[$((${posY}+8));$((${posX}))H      ░    ░  ░   ░      ░                  ░      ░        ░  "
echo -ne "\033[$((${posY}+9));$((${posX}))H  Tetris written in bash.    ░ Well, somebody had to do it! ;)"
echo -ne "\033[$((${posY}+10));$((${posX}))H  Coded by: @M_C_Stott (aka Gerbil)"
}

printscorebox(){
   posX=$1
   posY=$2
   boxXsize=16
   boxYsize=5
   shapeYpos=4
   
   [[ ${NEXT_SHAPE} -eq 7 ]] && shapeYpos=3 #move the shape up if it's the long one
   
   for y in $( seq 0 $((${boxYsize}-1)) )
   do
      echo -ne "\033[$((${posY}+${y}));$((${posX}))H█" #reposition cursor     
      echo -ne "\033[$((${posY}+${y}));$((${posX}+${boxXsize}-1))H█" #reposition cursor     
   done   
   for x in $( seq 0 $((${boxXsize}-1)) )
   do
      echo -ne "\033[$((${posY}));$((${posX}+${x}))H█" #reposition cursor     
      echo -ne "\033[$((${posY}+${boxYsize}-1));$((${posX}+${x}))H█" #reposition cursor     
   done
   echo -ne "\033[$((${posY}+2));$((${posX}+2))HSCORE: ${SCORE}"
   
}


removelines(){
   declare -A temp=()
   line_number=$((${PLAYFIELD_HEIGHT}-1))
   zero_count=0
   deleted=0
   for y in $( seq 0 $((${PLAYFIELD_HEIGHT}-1)) )
   do
      for x in $( seq 0 $((${PLAYFIELD_WIDTH}-1)) )
      do
         temp[${x},${line_number}]=${playfield[${x},$((${PLAYFIELD_HEIGHT}-${y}-1))]}
         [[ temp[${x},${line_number}] -eq 0 ]] && ((zero_count++))
      done
      [[ ${zero_count} -eq 0 ]] && [[ ${line_number} -lt $((${PLAYFIELD_HEIGHT}-1)) ]] && ((SCORE+=10)) && ((deleted++)) 
      [[ ${zero_count} -eq 0 ]] && [[ ${line_number} -eq $((${PLAYFIELD_HEIGHT}-1)) ]] && ((line_number--)) 
      [[ ${zero_count} -gt 0 ]] && ((line_number--)) && zero_count=0
   done
   
   [[ ${deleted} -eq 0 ]] && return #do nowt as nothing is to be deleted
   
   for y in $( seq 0 ${deleted} ) #Fill top gap and walls
   do
      for x in $( seq 0 $((${PLAYFIELD_WIDTH}-1)) )
      do
         temp[${x},${y}]=0
      done
      temp[0,${y}]=8
      temp[$((${PLAYFIELD_WIDTH}-1)),${y}]=8
   done
   
   echo -e "\007" #BEEP! Cheers BlueChip! :)

   for y in $( seq 0 $((${PLAYFIELD_HEIGHT}-1)) ) #copy temp to playfield
   do
      for x in $( seq 0 $((${PLAYFIELD_WIDTH}-1)) )
      do
         playfield[${x},${y}]=${temp[${x},${y}]}
      done
   done
   printplayfield
}


createshape(){
   SHAPE_ID=$1
   NEXT_SHAPE=$((1 + RANDOM % 7))
   SHAPE_X=5
   SHAPE_Y=1

   for y in $( seq 0 3 ) 
   do         
      for x in $( seq 0 3 )
      do
         eval "shape[${x},${y}]=\${shape${SHAPE_ID}[\${x},\${y}]}"
      done
   done;
   printnextbox 15 14
   printscorebox 25 14
   printtitle 15 2
   printshape ${SHAPE_ID} ${SHAPE_X} ${SHAPE_Y}
}

printplayfield(){
   echo -ne "\033[2J" #clear screen and reset cursor to 0,0   
   for y in $( seq 0 $((${PLAYFIELD_HEIGHT}-1)) ) 
   do         
      for x in $( seq 0 $((${PLAYFIELD_WIDTH}-1)) )
      do    
         block=${playfield[${x},${y}]}
         if [ ${block} -gt 0 ]
         then
            echo -ne "\033[$((${y}+1));$((${x}+1))H" #reposition cursor  
            printf "\033[0;3${block}m█\033[0m" 
         fi
      done
   done;
   echo -ne "\033[23;0H" #reposition cursor to bottom of playfield   
}


printshape(){
   shapenum=$1
   posX=$2
   posY=$3
   penX=${posX}
   penY=${posY}
   gridwidth=2
   
   [[ ${shapenum} -eq 7 ]] && gridwidth=3
   
   for y in $( seq 0 ${gridwidth} ) 
   do         
      for x in $( seq 0 ${gridwidth} )
      do    
         block=${shape[${x},${y}]}
            if [ ${block} -gt 0 ]
         then
            echo -ne "\033[${penY};${penX}H" #reposition cursor  
            printf "\033[0;3${block}m█\033[0m"  #\033[0;30m" #\033[0m
         fi
         ((penX++))
      done
      ((penY++))
      penX=${posX}
   done;
   echo -ne "\033[23;0H" #reposition cursor to bottom of playfield   
}

printnextshape(){
   shapenum=$1
   posX=$2
   posY=$3
   penX=${posX}
   penY=${posY}
   gridwidth=2
   
   [[ ${shapenum} -eq 7 ]] && gridwidth=3
   
   #clear next shape image
   for y in $( seq 0 ${gridwidth} ) 
   do         
      echo -ne "\033[$((${penY}+${y}));${penX}H    " #blank out previous pattern  
   done 
   
   
   for y in $( seq 0 ${gridwidth} ) 
   do         
      for x in $( seq 0 ${gridwidth} )
      do    
         eval "block=\${shape${shapenum}[${x},${y}]}"
         if [ ${block} -gt 0 ]
         then
            echo -ne "\033[${penY};${penX}H" #reposition cursor  
            printf "\033[0;3${block}m█\033[0m" 
         fi
         ((penX++))
      done
      ((penY++))
      penX=${posX}
   done;
   echo -ne "\033[23;0H" #reposition cursor to bottom of playfield   
}


clearshape(){
   posX=$1
   posY=$2
   penX=${posX}
   penY=${posY}
   gridwidth=2
   
   [[ ${SHAPE_ID} -eq 7 ]] && gridwidth=3
   
   for y in $( seq 0 ${gridwidth} ) 
   do         
      for x in $( seq 0 ${gridwidth} )
      do    
         block=${shape[${x},${y}]}
            if [ ${block} -gt 0 ]
         then
            echo -ne "\033[${penY};${penX}H" #reposition cursor  
            printf " " 
         fi
         ((penX++))
      done
      ((penY++))
      penX=${posX}
   done;
}


moveshape(){
   position=$1
   gridwidth=2
   blockerx=0
   blockery=0
   var="" #used to insert variable name
   
   [[ ${SHAPE_ID} -eq 7 ]] && gridwidth=3
   
   case ${position} in
      1) #left
      blockerx=-2
      blockery=-1
      delta=-1
      var="SHAPE_X";;
      2) #right
      blockerx=0
      blockery=-1
      delta=1
      var="SHAPE_X";;
      3) #up
      blockerx=-1
      blockery=-1
      delta=-1
      var="SHAPE_Y";;
      4) #down
      blockerx=-1
      blockery=0
      delta=1
      var="SHAPE_Y";;
   esac
      
   for y in $( seq 0 ${gridwidth} ) #Check for collisions
   do         
      for x in $( seq 0 ${gridwidth} )
      do
         [[ ${shape[${x},${y}]} -gt 0 ]] && #If the cell of the shape is "solid"...
         [[ ${playfield[$((${x}+${SHAPE_X}+${blockerx})),$((${y}+${SHAPE_Y}+${blockery}))]} -gt 0 ]] && #...and corresponding cell in the playfield is "solid"... 
         {
             [[ $2 -eq 1 ]] && storeshape && createshape ${NEXT_SHAPE} #...then store shape if "moved" by cpu ("gravity"). 
            return; #Otherwise ignore the move attempt.
         }
            
      done
   done;
   #If we get here then no collision was found. Continue with moving the shape.
   clearshape ${SHAPE_X} ${SHAPE_Y}
   eval "((${var}+=${delta}))"
   printshape ${SHAPE_ID} ${SHAPE_X} ${SHAPE_Y}
   echo -ne "\033[23;0H" #reposition cursor to bottom of playfield                    
}


storeshape(){
   posX=${SHAPE_X}
   posY=${SHAPE_Y}
   penX=${posX}
   penY=${posY}
   gridwidth=3 #Only interested in s populated cells
   
   [[ ${SHAPE_Y} -eq 1 ]] && echo "GAME OVER!" && exit
   
   for y in $( seq 0 ${gridwidth} ) 
   do         
      for x in $( seq 0 ${gridwidth} )
      do    
         block=${shape[${x},${y}]}
         if [ ${block} -gt 0 ]
         then
            playfield[$((${penX}-1)),$((${penY}-1))]=${shape[${x},${y}]}
         fi
         ((penX++))
      done
      ((penY++))
      penX=${posX}
   done;
   printshape ${SHAPE_ID} ${SHAPE_X} ${SHAPE_Y} #Stop the "rare invisible glitch?"
   echo -ne "\033[23;0H" #reposition cursor to bottom of playfield
   removelines 
}


rotateshape(){
   shapenum=$1
   n=3
   declare -A temp=()
   
   [[ ${shapenum} -eq 6 ]] && return #no need to rotate a square!
   [[ ${shapenum} -eq 7 ]] && n=4 #change n if shape is |
      
   for x in $( seq 0 3 ) #copy shape to temp
   do
      for y in $( seq 0 3 )
      do
         temp[${x},${y}]=${shape[${x},${y}]}
      done
   done   

   for x in $( seq 0 $((${n}/2)) ) #make temporary copy and check for collisions...
   do
      for y in $( seq ${x} $((${n}-${x}-2)) )
      do
         i=$((${n}-${x}-1))
         j=$((${n}-${y}-1))
         tmp=${shape[${x},${y}]}
         temp[${x},${y}]=${shape[${y},${i}]}
         [[ ${temp[${x},${y}]} -gt 0 ]] && [[ ${playfield[$(($SHAPE_X+${x}-1)),$(($SHAPE_Y+${y}-1))]} -gt 0 ]] && return
         temp[${y},${i}]=${shape[${i},${j}]}
         [[ ${temp[${y},${i}]} -gt 0 ]] && [[ ${playfield[$(($SHAPE_X+${y}-1)),$(($SHAPE_Y+${i}-1))]} -gt 0 ]] && return
         temp[${i},${j}]=${shape[${j},${x}]}
         [[ ${temp[${i},${j}]} -gt 0 ]] && [[ ${playfield[$(($SHAPE_X+${i}-1)),$(($SHAPE_Y+${j}-1))]} -gt 0 ]] && return
         temp[${j},${x}]=${tmp}
         [[ ${temp[${j},${x}]} -gt 0 ]] && [[ ${playfield[$(($SHAPE_X+${j}-1)),$(($SHAPE_Y+${x}-1))]} -gt 0 ]] && return
      done
   done   

   clearshape ${SHAPE_X} ${SHAPE_Y}
   for x in $( seq 0 ${n} ) #...if we got to here, no collisions. Make permanent.
   do
      for y in $( seq 0 ${n} )
      do
         shape[${x},${y}]=$((${temp[${x},${y}]}+0))
      done
   done   
}

#################################################################
# Setup shapes.

for shapenum in $( seq 1 7 )
do
   i=0
   for y in $( seq 0 3 ) 
   do
      for x in $( seq 0 3 )
      do    
         eval "shape${shapenum}[\${x},\${y}]=\${shape${shapenum}data:\${i}:1}"
         ((i++))
      done
   done
done

echo -ne "\033[2J" #clear screen and reset cursor to 0,0

setupplayfield
echo -ne "\033[23;0H" #reposition cursor to bottom of playfield

createshape ${SHAPE_ID}

while :  # 1 char (not delimiter), silent
do
   #read keystroke:
   read -sN1 -t ${CONTROL_LIMIT} key 

   # catch multi-char special key sequences
   read -sN1 -t 0.0001 k1
   read -sN1 -t 0.0001 k2
   read -sN1 -t 0.0001 k3
   key+=${k1}${k2}${k3}

   case "$key" in
      z|$'\e[D'|$'\e0D')  # cursor left
      moveshape 1;;

      x|$'\e[C'|$'\e0C')  # cursor right
      moveshape 2;;

      $'\e[A'|$'\e0A')  # cursor up
      rotateshape ${SHAPE_ID};;

      m|$'\e[B'|$'\e0B')  # cursor down
      moveshape 4;;

      ' ')  # rotate shape
      rotateshape ${SHAPE_ID};;

      q) # q, carriage return: quit
      echo "BYE BYE PEEPS!" && exit;;
   esac
   moveshape 4 1  #second parameter tells that CPU has moved the block down
done


