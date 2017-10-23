// $YOUR_NAME
// $YOUR_ANDREW_ID
// top.sv
`default_nettype none

`ifndef STRUCTS
`define STRUCTS

  typedef enum logic [3:0] {START    = 4'h1,
                            ENTER    = 4'h2,
                            ARITH_OP = 4'h4,
                            DONE     = 4'h8} oper_t;

  typedef struct packed { // what appears at the data input
    oper_t       op;
    logic [15:0] payload;
    } keyIn_t;

`endif


//////////////////////
////             ////
////    top     ////
////           ////
//////////////////

module top();

    //inputs to calculator
    logic    clock, reset_N;
    keyIn_t  data;

    //outputs from calculator
    logic [15:0]  result;
    logic         stackOverflow, unexpectedDone, protocolError, dataOverflow,
                correct, finished;

    logic [7:0][15:0] stackOut;

    //calculator instantiation
    TA_calc  brokenCalc(.*);

    logic [15:0] checkResult;
    int correctRes;

    //the system clock
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    //this task should contain your testbench
    task runTestbench(input int phase);
      begin
        //test for functional "correct", "finished", and ADD
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0005; // stack: 5
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h0003; // stack: 3 5
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; // add
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; // done
        @(posedge clock);
        assert(correct);
        assert(finished);
        assert(result == 8) $info("(5 + 3 == 8) checked");
        else $error("result is %d, should be 8", result);

        $display("CHECKING [8 6 -]. SHOULD BE CORRECT...");
        //checking sub 1234 - 1233 reseult == 1 which should be correct
        checkResult = 16'd1;
        correctRes = 0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'd7;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'd6; // stack 1234 1233
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= DONE;
        correctRes <= 1;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes <= 0;
        //correctRes = 1'b0;
        @(posedge clock);


        //checking add 8000 8000, reseult == 0 which is be correct but overflow
        $display("CHECKING [8000 8000 +] DATAOVERFLOW SHOULD OCCUR...");
        checkResult = 16'h0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h8000;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h8000; // stack 1234 1233
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes <= 2;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        assert(dataOverflow);
        correctRes <= 0;
        @(posedge clock);

        $display("CHECKING [1 2 3 4 + + +]. SHOULD BE CORRECT...");
        // checking 1 2  3  4 + + + = 10
        checkResult = 16'ha;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0001;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [1 2 3 4 5 + + + +]. SHOULD BE CORRECT......");
        // checking 1 2 3 4 5 + + + + = 10
        checkResult = 16'd15;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 1 2 3 4 5
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        //assert(stackOverflow) else $error("Stack overflow should have occured!");
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);

        $display("TRYING TO POP MORE ELEMENTS THAN ON THE STACK SO PROTOCOLERROR SHOULD OCCUR......");
        //check for too many pops
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 1 2 3 4 5
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        assert(protocolError) $info("Protocol Error occured");
          else $error("PROTOCOL ERROR SHOULD HAVE OCCURED FOR TOO MANY POPS!");
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes = 2;
        @(posedge clock);
        correctRes = 0;

        $display("CHECKING [1 2 3 4 5 6 7 + + + + + +]. SHOULD BE CORRECT....");
        @(posedge clock);
        // checking 1 2 3 4 5 6 7 +  = 28
        checkResult = 16'd28;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 1 2 3 4 5
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h6; // stack 1 2 3 4 5 6
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7; // stack 1 2 3 4 5 7
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);

        $display("CHECKING [1 2 3 4 5 6 7 8 9 +] STACK OVERFLOW SHOULD OCCUR...");
        @(posedge clock);
        // checking 1 2 3 4 5 6 7 8 +  = 10
        checkResult = 16'd15;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 1 2 3 4 5
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h6; // stack 1 2 3 4 5 6
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7; // stack 1 2 3 4 5 7
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h8; // stack 1 2 3 4 5 7 8
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h9; // stack 1 2 3 4 5 7 8 9
        @(posedge clock);
        assert(stackOverflow) $info("stackOverflow occured!");
          else $error("STACK OVERFLOW SHOULD HAVE OCCURED!");
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes = 2;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display({"INSERTING START BEFORE DONE W/0 CORRECT...",
              "PROTOCOLERROR SHOULD OCCUR..."});
        @(posedge clock);
        // checking 1 2 3 4 5 6 7 8 +  = 10
        correctRes = 3;
        checkResult = 16'd4;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= START;/// error but if faulty it will restart
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add == 4
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        assert(protocolError);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [1 2 3 + + 6 -]. SHOULD BE CORRECT......");
        checkResult = 16'd0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h6; // stack 6 6
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [1 2 3 + + 5 -] AND SWAPPING BEFORE. CORRECT...");
        checkResult = -(16'd1);
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 6 5
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap //stack 5 6
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);

        $display("CHECKING [1 2 3 + + 6 -] AND SWAPPING. SHOULD GIVE PROTOCOLERROR");
        checkResult = 16'd0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h6; // stack 6 6
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 2;
        @(posedge clock);
        assert(protocolError);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [2 1 3 - + = 0]. SHOULD BE CORRECT...");
        checkResult = 16'd2;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap stack 2 1 3
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes = 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("checking [1 1 &], SHOULD BE CORRECT......");
        checkResult = 16'd1;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack 1 1
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4;
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);

        $display("CHECKING [1 1 0 & &] SHOULD BE CORRECT...");
        checkResult = 16'd0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack 1 1
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h0; // stack 1 1 0
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4; //AND
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4; //AND
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [0 NEG 1 1 & &] SHOULD BE CORRECT......");
        checkResult = 16'd0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0;
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h10; //negte // stack 1
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack 1 1
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack 1 1 1
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4;
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4;
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 1;
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [START 0 DONE] SHOULD NOT GIVE AN ERROR......");
        checkResult = 16'd0;
        correctRes = 3;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0;
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHECKING [START 0 2 DONE] ERROR SHOULD OCCUR......");
        checkResult = 16'd1;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack 1
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 2;
        @(posedge clock);
        assert(unexpectedDone);
        correctRes = 0;
        @(posedge clock);

        $display("CHEKING [START 0 + 1 1 + DONE] SHOULD GIVE AN ERROR......");
        checkResult = 16'd0;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h0;
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack + 1
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h1; // stack + 1 1
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add + 1 1 +
        @(posedge clock);
        data.op <= DONE;
        data.payload <= 16'h1; //done
        correctRes <= 2;
        @(posedge clock);
        assert(protocolError);
        correctRes = 0;
        @(posedge clock);



        $display({"CHEKING [1 2 3 4 5 6 7 + - swap negate  and + - pop]",
          "SHOULD BE CORRECT..."});
        @(posedge clock);
        // checking 1 2 3 4 5 6 7 +  = 28
        checkResult = 16'd1;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h5; // stack 1 2 3 4 5
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h6; // stack 1 2 3 4 5 6
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7; // stack 1 2 3 4 5 7
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h10; //neg
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h4; //and
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);



        $display("CHECKING SOME INVALID COMMANDS. ERROR SHOULD OCCUR");
        @(posedge clock);
        checkResult = 16'd1;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h1;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h2; // stack 1 2
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h3; // stack 1 2 3
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h4; // stack 1 2 3 4
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h20; //pop
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h10; //neg
        @(posedge clock);
        correctRes = 2;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        assert(protocolError);
        correctRes = 0;
        @(posedge clock);


        $display("CHEKING [8000 7fff SWAP SWAP ADD] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = 16'hFFFF;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h8000;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHEKING [8000 7fff SWAP ADD] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = 16'hFFFF;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h8000;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);

        $display("CHEKING [8000 7fff ADD] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = 16'hFFFF;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h8000;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h1; //add
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHEKING [800 7fff SUB] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = 16'h8801;
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h800;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHEKING [7fff 7fff SWAP SUB] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = (16'd0000);
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h7fff;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);


        $display("CHEKING [7fff 7fff SWAP SWAP SUB] SHOULD BE CORRECT......");
        @(posedge clock);
        checkResult = (16'hd001);
        @(posedge clock);
        data.op <= START;
        data.payload <= 16'h5000;
        @(posedge clock);
        data.op <= ENTER;
        data.payload <= 16'h7FFF; // stack 8000 7FFFF
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h8; //swap
        @(posedge clock);
        data.op <= ARITH_OP;
        data.payload <= 16'h2; //sub
        @(posedge clock);
        correctRes = 1;
        data.op <= DONE;
        data.payload <= 16'h1; //done
        @(posedge clock);
        correctRes = 0;
        @(posedge clock);
      end
    endtask


    logic errorOccured;
    assign errorOccured = (stackOverflow | unexpectedDone | dataOverflow | protocolError);

    function logic checkVals(int num);
      int count;
      for (int i = 0; i < 8; i = i + 1) begin
        if(stackOut[i] != 'bx) begin
          count++;
        end
      end
      return(1'b1);
    endfunction

    property CheckStart;
      @(posedge clock) (data.op == START && correctRes != 3) |=> (stackOut[0] == $past(data.payload,1)) ;
    endproperty

    emptyStack: assert property (CheckStart) else $error("%m, STACK[0] SHOULD HAVE APPEARED!");


    // property CheckEnter;
    //   @(posedge clock) (data.op == ENTER) |=>  (stackOut[0] == $past(data.payload,1)) ;
    // endproperty
    //
    // ValtoStk: assert property (CheckEnter) else $error("%m, ENTER DIDNT APPEAR ON TIME");


    // property checkAdd;
    //   @(posedge clock) (data.op == ARITH_OP && data.payload == 16'h1) |=> (stackOut[0] == (($past(stackOut[0]) + $past(stackOut[1])) && 16'hffff));
    // endproperty
    //
    // property checkSub;
    //   @(posedge clock) (data.op == ARITH_OP && data.payload == 16'h2) |=> (stackOut[0] == (($past(stackOut[0]) - $past(stackOut[1])) && 16'hffff));
    // endproperty


    // addCheck: assert property (checkAdd) else $error("%m, Inccorrect result of ADD");
    //Check start for protocolError
    property CheckStartMiddle;
      @(posedge clock) (data.op == START && correctRes != 3) |-> $past(data.op, 1) == DONE ; //(data.op == DONE && !data.op == START) ##[1:$] data.op == START;
    endproperty

    middleStart: assert property (CheckStartMiddle) else $error("%m, SHOULD NOT BE A START HERE!");

    //Distance between start and done should be more than >= 1
    property distStartDone;
     @(posedge clock) (data.op == START && correctRes != 3) |=> (!(data.op == DONE));
    endproperty

    distStrDn: assert property (distStartDone) else $error("%m, SHOULD BE MORE THAN ONE ELEMENTS BETWEEN START AND DONE!");


    //stackOverflow check
    property doneAsserted;
     @(posedge clock) (data.op == START) |-> ##[1:$] (data.op == DONE) ##0 finished;
    endproperty

    DoneNotAsserted: assert property (doneAsserted) else $error("%m, DONE SHOULD HAVE BEEN ASSERTED!");

    property stackOverflowProp;
     @(posedge clock) (data.op == START) |-> ##[1:$] (!stackOverflow);
    endproperty

    Overflow: assert property (stackOverflowProp) else $error("%m, STACK OVERFLOW OCCURED!");


    // Done only asserted when one value is left on stack
    // property UnexpectedDone;
    //  @(posedge clock) (data.op == DONE) |-> (finished);
    // endproperty
    //
    // countWHenDone: assert property (UnexpectedDone) else $error("%m, more than one val on stack when DONE! Finished is %b", finished);

    //Check the correctness of result
    property resultCheck;
     @(posedge clock) ((data.op == DONE) && (correctRes == 1)) |-> result == checkResult and correct and result == stackOut[0];
    endproperty

    resultCorrectness: assert property (resultCheck) $info("CORRECT!");
     else $error("%m, RESULT SHOULD BE %h, BUT THE OUTPUT FROM CALCULATOR IS %h", checkResult, result);

    //Check the incorectness of the result
    property ErrorCheck;
     @(posedge clock) (data.op == DONE) && (correctRes == 2) |-> ((!correct) and finished and errorOccured);
    endproperty

    chkForError: assert property (ErrorCheck) $info("ERROR OCCURED AS EXPECTED");
      else $error("%m, AN ERROR SHOULD HAVE OCCURED");

    property ErrorCheck2;
    @(posedge clock) (errorOccured) |-> ##[1:$] ((data.op == DONE) and (!correct) and finished and (correctRes == 2));
    endproperty

    errorchk2: assert property (ErrorCheck2) else $error("UNEXPECTED ERROR OCUURED!");

    property UnexpectedFinish;
     @(posedge clock) finished |-> (data.op == DONE) ;
    endproperty

    whyfinish: assert property (UnexpectedFinish) else $error({"%m, ",
    "shouldnt finish yet! stack is %h %h %h %h %h %h %h %h"},  stackOut[0],
     stackOut[1], stackOut[2], stackOut[3], stackOut[4], stackOut[5],
     stackOut[6], stackOut[7]);

    property UnexpectedCorrect;
     @(posedge clock) correct |-> (data.op == DONE);
    endproperty

    whycorrect: assert property (UnexpectedCorrect) else $error({"%m, odly ",
    "timed correct! stack is %h %h %h %h %h %h %h %h"},  stackOut[0],
    stackOut[1], stackOut[2], stackOut[3], stackOut[4], stackOut[5],
    stackOut[6], stackOut[7]);



endmodule: top
