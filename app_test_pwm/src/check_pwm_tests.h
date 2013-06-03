/**
 * The copyrights, all other intellectual and industrial 
 * property rights are retained by XMOS and/or its licensors. 
 * Terms and conditions covering the use of this code can
 * be found in the Xmos End User License Agreement.
 *
 * Copyright XMOS Ltd 2013
 *
 * In the case where this code is a modification of existing code
 * under a separate license, the separate license terms are shown
 * below. The modifications to the code are still covered by the 
 * copyright notice above.
 **/                                   

#ifndef _CHECK_PWM_TESTS_H_
#define _CHECK_PWM_TESTS_H_

#include <stdlib.h>

#include <xs1.h>
#include <assert.h>
#include <print.h>
#include <safestring.h>

#include "app_global.h"
#include "use_locks.h"
#include "test_pwm_common.h"

/** Define No. of buffers used for storing PWM widths */
#define NUM_INP_BUFS 2 // No. of input buffers used for storing PWM widths

/** Define allowed PWM-width delay */
#define WID_TIMEOUT 2 // Allowed PWM-width delay

/** Different PWM Phases */
typedef enum PWM_LEG_ETAG
{
  HI_LEG = 0,	// High-Leg
  LO_LEG,		  // Low-Leg
  NUM_PWM_LEGS    // Handy Value!-)
} PWM_LEG_ENUM;

/** Type containing all check data */
typedef struct CHECK_PWM_TAG // Structure containing PWM check data
{
	COMMON_PWM_TYP common; // Structure of PWM data common to Generator and Checker
	char padstr1[STR_LEN]; // Padding string used to format display output
	char padstr2[STR_LEN]; // Padding string used to format display output
	TEST_VECT_TYP curr_vect; // Structure of containing current PWM test vector (PWM conditions to be tested)
	TEST_VECT_TYP prev_vect; // Structure of containing previous PWM test vector
	int motor_errs[NUM_VECT_COMPS]; // Array of error counters for one motor
	int motor_tsts[NUM_VECT_COMPS]; // Array of test counters for one motor
	unsigned time[NUM_PWM_LEGS]; // array of times when width receivedfor each PWM-leg 
	int wid_chk;	// width check value
	int wid_cnt;	// Counter used in width test
	unsigned curr_val; // current PWM value
	unsigned prev_val; // previous PWM value
	int fail_cnt;	// Counter of failed tests
	int speed_sum; // Accumulator for speed tests
	int speed_num; // No of accumulations for speed tests
	int print;  // Print flag
	int dbg;  // Debug flag
} CHECK_PWM_TYP;

/*****************************************************************************/
/** Display PWM results for all motors
 * \param c_tst // Channel for sending test vecotrs to test checker
 * \param p32_tst_hi, // array of PWM ports (High side)  
 * \param p32_tst_lo, // array of PWM ports (Low side)   
 * \param c_adc_trig // ADC trigger channel 
 */
void check_all_pwm_client_data( // Display PWM results for all motors
	streaming chanend c_tst, // Channel for receiving test vectors from test generator
	buffered in port:32 p32_tst_hi[], // array of PWM ports (High side)  
	buffered in port:32 p32_tst_lo[], // array of PWM ports (Low side)   
	chanend c_adc_trig // ADC trigger channel 
);
/*****************************************************************************/
#endif /* _CHECK_PWM_TESTS_H_ */
