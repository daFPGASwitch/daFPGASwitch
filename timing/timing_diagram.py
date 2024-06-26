# Run on https://wavedrom.com/editor.html
import wavedrom
svg = wavedrom.render("""
{signal: [
  {name:'clk',         wave: 'P...............................|'}, 
  ['Ingress',
   ['input',
    {name: 'packet_in', wave: '999999998888888877777777777777770',   data: ''  }, // size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload
    {name: 'new_packet_en', wave: '10......10......10.................'},
    {name: 'write_en', wave: '1.......1.......1........1.........'},
    {name: 'sched_done', wave: '0.......10......10......10......10......10......10......10......10......'},
    {name: 'sched_sel', wave: '0.......3.......3.......3.......', data: '1000 0100 0010'}
    ],
    ['voq_registers', 
     {name: 'start_idx_0[9:0]', wave: '0.......7.......7.......7............', data: '1 2 3'},
     /*{name: 'start_idx_1[9:0]', wave: '000000000' , data: ''},
     {name: 'start_idx_2[9:0]', wave: '000000000' , data: ''},
     {name: 'start_idx_3[9:0]', wave: '000000000' , data: ''},*/
     {name: 'end_idx_0[9:0]', wave: '0..7.......7.......7............', data: '1 2 3'},
     /*{name: 'end_idx_1[9:0]', wave: '000000000' , data: ''},
     {name: 'end_idx_2[9:0]', wave: '000000000' , data: ''},
     {name: 'end_idx_3[9:0]', wave: '000000000' , data: ''},*/
    ],
    ['ctrl_registers', 
     {name: 'curr_write[9:0]', wave: '4.......4.......4.......4.......', data: '1 2 3 1'},
     {name: 'curr_read[9:0]', wave: '0.......4.......4...............', data: '1 2'},
     {name: 'next_write[9:0]', wave:'4.......4.......4...4...4.......', data: '2 3 4 1 3'},
     {name: 'next_read[9:0]', wave: '0.......0........4.......0......', data: '4'},
     {name: 'empty_block[9:0]', wave: '5.......5.......5.......5.......' , data: '1023 1022 1021 1020'},
     {name: 'offset[2:0]', wave: '33333333333333333333333333333333' , data: '0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7'},
     {name: 'length[5:0]', wave: '9.......8.......7.......7.......' , data: '1 1 2 1'},
     {name: 'ctrl_data[10:0]', wave: '0......6.0.....6.0.....6.0.....6', data:'0|0 0|0 0|0 0'}
    ],
    /* ['ouput',
    {name: 'packet_out', wave: '0.............999999990...............888888880888888880............',   data: ''}, // size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload
    {name: 'egress_en', wave: '0.............1.......0...............1.......01.......0.........'},
    {name: 'ingress_busy', wave: '0.....................................1.......0....................'}, // If this is the last segment of the packet, set it to be non busy
    {name: 'busy_voq_num[2:0]', wave: '0.....................................5.......0...........', data: '1'},
    {name: 'voq_empty[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
   
   ], */
   ['control_mem',
    {name: 'ctrl_wen_a', wave: '10......10......10......10......'},
    {name: 'ctrl_ren_a', wave: '0.....10......10......10.......'},
    {name: 'ctrl_addr_a', wave: '30....3030....3030....3030......', data: '1 2 2 3 3 4 4'},
    {name: 'crtl_in_a[31:0]', wave: '60......60......60......60......', data: '1|0 1|0 1|4 1|0'},
    {name: 'crtl_out_a[31:0]', wave: '0......60......60......60.......', data: '0|0 0|0 0|0'},
    {name: 'crtl_wen_b', wave: '0.................10......10.......'},
    {name: 'ctrl_ren_b', wave: '0........10......10......10.......'},
    {name: 'crtl_addr_b', wave: '0........30......330.....330.......', data: '1 2 1 3 2'},
    {name: 'crtl_in_b[31:0]', wave: '0.................60......60.......', data: '0|4 0|5 0|0'},
    {name: 'crtl_out_b[31:0]', wave: '0.........60.......60......60.......', data: '1|0 1|0 1|4'},
   ],
   
   ['data_mem',
    {name: 'data_wen_a', wave: '1.......1.......1.......1.......'},
    {name: 'data_ren_a'},
    {name: 'data_addr_a', wave: '33333333333333333333333333333333', data: '1+0 1+1 1+2 1+3 1+4 1+5 1+6 1+7 2+0 2+1 2+2 2+3 2+4 2+5 2+6 2+7 3+0 3+1 3+2 3+3 3+4 3+5 3+6 3+7 4+0 4+1 4+2 4+3 4+4 4+5 4+6 4+7' },
    {name: 'data_in_a[31:0]', wave: '99999999888888887777777777777777',   data: ''},
    {name: 'data_out_a[31:0]'},
    {name: 'data_wen_b'},
    {name: 'data_ren_b', wave:'0.........1.......1.......1.......'},
    {name: 'data_addr_b', wave: '0.........33333333333333333333333333333333', data: '1+0 1+1 1+2 1+3 1+4 1+5 1+6 1+7 2+0 2+1 2+2 2+3 2+4 2+5 2+6 2+7 3+0 3+1 3+2 3+3 3+4 3+5 3+6 3+7 4+0 4+1 4+2 4+3 4+4 4+5 4+6 4+7'},
    {name: 'data_in_b[31:0]'},
    {name: 'data_out_b[31:0]', wave:'0..........99999999888888887777777777777777',   data: ''},
   ],
   
   ['voq_mem',
    {name: 'voq_wen_a', wave: '0..10......10......10...........'},
    {name: 'voq_ren_a', },
    {name: 'voq_addr_a', wave: '0..30......30......30...........', data: '0 1 2'},
    {name: 'voq_in_a[31:0]', wave: '0..40......40......40...........', data: '1 2 3'},
    {name: 'voq_out_a[31:0]'},
    {name: 'voq_wen_b'},
    {name: 'voq_ren_b', wave: '0.......10......10......10...........'},
    {name: 'voq_addr_b', wave: '0.......30......30......30...........', data: '0 1 2'},
    {name: 'voq_in_b[31:0]'},
    {name: 'voq_out_b[31:0]', wave: '0........40......40......40...........', data: '1 2 3'},
   ], 
  ],
  
   ['scheduler',
    {name: 'sched_en', wave: '0...10......10......10......10..'},
    {name: 'ingress_rr[1:0]', wave: '0...3......4......5......6......', data: '0 1 2 3'}, // If this is the last segment of the packet, set it to be non busy
    {name: 'is_busy[3:0]', wave: '0...10......10......10......10..'},
   	{name:	'last_egress_0[1:0]]', wave: '0...10......10......10......10..'},
    {name: 'last_egress_1[1:0]', wave: '0...10......10......10......10..'},
    {name: 'last_egress_2[1:0]', wave: '0...10......10......10......10..'},
    {name: 'last_egress_3[1:0]', wave: '0...10......10......10......10..'},
    {name: 'busy_voq_num_0[1:0]', wave: '0...3......4......5......6......', data: '0 0 2 3'},
    {name: 'busy_voq_num_1[1:0]', wave: '0...3......4......5......6......', data: '0 0 0 0'},
    {name: 'busy_voq_num_2[1:0]', wave: '0...3......4......5......6......', data: '0 0 0 0'},
    {name: 'busy_voq_num_3[1:0]', wave: '0...3......4......5......6......', data: '0 0 0 0'},
    {name: 'voq_empty_0[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
    {name: 'voq_empty_1[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
    {name: 'voq_empty_2[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
    {name: 'voq_empty_3[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
   ],
   ['Crossbar',
    {name: 'data_1', wave: '0..........10......10......10......10..'},
    {name: 'data_2', wave: '0..........10......10......10......10..'},
    {name: 'data_3', wave: '0..........10......10......10......10..'},
    {name: 'data_4', wave: '0..........10......10......10......10..'},
    {name: 'sched_dec_1[1:0]', wave: '0.......3.......4.0.....5.0.....6.0.....', data: '0 1 2 3'}, // If this is the last segment of the packet, set it to be non busy
    {name: 'sched_dec_2[1:0]', wave: '0.......3.......4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    {name: 'sched_dec_3[1:0]', wave: '0.......3.......4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    {name: 'sched_dec_4[1:0]', wave: '0.......3.......4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    {name: 'data_out_1', wave: '0...........10......10......10......10..'},
    {name: 'data_out_2', wave: '0...........10......10......10......10..'},
    {name: 'data_out_3', wave: '0...........10......10......10......10..'},
    {name: 'data_out_4', wave: '0...........10......10......10......10..'},
   /* ['Crossbar Registers',
    {name: 'sched_dec_1[1:0]', wave: '0........30.....4.0.....5.0.....6.0.....', data: '0 1 2 3'}, // If this is the last segment of the packet, set it to be non busy
    {name: 'sched_dec_2[1:0]', wave: '0........30.....4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    {name: 'sched_dec_3[1:0]', wave: '0........30.....4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    {name: 'sched_dec_4[1:0]', wave: '0........30.....4.0.....5.0.....6.0.....', data: '0 1 2 3'},
    
    ]*/
   
  ], 
   ['ouput',
    {name: 'packet_out', wave: '0...........999999990...............888888880888888880............',   data: ''}, // size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload size dest src t_ingress t_egress payload
    {name: 'egress_en', wave: '0...........1.......0...............1.......01.......0.........'},
    //{name: 'ingress_busy', wave: '0.....................................1.......0....................'}, // If this is the last segment of the packet, set it to be non busy
    //{name: 'busy_voq_num[2:0]', wave: '0.....................................5.......0...........', data: '1'},
    //{name: 'voq_empty[3:0]', wave: '5.........3...5..................4....0.........................', data: '1111 1011 1111 1101'}, // voq_empty start to become non-empty after some cycles 
   ],
   
  /*{name: 'dat', wave: 'x.345x|=.x', data: ['head', 'body', 'tail', 'data']},
  {name: 'req', wave: '0.1..0|1.0'},
  {},
  {name: 'ack', wave: '1.....|01.'} */
]}
""")
svg.saveas("timing.svg")
