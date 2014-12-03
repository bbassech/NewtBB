import controlP5.*;

/*
 *  Copyright (c) 2014, Neuplay
 *  All rights reserved.
 *
 *  This file contains CONFIDENTIAL material.
 *  Neuplay forbids duplication of
 *  this material without express written permission
 *  from Bay Computer Associates.
 *
 *
 *    Author:
 *    Joel B. Schwartz
 *    Neuplay
 *    1 Hoppin Street
 *    Coro West, Ste 404
 *    Providence, RI 02903
 */

import processing.serial.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.PointerInfo;
import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.event.KeyEvent;
import controlP5.*;

int[] rxbuf = new int[4096];  // Allocate buffer for receiving commands from controller
int rxwp = 0;                 // write pointer
int rxrp = 0;                 // read pointer
int rxd = 0;                  // location of last delimiter
int i = 0;                    // index
int lim = 4096;               // size of receiveBuffer

int val = 0;   // Store data from the serial port
int x = 0;     // Mouse pointer position
int y = 0;     // Mouse pointer position
int new_x = 0; // New mouse pointer position
int new_y = 0; // New mouse pointer position
int old_rxheading = 0;  // Previous rxheading value...

int x_window_limit = 1;
int y_window_limit = 0;

int myColor = color(255);
int c1, c2;
float n, n1;

// Other
Serial  port;  // Create object from Serial class
Robot   robot; // Create object from Robot class

// GUI
ControlP5 cp5;
DropdownList ddl_ports;             // available serial ports as a DropdownList
controlP5.Button b_comm_type;
controlP5.Button b_emulator_on;
controlP5.Button b_direction_invert;
controlP5.Button b_keyboard_mouse;
controlP5.Button b_heading_left;
controlP5.Button b_heading_stop;
controlP5.Button b_heading_right;

controlP5.Textlabel t_port_status;
controlP5.Textlabel t_heading_status;
controlP5.Textlabel t_desc_emulator_on;
controlP5.Textlabel t_desc_direction_invert;
controlP5.Textlabel t_desc_comm_type;
controlP5.Textlabel t_desc_emulator_type;
controlP5.Textlabel t_mouse_x;
controlP5.Textlabel t_mouse_x_value;
controlP5.Textlabel t_mouse_y;
controlP5.Textlabel t_mouse_y_value;
controlP5.Textlabel t_desc_x_min;
controlP5.Textlabel t_desc_x_max;

controlP5.Textfield t_in_x_min;
controlP5.Textfield t_in_x_max;

controlP5.Textlabel t_desc_sensitivity;
controlP5.Textlabel t_desc_speed;

// these variables will all get toggled when they are called to update the button text...
// so fill them with the opposite of the desired value
boolean emulator_on_toggle = true;        // 0 = off, 1 = on
boolean direction_invert_toggle = true;   // 0 = regular, 1 = inverted
boolean comm_type_toggle = false;         // 0 = RC, 1 = dongle
boolean keyboard_mouse_toggle = true;     // 0 = mouse, 1 = keyboard
int mouse_speed = 6;                      // fraction of display; movement per heading

float controller_sensitivity_value = 1;   // default value for sensitivity
float controller_speed_value = 5;         // default value for speed

String[] port_list;                // 
int port_number;                   // selected port
boolean port_selected = false;     // if a port has been chosen
boolean port_setup = false;        // if a port has been set up



void setup() {
  size(400,500);
  //frameRate(30);  // how often draw() gets called...
  
  // -------------------
  // GUI
   
  noStroke();
  
  cp5 = new ControlP5(this);
  
  // Text label for heading status
  t_heading_status = cp5.addTextlabel("heading_status", "", 10, 60); // 10, 160
  
  // Buttons to show status of command being received
  b_heading_left = cp5.addButton("left")
    .setValue(0)
    .setPosition(240, 57) // 240, 157
    .setSize(20, 20)
    .setId(1);
  
  b_heading_stop = cp5.addButton("stop")
    .setValue(0)
    .setPosition(270, 57) // 270, 157
    .setSize(20, 20)
    .setId(2);
  
  b_heading_right = cp5.addButton("right")
    .setValue(0)
    .setPosition(300, 57) // 300, 157
    .setSize(20, 20)
    .setId(3);
  
  // Text label for emulator on/off
  t_desc_emulator_on = cp5.addTextlabel("desc_emulator_on", "", 10, 100);
  
  // Button to start/stop toy controller emulation
  b_emulator_on = cp5.addButton("emulator_on")
    .setValue(0)
    .setPosition(240, 92)
    .setSize(50, 30)
    .setId(0);
  
  // Text label for direction invert
  t_desc_direction_invert = cp5.addTextlabel("desc_direction_invert", "", 10, 140);
  
  //
  b_direction_invert = cp5.addButton("direction_invert")
    .setValue(0)
    .setPosition(240, 132)
    .setSize(100, 30)
    .setId(0);
  
  // Text label for communication type
  t_desc_comm_type = cp5.addTextlabel("desc_comm_type", "", 10, 180); // 10, 140
  
  // Button to toggle between communication type - rc or toy
  b_comm_type = cp5.addButton("comm_type")
    .setValue(0)
    .setPosition(240, 172) // 240, 112
    .setSize(100, 30)
    .setId(4);
  
  // Text label for emulator type
  t_desc_emulator_type = cp5.addTextlabel("desc_emulator_type", "", 10, 220); // 10, 180
  
  // Button to toggle between keyboard and mouse emulation, 'keyboard_mouse'
  b_keyboard_mouse = cp5.addButton("keyboard_mouse")
    .setValue(0)
    .setPosition(240, 212) // 240, 112
    .setSize(100, 30)
    .setId(4);
  
  // text labels for current mouse position
  t_mouse_x = cp5.addTextlabel("mouse_x", "", 240, 252); // 212
  t_mouse_x_value = cp5.addTextlabel("mouse_x_value", "", 265, 252);
  t_mouse_y = cp5.addTextlabel("mouse_y", "", 240, 272);
  t_mouse_y_value = cp5.addTextlabel("mouse_y_value", "", 265, 272);
  
  // text label for x-min
  t_desc_x_min = cp5.addTextlabel("desc_x_min", "", 10, 320); // 280
  
  // text input for x-min
  t_in_x_min = cp5.addTextfield("in_x_min")
    .setValue(0)
    .setPosition(240, 312)
    .setSize(100, 30);
  t_in_x_min.setInputFilter(ControlP5.INTEGER);
  
  // text label for x-max
  t_desc_x_max = cp5.addTextlabel("desc_x_max", "", 10, 360); // 320
  
  // text input for x-max
  t_in_x_max = cp5.addTextfield("in_x_max")
    .setValue(0)
    .setPosition(240, 352)
    .setSize(100, 30);
  t_in_x_max.setInputFilter(ControlP5.INTEGER);
  
  
  // Text label for mouse sensitivity/ response speed
  t_desc_sensitivity = cp5.addTextlabel("desc_sensitivity","", 10, 420); // 10, 220
  
  // Slider to toggle mouse responsiveness
  cp5.addSlider("controller_sensitivity")
    .setMin(0)
    .setMax(10)
    .setValue(controller_sensitivity_value)
    .setSize(140, 30)
    .setPosition(240, 412) // 240, 212
    .setNumberOfTickMarks(11);
    
  // Text label for speed
  t_desc_speed = cp5.addTextlabel("desc_speed","", 10, 460); // 10, 220
  
  // Slider to toggle mouse responsiveness
  cp5.addSlider("controller_speed")
    .setMin(0)
    .setMax(10)
    .setValue(controller_speed_value)
    .setSize(140, 30)
    .setPosition(240, 452) // 240, 212
    .setNumberOfTickMarks(11);   


  // --- this must be down here...
  
  // Text label for status of port  
  t_port_status = cp5.addTextlabel("port_status","",10,35);
  
  // DropdownList to display the values
  //ports = cp5.addDropdownList("ports-list",10,30,180,84);
  ddl_ports = cp5.addDropdownList("dropdownlist_ports")
    .setPosition(10,30)
    .setWidth(380)
    .setHeight(140);
  
  // This function can be used to refresh the COM ports in the list
  customize_dropdownlist(ddl_ports);
  
  
  PFont pfont = createFont("Arial", 24, false);
  ControlFont font = new ControlFont(pfont, 12);
  cp5.setControlFont(font);
  

  
  t_port_status.setColorValue(0xFF0303);
  t_port_status.setValue("Not connected");

  t_heading_status.setColorValue(0xFF0303);
  t_heading_status.setValue("Controller heading status: ");
  
  t_desc_comm_type.setColorValue(0xFF0303);
  t_desc_comm_type.setValue("Toggle communication (not being used)");
  
  t_desc_emulator_on.setColorValue(0xFF0303);
  t_desc_emulator_on.setValue("Toggle emulator ON/OFF");
  
  t_desc_direction_invert.setColorValue(0xFF0303);
  t_desc_direction_invert.setValue("Invert direction?");
  
  t_desc_emulator_type.setColorValue(0xFF0303);
  t_desc_emulator_type.setValue("Toggle emulator Keyboard/Mouse");
  
  t_mouse_x.setColorValue(0xFF0303);
  t_mouse_x.setValue("x:");
  
  t_mouse_x_value.setColorValue(0xFF0303);
  t_mouse_x_value.setValue("0");
  
  t_mouse_y.setColorValue(0xFF0303);
  t_mouse_y.setValue("y:");
  
  t_mouse_y_value.setColorValue(0xFF0303);
  t_mouse_y_value.setValue("0");
  
  t_desc_x_min.setColorValue(0xFF0303);
  t_desc_x_min.setValue("Mouse horizontal left limit (x min):");
  
  t_in_x_min.setValue("0");
  
  t_desc_x_max.setColorValue(0xFF0303);
  t_desc_x_max.setValue("Mouse horizontal right limit (x max):");
  
  t_in_x_max.setValue("" + displayWidth);
  
  t_desc_sensitivity.setColorValue(0xFF0303);
  t_desc_sensitivity.setValue("Sensitivity (not implemented)");
  
  t_desc_speed.setColorValue(0xFF0303);
  t_desc_speed.setValue("Speed (not implemented)");
   
  //b_emulator_on.captionLabel()
  //  .setText("ON");
  
  cp5.getController("emulator_on")
    .getCaptionLabel();
  
  cp5.getController("direction_invert")
    .getCaptionLabel();
  
  //b_comm_type.captionLabel()
  //  .setText("Dongle");
  
  cp5.getController("comm_type")
    .getCaptionLabel();
  
  //b_keyboard_mouse.captionLabel()
  //  .setText("Keyboard");

  cp5.getController("keyboard_mouse")
    .getCaptionLabel();
  
  cp5.getController("left")
    .getCaptionLabel();
  b_heading_left.captionLabel()
    .setText("");
    
  cp5.getController("stop")
    .getCaptionLabel();
  b_heading_stop.captionLabel()
    .setText("");
    
  cp5.getController("right")
    .getCaptionLabel();
  b_heading_right.captionLabel()
    .setText("");
  
  /*
  cp5.getController("dropdownlist_ports")
    //.getCaptionLabel();
    .setFont(font)
    .toUpperCase(false);
   */
     
  // -------------------
  
  // DEBUG
  //println("Display width:     " + displayWidth);
  //println("Cursor increment:  " + displayWidth/mouse_speed);
  
  
  // -------------------
  
  // Setup the robot to move the mouse around...
  try {
    robot = new Robot();
  }
  catch(AWTException e) {
    e.printStackTrace();
  }
  
  // Center the mouse
  robot.mouseMove(displayWidth/2, displayHeight/2);
}



/** 
 *
 *
 */
void draw()
{
  background(255);
  
  int[] rxheading = {0, 0};
  int heading = 0;
  
  /**
   *
   * TODO
   * + Create an interface to choose the COM port
   * + Toggle between keyboard and mouse
   * + Show what is being activated
   * (+ Show accelerometer output?)
   * + Change mouse increment to change speed
   *
   *
   */
  
  //background(204);
  
  while(port_selected == true && port_setup == false)
  {
    // DEBUG
    //println("starting serial port");
    start_serial(port_list);
  }
  
  /**
   * Heading codes:
   *
   * 0: Nothing
   * 3: Forward (right, because we are in the Northern Hemisphere...)
   * 6: Reverse (left)
   */
  rxheading = processchar();
  if (rxheading[0] >= 0) {
    if (rxheading[1] == 3) {
      // heading = 1;
      if (direction_invert_toggle == false) {
        heading = 1;
      } else {
        heading = -1;
      }
      b_heading_right.setColorBackground(color(13, 208, 255));  // Active
      b_heading_left.setColorBackground(color(90));   // Inactive
      b_heading_stop.setColorBackground(color(90));   // Inactive
    } else if (rxheading[1] == 6) {
      //heading = -1;
      if (direction_invert_toggle == false) {
        heading = -1;
      } else {
        heading = 1;
      }
      b_heading_right.setColorBackground(color(90));  // Inactive
      b_heading_left.setColorBackground(color(13, 208, 255));   // Active
      b_heading_stop.setColorBackground(color(90));   // Inactive
    } else {
      heading = 0;
      b_heading_right.setColorBackground(color(90));  // Inactive
      b_heading_left.setColorBackground(color(90));   // Inactive
      b_heading_stop.setColorBackground(color(13, 208, 255));   // Active
    }
    //print(" " + rxheading);
  }
  
  /**
   * Control the Keyboard (0) or the Mouse (1) depending on the state
   * of the variable keyboard_mouse_toggle
   *
   */
  
  // If the emulator is not running, do nothing...
  if(!emulator_on_toggle) {
    return;
  }
  
  // Check if we are going to emulate the mouse or the keyboard...
  if (!keyboard_mouse_toggle) {
    // If we are moving the mouse pointer...
    PointerInfo a = MouseInfo.getPointerInfo();
    // Catch NullPointerException in case the pointer disappears...
    if (a != null) {
      Point b = a.getLocation();
      x = (int) b.getX();
      y = (int) b.getY();
      
      /*
      // Move the x-coordinate of the mouse baed on the controller
      new_x = x + (heading * mouse_speed * (displayWidth / 100));
      if (new_x < x_window_limit) {
        new_x = x_window_limit;
      } else if (new_x > (displayWidth - x_window_limit)) {
        new_x = displayWidth - x_window_limit;
      }
      */                 
      
      // Move the x-coordinate of the mouse 0-99
      if (rxheading[0] >= 0) {
        
        // invert if we are inverting...
        if (direction_invert_toggle == false) {
          // do nothing
        } else {
          rxheading[0] = 99 - rxheading[0];
        } 
        
        //if (abs(rxheading[0] - old_rxheading) > controller_sensitivity_value) {
        if (abs(rxheading[0] - old_rxheading) > 1) {
          
          new_x = (displayWidth * rxheading[0] / 100);
          
          //println("" + cp5.getController("in_x_min").getValue());
          
          //if (new_x < (int) cp5.getController("in_x_min").getText()) {
          //  new_x = (int) cp5.getController("in_x_min").getText();
          //} else if (new_x > (int) cp5.getController("in_x_max").getText()) {
          //  new_x = (int) cp5.getController("in_x_max").getText();
          //}
          
          if (new_x < Integer.parseInt(t_in_x_min.getText())) {
            new_x = Integer.parseInt(t_in_x_min.getText());
          } else if (new_x > Integer.parseInt(t_in_x_max.getText())) {
            new_x = Integer.parseInt(t_in_x_max.getText());
          }
          
          old_rxheading = rxheading[0];
        
      } else {
          new_x = x;
        }
        //println(new_x);
        //new_x = x;
      } else {
        new_x = x;
      }
      //if (new_x < x_window_limit) {
      //  new_x = x_window_limit;
      //} else if (new_x > (displayWidth - x_window_limit)) {
      //  new_x = displayWidth - x_window_limit;
      //}
      
      // Keep the y-coordinate the same
      new_y = y;
      
      t_mouse_x_value.setValue(""+new_x);
      t_mouse_y_value.setValue(""+new_y);
      
      // This is a little choppy...
      robot.mouseMove(new_x, new_y);
    }
  } else if (keyboard_mouse_toggle) {
    // Toggle the keys
    if (heading == 1) {
      robot.keyPress(KeyEvent.VK_RIGHT);
      robot.keyRelease(KeyEvent.VK_RIGHT);
    } else if (heading == -1) {
      robot.keyPress(KeyEvent.VK_LEFT);
      robot.keyRelease(KeyEvent.VK_LEFT);
    } else {
      // Do nothing...
      ;
    }
  }
  
  // TODO: If we are moving the keys...
  // move the keys...
  
}


/** 
 * The method serialEvent will place newly received characters in
 * the receive buffer. This will wrap around the buffer.
 *
 */
void serialEvent(Serial port)
{
  i = ((i + 1) % lim);
  
  if (i != rxrp) {
    rxbuf[i] = port.read();
    //byte[] in = port.readBytesUntil(',');
    rxwp = i;
  } else {
    // Dropped character
  }
}


/**
 * The method getcharnb will attempt to get the next character from
 * the receive buffer if one is available. If not, it will NOT block.
 *
 * return (-1=Failure, Otherwise=Successful)
 */
public int getcharnb()
{
  int res;
  
  if (rxrp != rxwp) {
    res = rxbuf[rxrp];
    rxrp = ((rxrp + 1) % lim);
  } else {
    res = -1;
  }
  
  return res;
}


/** 
 * The method processchar will check the receive buffer for the terminator (',')
 * and if a terminator is received, will look a few indices back in the receive
 * buffer for the heading code
 * 
 * Expected response:
 * [-]  ,          Delimeter    44
 * [0]  G          Gain         71
 * [1]  <0-9>      ...          was... <0,1,2>      48,49,50
 * [2]  <0-9>      ...
 * [3]  <0-9>      ...
 * [4]  <0-9>      ...
 * [5]  H          Heading      72
 * [6]  <0,3,6>                 48,51,54
 * [7]  ,          Delimiter    44
 *
 *
 * return (-1=Failure, Otherwise=Success)
 */
public int[] processchar()
{
  int rxchar;
  char[] throttle = new char[4];
  int temp_tens;
  int temp_ones;
  int temp;
  int[] res = {0, 0};
  
  rxchar = getcharnb();
  
  if ((rxchar == 44) && (rxrp > 4)) {
    // check that we're past the first delimeter...
    if (rxd > 0) {
      if (rxbuf[rxrp - 3] == 72) {
        // 0-99
        temp_tens = rxbuf[rxrp - 5] - 48;
        temp_ones = rxbuf[rxrp - 4] - 48;
        temp = 10*temp_tens + temp_ones;
        // JBS - if using the controller's location (0-99), return this:
        res[0] = temp;
        
        // H received... get the heading code...
        // JBS - if using the controller's heading code, return this:
        res[1] = rxbuf[rxrp - 2] - 48;
        
        
        //DEBUG
        //println(rxd + ":" + temp);
        
        /*
        if (rxbuf[rxd + 1] == 71) {
          // G received... get the throttle...
          for (int i = 0; i < 4; i++)
          {
            if (rxbuf[rxd + 2 + i] == 72) {
              break;
            }
            temp = rxbuf[rxd + 2 + i] - 48;
            println(rxd + ":" + temp);
            //throttle[i] = (char) ('0' + (rxbuf[rxd + 2 + i] - 48));
          }
        }
        */
      
        // done processing... store as the last received delimeter...
        rxd = rxrp;
      } else {
        res[0] = -1;
        res[1] = -1;
      }
    } else {
      // store the last received delimeter...
      rxd = rxrp;
    }
  } else {
    res[0] = -1;
    res[1] = -1;
  }
  //println(res);
  return res;
}


/** 
 * The function start_serial initializes the selected port
 *
 */
void start_serial(String[] port_list)
{  
  port_setup = true;
  
  try {
    port = new Serial(this, port_list[port_number], 115200);
    //port.bufferUntil(',');
  }
  catch(RuntimeException e) {
    port_setup = false;
    port_selected = false;
    // This color does not update...
    t_port_status.setColorValue(0xFF0000);
    t_port_status.setValue("Error: cannot connect to port");
  }
  
  // Update port settings
  if (port_setup == true) {
    t_port_status.setColorValue(0x030303);
    t_port_status.setValue("Connected to port " + port_list[port_number]);
    // Send a carriage return to the port because sometimes it stops printing...
    port.write(13);
  }
}


/** 
 * GUI features
 *
 */
 
 
/* Dropdownlist event */
public void controlEvent(ControlEvent theEvent)
{
  //println(theEvent.getController().getName());
  
  if (theEvent.isGroup())
  {
    // Store the value of which box was selected
    float p = theEvent.group().value();
    port_number = int(p);
    
    // TODO: stop the serial connection and start a new one
    port_selected = true;
  }
}

/* Function emulator_on */
public void emulator_on(int theValue)
{
  emulator_on_toggle = !emulator_on_toggle;
  cp5.controller("emulator_on").setCaptionLabel((emulator_on_toggle == true) ? "ON":"OFF");
  //println("on ?:" + emulator_on_toggle);
  if (emulator_on_toggle)
  {
    // The emulator is turned ON, send a keystroke to the serial port in case data has paused...
    port.write(13);
  }
}

/* Function direction_invert */
public void direction_invert(int theValue)
{
  direction_invert_toggle = !direction_invert_toggle;
  cp5.controller("direction_invert").setCaptionLabel((direction_invert_toggle == true) ? "INVERT":"NORMAL");
  //println("dongle ?:" + comm_type_toggle);
}

/* Function comm_type */
public void comm_type(int theValue)
{
  comm_type_toggle = !comm_type_toggle;
  cp5.controller("comm_type").setCaptionLabel((comm_type_toggle == true) ? "DONGLE":"RC TOY");
  //println("dongle ?:" + comm_type_toggle);
}


/* Function keyboard_mouse */
public void keyboard_mouse(int theValue)
{
  keyboard_mouse_toggle = !keyboard_mouse_toggle;
  cp5.controller("keyboard_mouse").setCaptionLabel((keyboard_mouse_toggle == true) ? "Keyboard":"Mouse");
  //println("keyboard ?:" + keyboard_mouse_toggle);
}

/* Function in_x_min text field */
public void in_x_min(float theValue)
{
  //cp5.controller("in_x_min").setValue("" + theValue);
  t_in_x_min.setValue("" + theValue);
}

/* Function in_x_max text field */
public void in_x_max(float theValue)
{
  //cp5.controller("in_x_max").setValue("" + theValue);
  t_in_x_max.setValue("" + theValue);
}

/* Function mouse sensitivity */
public void controller_sensitivity(float controller_sensitivity_value)
{
  controller_sensitivity_value = cp5.getController("controller_sensitivity").getValue();
}

public void controller_speed(float controller_speed_value)
{
  controller_speed_value = cp5.getController("controller_speed").getValue();
}


/* Setup the DropdownList */
void customize_dropdownlist(DropdownList ddl)
{
  //
  ddl.setBackgroundColor(color(200));
  ddl.setItemHeight(20);
  ddl.setBarHeight(20);
  ddl.captionLabel().set("Select COM port");
  ddl.captionLabel().style().marginTop = 3;
  ddl.captionLabel().style().marginLeft = 3;
  ddl.valueLabel().style().marginTop = 3;
  
  // Store the serial port list in the string port_list (char array)
  port_list = port.list();
  
  for (int i = 0; i < port_list.length; i++) {
    ddl.addItem(port_list[i], i);
  }
  
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}
