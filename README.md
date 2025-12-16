# VHDL Pokémon Battle Demo
*(For educational purposes only)*

**Made by Seongjun An and Matthew Suh**

## Project Overview
Our project recreates a simplified version of a Pokémon battle using VHDL and runs on a Nexys A7-100T FPGA board. The project is displayed on a monitor using a VGA to HDMI adapter plugged directly into the FPGA. The player is able to create a team of 3 Pokémon, choosing from 6 available Pokémon. The player then battles against a CPU trainer that also has a team of 3 Pokémon. The demo ends when the player defeats all of the CPU's Pokémon or when all of their Pokémon are defeated.

### Pokémon Selection Screen
![](/Media/pokeSelect.png)

### Controls
- BTNU: Move cursor up
- BTND: Move cursor down
- BTNL: Move cursor left
- BTNR: Move cursor right
- BTNC: Select/Attack

## Required Hardware/Software
- Digilent Nexys A7-100T FPGA Board
- Micro USB Cable
- VGA to HDMI Adapter
- HDMI Cable
- TV or Monitor with an HDMI input
- AMD Vivado™ Design Suite

## Visuals/Diagrams
[Full video of demo](https://youtu.be/rZIYxnwkLVs)
### Battle
![](/Media/battle.gif)

### Modules
![](/Media/diagram.png)

### FSM
![](/Media/fsm.png)
