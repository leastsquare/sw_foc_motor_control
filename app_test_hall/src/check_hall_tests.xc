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

#include "check_hall_tests.h"

/*****************************************************************************/
static void init_check_data( // Initialise check data for Hall tests
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
	int motor_cnt; // counts Motors 


	init_common_data( chk_data_s.common ); // Initialise data common to Generator and Checker

	safestrcpy( chk_data_s.padstr1 ,"                                             " );
	safestrcpy( chk_data_s.padstr2 ,"                              " );

	chk_data_s.fail_cnt = 0; // Clear count of failed tests.

	chk_data_s.print = PRINT_TST_HALL; // Set print mode
	chk_data_s.dbg = 0; // Set debug mode

	// Clear error and test accumulators
	for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
	{
		chk_data_s.all_errs[motor_cnt] = 0;
		chk_data_s.all_tsts[motor_cnt] = 0;
	} // for motor_cnt

} // init_motor_checks
/*****************************************************************************/
static void init_motor_checks( // Initialise Hall parameter structure
	CHECK_HALL_TYP &chk_data_s, // Reference to structure containing test check data
	int motor_id	// Unique Motor identifier
)
{
	int comp_cnt; // Counter for Test Vector components


	chk_data_s.id = motor_id; // Assign Motor identifier

	chk_data_s.err_cnt = 0; // Clear count-down counter used in error_status test
	chk_data_s.err_chk = ERR_OFF; // Initialise expected error_status test result

	chk_data_s.orig_cnt = 0; // Clear count-down counter used in origin-bit test
	chk_data_s.orig_chk = ORIG_OFF; // Initialise expected origin-bit test result

	chk_data_s.curr_params.hall_val = 0;
	chk_data_s.curr_params.err = 0; // No Errors

	chk_data_s.prev_params = chk_data_s.curr_params; // Initialise previous parameter values

	// Clear error and test counters for current motor
	for (comp_cnt=0; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
	{
		chk_data_s.motor_errs[comp_cnt] = 0; 
		chk_data_s.motor_tsts[comp_cnt] = 0; 
	} // for comp_cnt

} // init_motor_checks
/*****************************************************************************/
static void print_hall_parameters( // Print Hall parameters
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );

	printint( chk_data_s.id );
	printstr( ":  E=" );
	printint( chk_data_s.curr_params.err );
	printstr( "  H=" );
	printint( chk_data_s.curr_params.hall_val );
	printcharln(' ');
	release_lock(); // Release Display Mutex
} // print_hall_parameters
/*****************************************************************************/
static void check_hall_error_status( // Check for correct update of error status due to Hall error-bit changes
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
	int inp_err = chk_data_s.curr_params.err; // local copy of error_status parameter


	chk_data_s.motor_tsts[ERROR]++;

	// Check for expected value
	if (inp_err == chk_data_s.err_chk)
	{ // Found expected value (Test passed)
		chk_data_s.err_cnt = 0; // Clear Time-out
	} // if (inp_err == chk_data_s.err_chk)
	else
	{ // Not expected value
		if (0 < chk_data_s.err_cnt)
		{ // test NOT yet timed-out
			chk_data_s.err_cnt--; // Decrement 'timer'
		} // if (0 < chk_data_s.err_cnt)
		else
		{ // test timed-out (Test failed)
			chk_data_s.motor_errs[ERROR]++;

			acquire_lock(); // Acquire Display Mutex
			printcharln(' ');
			printstr( chk_data_s.padstr1 );

			switch( chk_data_s.curr_vect.comp_state[ERROR] )
			{
				case ERR_OFF:
					printstrln("ERR_OFF FAILURE");
				break; // case ERR_OFF:
		
				case ERR_ON: // Start error_status test
					printstrln("ERR_ON FAILURE");
				break; // case ERR_ON:
		
				default:
					printstrln("ERROR: Unknown Hall Error-state");
					assert(0 == 1);
				break; // default:
			} // switch( chk_data_s.curr_vect.comp_state[ERROR] )

			release_lock(); // Release Display Mutex

			chk_data_s.err_cnt = 0; //  // Clear Time-out
		} // if (0 < chk_data_s.err_cnt)
	} // else !(inp_err == chk_data_s.err_chk)

} // check_hall_error_status
/*****************************************************************************/
static void check_hall_spin_direction( // Check correct update of Hall spin direction
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
#ifdef MB
	int inp_vel = chk_data_s.curr_params.veloc; // local copy of angular_velocity parameter


	switch( chk_data_s.curr_vect.comp_state[SPIN] )
	{
		case CLOCK: // Clock-wise
			chk_data_s.motor_tsts[SPIN]++;
			if (0 > inp_vel)
			{
				chk_data_s.motor_errs[SPIN]++;

				acquire_lock(); // Acquire Display Mutex
				printcharln(' ');
				printstr( chk_data_s.padstr1 );
				printstrln("Clock-Wise FAILURE");
				release_lock(); // Release Display Mutex
			} // if (0 > inp_vel)
		break; // case CLOCK:

		case ANTI: // Anti-clockwise
			chk_data_s.motor_tsts[SPIN]++;
			if (0 < inp_vel)
			{
				chk_data_s.motor_errs[SPIN]++;

				acquire_lock(); // Acquire Display Mutex
				printcharln(' ');
				printstr( chk_data_s.padstr1 );
				printstrln("Anti-Clock FAILURE");
				release_lock(); // Release Display Mutex
			} // if (0 < inp_vel)
		break; // case ANTI:

		default:
			acquire_lock(); // Acquire Display Mutex
			printcharln(' ');
			printstr( chk_data_s.padstr1 );
			printstrln("ERROR: Unknown Hall Spin-state");
			release_lock(); // Release Display Mutex
			assert(0 == 1);
		break; // default:
	} // switch( chk_data_s.curr_vect.comp_state[SPIN] )
#endif //MB~

} // check_hall_spin_direction
/*****************************************************************************/
static void check_hall_parameters( // Check all Hall parameters
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
	check_hall_error_status( chk_data_s ); // Check Hall error status

	check_hall_spin_direction( chk_data_s ); // Check Hall spin direction
} // check_hall_parameters
/*****************************************************************************/
static int parameter_compare( // Check if 2 sets of Hall parameters are different
	HALL_PARAM_TYP &params_a,	// Structure containing 1st set of Hall parameters
	HALL_PARAM_TYP &params_b	// Structure containing 2nd set of Hall parameters
) // return TRUE (1) if sets are different, FALSE(0) if equal
{
	if (params_a.hall_val != params_b.hall_val) return 1;	// Check Hall value

	if (params_a.err != params_b.err) return 1;	// Check error_status

	return 0; // No differences found
} // parameter_compare
/*****************************************************************************/
static void get_new_hall_client_data( // Get next set of Hall parameters
	CHECK_HALL_TYP &chk_data_s, // Reference to structure containing test check data
	streaming chanend c_hall // Hall channel between Client and Server
)
{
	int do_test = 0;	// Flag set when next test required


	// Get new parameter values from Client function under test
	foc_hall_get_parameters( chk_data_s.curr_params ,c_hall );

	// Check for change in non-speed parameters
	do_test = parameter_compare( chk_data_s.curr_params ,chk_data_s.prev_params ); 

	// Check for parameter change
	if (do_test)
	{ // Parameters changed

		if (chk_data_s.print)
		{
			print_hall_parameters( chk_data_s ); // Print new Hall parameters
		} // if (chk_data_s.print)

		// Check if this current test vector is valid
		if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])
		{
			check_hall_parameters( chk_data_s ); // Check new Hall parameters
		} // if (VALID == chk_data_s.curr_vect.comp_state[CNTRL])

		chk_data_s.prev_params = chk_data_s.curr_params; // Store previous parameter values
	} // if (chk_data_s.curr_params.theta != chk_data_s.curr_params.theta)
} // get_new_hall_client_data
/*****************************************************************************/
static void process_new_test_vector( // Process new test vector
	CHECK_HALL_TYP &chk_data_s // Reference to structure containing test check data
)
{
	int change = 0; // Clear flag indicating change in test vector detected


	// Check if error_status test
	if (chk_data_s.curr_vect.comp_state[ERROR] != chk_data_s.prev_vect.comp_state[ERROR])
	{ // Initialise error_status test

		// Check if test already running
		if (0 < chk_data_s.err_cnt)
		{
			acquire_lock(); // Acquire Display Mutex
			printstr( chk_data_s.padstr1 );
			printstrln("ERROR: Previous Error-status test NOT completed");
			release_lock(); // Release Display Mutex
			assert(0 == 1); // Abort
		} // if (0 < chk_data_s.err_cnt)
		else
		{ // Start new test
			chk_data_s.err_chk = chk_data_s.curr_vect.comp_state[ERROR]; // Expected error_status value
			chk_data_s.err_cnt = ERR_TIMEOUT; // Start count-down
		} // else !(0 < chk_data_s.err_tst)

		change = 1; // Set flag indicating change in test vector detected
	} // if (chk_data_s.curr_vect.comp_state[ERROR] != chk_data_s.prev_vect.comp_state[ERROR])

	// Check if test vector changed
	if (change)
	{
		chk_data_s.prev_vect = chk_data_s.curr_vect; // Update previous test-vector
	} // if (change)

	if (chk_data_s.print)
	{
		print_test_vector( chk_data_s.common ,chk_data_s.curr_vect ,chk_data_s.padstr1 ); // Print new test vector details
	} // if (chk_data_s.print)

} // process_new_test_vector
/*****************************************************************************/
static void check_motor_hall_client_data( // Display Hall results for one motor
	CHECK_HALL_TYP &chk_data_s, // Reference to structure containing test check data
	streaming chanend c_tst, // Channel for receiving test vectors from test generator
	streaming chanend c_hall // Hall channel between Client and Server
)
{
	timer chronometer; // XMOS timer
	int comp_cnt; // Counter for Test Vector components
	int do_loop = 1;   // Flag set until loop-end condition found 
	int motor_errs = 0;   // Preset flag to NO errors for current motor
	int motor_tsts = 0;   // Clear test ccounter for current motor


	chronometer :> chk_data_s.time; // Get start time
	chronometer when timerafter(chk_data_s.time + (MICRO_SEC << 1)) :> chk_data_s.time; // Wait for Test Generation to Start

	acquire_lock(); // Acquire Display Mutex
	printcharln(' ');
	printstr( chk_data_s.padstr1 );
	printstr("Start Checks For Motor_"); printintln( chk_data_s.id ); 
	release_lock(); // Release Display Mutex

	c_tst :> chk_data_s.curr_vect; // Initialise test-vector structure with 1st test

	// special case: initialisation for first speed test
  chk_data_s.prev_vect = chk_data_s.curr_vect;

	// Loop until end condition found
	while( do_loop )
	{
		select {
			// Service any change on test channel
			case c_tst :> chk_data_s.curr_vect :
				// New test vector detected.
				process_new_test_vector( chk_data_s ); // Process new test vector

				// Check if testing has ended for current motor
				if (QUIT == chk_data_s.curr_vect.comp_state[CNTRL])
				{
					do_loop = 0; // Error flag signals end-of-loop
				} // if (QUIT == chk_data_s.curr_vect.comp_state[CNTRL])
			break; // c_tst 

			// Pace Hall Client requests, so as NOT to overload Hall server
			case chronometer when timerafter(chk_data_s.time + HALL_PERIOD) :> chk_data_s.time :
				get_new_hall_client_data( chk_data_s ,c_hall ); // Request data from server & check

				if (0 == chk_data_s.print)
				{
					printchar('.'); // Progress indicator
				} // if (0 == chk_data_s.print)
			break; // case chronometer
		} // select
	} // while( loop )

	// Update error statistics for current motor
	for (comp_cnt=0; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
	{
		motor_errs += chk_data_s.motor_errs[comp_cnt]; 
		motor_tsts += chk_data_s.motor_tsts[comp_cnt]; 
	} // for comp_cnt

	chk_data_s.all_errs[chk_data_s.id] += motor_errs;
	chk_data_s.all_tsts[chk_data_s.id] += motor_tsts;

	acquire_lock(); // Acquire Display Mutex
	printcharln(' ');
	printstr( chk_data_s.padstr1 );
	printint( motor_tsts );
	printstrln( " tests run" );

	// Check if this motor had any errors
	if (motor_errs)
	{
		printstr( chk_data_s.padstr1 );
		printint( motor_errs );
		printstrln( " tests FAILED, as follows:" );

		// Print Vector Component Names
		for (comp_cnt=0; comp_cnt<NUM_VECT_COMPS; comp_cnt++)
		{
			printstr( chk_data_s.padstr1 );
			printstr( chk_data_s.common.comp_data[comp_cnt].comp_name.str );
			printstr(" : ");
			printint( chk_data_s.motor_tsts[comp_cnt] );
			printstr( " tests run" );

			if (chk_data_s.motor_errs[comp_cnt])
			{
				printstr( ", " );
				printint( chk_data_s.motor_errs[comp_cnt] );
				printstr(" FAILURES");
			} // if (chk_data_s.motor_errs[comp_cnt])
			printcharln(' ');
		} // for comp_cnt
	} // if (motor_errs)
	else
	{
		printstr( chk_data_s.padstr1 );
		printstr( "All Motor_" );
		printint( chk_data_s.id );
 		printstrln( " Tests PASSED" );
	} // else !(motor_errs)

	release_lock(); // Release Display Mutex

	chronometer when timerafter(chk_data_s.time + MILLI_SEC) :> chk_data_s.time; // Wait for Test Generation to End
} // check_motor_hall_client_data
/*****************************************************************************/
void check_all_hall_client_data( // Display Hall results for all motors
	streaming chanend c_tst, // Channel for receiving test vectors from test generator
	streaming chanend c_hall[] // Array of Hall channel between Client and Server
)
{
	CHECK_HALL_TYP chk_data_s; // Structure containing test check data
	int motor_cnt; // counts Motors 
	int errs_all = 0;	// Preset flag to NO errors for all motors
	int tsts_all = 0;	// Clear test counter for all motors


	init_check_data( chk_data_s ); // Initialise check data

	// Loop through motors, so we can print results serially
	for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
	{
		init_motor_checks( chk_data_s ,motor_cnt ); // Initialise Hall parameter structure

		check_motor_hall_client_data( chk_data_s ,c_tst ,c_hall[motor_cnt] );
	} // for motor_cnt

	acquire_lock(); // Acquire Display Mutex
	printstr( chk_data_s.padstr1 );
	printstrln( "Test Check Ends " );

	// Update error statistics for all motors
	for (motor_cnt=0; motor_cnt<NUMBER_OF_MOTORS; motor_cnt++)
	{
		errs_all += chk_data_s.all_errs[motor_cnt]; 
		tsts_all += chk_data_s.all_tsts[motor_cnt]; 
	} // for motor_cnt

	printint( tsts_all );
	printstrln( " tests run" );

	// Check for any errors
	if (errs_all)
	{
		printint( errs_all );
		printstr( " TESTS FAILED");
		printstrln( "   (See individual motors for details)" );
	} // if (errs_all)
	else
	{
		printstrln( "ALL TESTS PASSED" );
	} // else !(errs_all)

	printcharln( ' ' );
	release_lock(); // Release Display Mutex
} // check_all_hall_client_data
/*****************************************************************************/
