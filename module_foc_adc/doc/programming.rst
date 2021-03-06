Programming Guide
=================

Key Files
---------

   * ``adc_client.xc``: Contains the xC implementation of the ADC Client API
   * ``adc_server.xc``: Contains the xC implementation of the ADC Server task

Usage
-----

The following 2 functions are designed to be called from an xC file.

   * ``foc_adc_get_parameters()`` Client function designed to be called from an xC file each time a new set of ADC parameters are required.
   * ``foc_adc_7265_triggered()``, Server function designed to be called from an xC file. It runs on its own core, and receives data from one ADC_7265 chip. The chip multiplexes together the data from all motors.

The following ADC definitions are required. These are set in ``app_global.h``

   * PWM_RES_BITS 12 // Number of bits used to define number of different PWM pulse-widths
   * PLATFORM_REFERENCE_HZ // Platform Reference Frequency
   * ADC_FILTER // ADC filter switch (0 == Off)
   * MAX_SPEC_RPM // Maximum specified motor speed

Test Applications
-----------------

This module has a test harness called ``Analogue-to-Digital Convertion (ADC) Test Harness`` which can be found in the xSOFTip Explorer pane.

To get started with this application, run through the instructions in the quick-start guide for the test harness. More details about using this test harness are given below.

Makefile
........

The Makefile is found in the top level directory of the application (e.g. app_test_adc)

The application is for the simulator. 
However the platform being simulated is a Motor control board.
The Makefile TARGET variable needs to be set to the Motor control board being used.
E.g. If the platform configuration file is XP-MC-CTRL-L2.xn, then
TARGET = XP-MC-CTRL-L2

The maximum number of motors supported in currently 2, this is set in app_global.h: e.g.
#define NUMBER_OF_MOTORS 2

Running the application with the Command Line Tools
...................................................

Move to the top level directory of the application (e.g. app_test_adc), and type

   * xmake clean
   * xmake all

To start the test type

   * xsim --plugin LoopbackPort.dll "-port tile[1] XS1_PORT_1G 1 0 -port tile[1] XS1_PORT_1C 1 0 -port tile[1] XS1_PORT_1H 1 0 -port tile[1] XS1_PORT_1D 1 0 -port tile[1] XS1_PORT_1I 1 0 -port tile[1] XS1_PORT_1E 1 0 -port tile[1] XS1_PORT_1J 1 0 -port tile[1] XS1_PORT_1F 1 0" bin/app_test_adc.xe

Test results will be printed to standard-out.
Remember this is a simulator, and is very slow.
The default test takes about a minute to run.
The 'slow' test make take over an hour.

For a explanation of the test results refer to the quick-start guide in doc_quickstart/adc/index.rst

Trouble-shooting
................

**The information in the 'check results' column may disappear**: This and almost any other problem are probably due to not setting the port configuration correctly when calling xSIM.

**The printout may stop** Depending on the speed of your PC (or Mac), there can be upto 1 minute gap between printed lines.

Example Usage In A Motor Control Loop
-------------------------------------

The ADC component can be used in conjunction with the PWM component. For more detail on the PWM component refer to the quick-start guide ``Pulse Width Modulation (PWM) Simulator Testbench``. The code example below demonstrates how to use the PWM-to-ADC trigger to synchronise the ADC sampling to the PWM pulse. It shows part of a main.xc file. In here a set of ``par`` statements are used to run the PWM server and the ADC Server in parallel with a function called ``run_motor``, which contains all the code for a motor control loop.

::

  // PWM ports
  on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_hi[NUMBER_OF_MOTORS][NUM_PWM_PHASES] 
    = {  {PORT_M1_HI_A, PORT_M1_HI_B, PORT_M1_HI_C} ,{PORT_M2_HI_A, PORT_M2_HI_B, PORT_M2_HI_C} };
  on tile[MOTOR_TILE]: buffered out port:32 pb32_pwm_lo[NUMBER_OF_MOTORS][NUM_PWM_PHASES] 
    = {  {PORT_M1_LO_A, PORT_M1_LO_B, PORT_M1_LO_C} ,{PORT_M2_LO_A, PORT_M2_LO_B, PORT_M2_LO_C} };
  on tile[MOTOR_TILE]: clock pwm_clk[NUMBER_OF_MOTORS] = { XS1_CLKBLK_5 ,XS1_CLKBLK_4 };
  on tile[MOTOR_TILE]: in port p16_adc_sync[NUMBER_OF_MOTORS] = { XS1_PORT_16A ,XS1_PORT_16B }; // NB Dummy port
  
  // ADC ports
  on tile[MOTOR_TILE]: buffered in port:32 pb32_adc_data[NUM_ADC_DATA_PORTS] 
    = { PORT_ADC_MISOA ,PORT_ADC_MISOB }; 
  on tile[MOTOR_TILE]: out port p1_adc_sclk = PORT_ADC_CLK; // 1-bit port connecting to external ADC serial clock
  on tile[MOTOR_TILE]: port p1_ready = PORT_ADC_CONV; // 1-bit port used to as ready signal for pb32_adc_data ports and ADC chip
  on tile[MOTOR_TILE]: out port p4_adc_mux = PORT_ADC_MUX; // 4-bit port used to control multiplexor on ADC chip
  on tile[MOTOR_TILE]: clock adc_xclk = XS1_CLKBLK_2; // Internal XMOS clock
  
  int main ( void ) // Program Entry Point
  {
    chan c_pwm2adc_trig[NUMBER_OF_MOTORS];
    chan c_pwm[NUMBER_OF_MOTORS];
    streaming chan c_adc_cntrl[NUMBER_OF_MOTORS];

  
    par
    {
      on tile[MOTOR_TILE] : 
      {
        par
        {
          // Loop through all motors
          par (int motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
          {
            run_motor( motor_cnt ,c_pwm[motor_cnt] ,c_adc_cntrl[motor_cnt] );
  
            foc_pwm_do_triggered( motor_cnt ,c_pwm[motor_cnt] ,pb32_pwm_hi[motor_cnt] ,pb32_pwm_lo[motor_cnt] 
              ,c_pwm2adc_trig[motor_cnt] ,p16_adc_sync[motor_cnt] ,pwm_clk[motor_cnt] );
          } // par motor_cnt

          foc_adc_7265_triggered( c_adc_cntrl ,c_pwm2adc_trig ,pb32_adc_data ,adc_xclk ,p1_adc_sclk ,p1_ready ,p4_adc_mux );
        } // par
      } // on tile[MOTOR_TILE]
    } // par
  
    return 0;
  } // main
