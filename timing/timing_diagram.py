# Run on https://wavedrom.com/editor.html
import wavedrom
svg = wavedrom.render("""
{signal: [
  {name:'clk',         wave: 'P.......................'},
  {name:'packets_in_mmu',        wave: '9.......9.......7......', data: 'packet[0].header packet[0].data packet[1]' },
  ['Scheduler',
  {name:'out.sched_decision',     wave: 'Hl......Hl......Hl.....' },
  ],
  {name:'ingress_1',     wave: '0.......................' },
  {name:'ingress_2',     wave: '0.......................' },
  {name:'ingress_3',     wave: '0.......................' },
  {name:'ingress_4',     wave: '0.......................' },
   {name:'packet_data',        wave: 'xxxx99999999.......77777777', data: 'size dest src t_ingress t_egress payload payload packet.data[32:63] size dest src t_ingress t_egress payload payload data[1] data[2] data[3] data[4] data[5] data[6] data[7] dest src payload payload ' },
  ['Crossbar',
  ['crossbar_ctrl',
  {name:'busy',     wave: '0...Pl...................' },
  {name:'empty',     wave: '0..................Pl......' },
  ]],
  ['Ingress',

  {name:'dmem.RD_EN', wave: '0..Hl..................'},
  {name:'dmem.RD_ADDR', wave: '0..Hl..................'},
  {name:'dmem.DATA_OUT', wave: '0...Hl.................'},
  {name:'dmme.WR_EN', wave: '0...Hl.................'},
   ['ingress_1',
  {name:'voq_1',     wave: '0.......................' },
  {name:'voq_2',     wave: '0Hl....................' },
  {name: 'voq_2.RD_EN', wave: '0.Hl...................'},
  {name: 'voq_2.RD_ADDR', wave: '0.Hl...................'},
  {name:'voq_3',     wave: '0.......................' },
  {name:'voq_4',     wave: '0.......................' },
  ]],
  {name:'packet_data (crossbar)',        wave: 'xxxxx99999999.......77777777', data: 'size dest src t_ingress t_egress payload payload packet.data[32:63] data[1] data[2] data[3] data[4] data[5] data[6] data[7] dest src payload payload ' },
  {name:'crossbar',        wave: 'xxxxx99999999.......77777777', data: 'size dest src t_ingress t_egress payload payload packet.data[32:63] data[1] data[2] data[3] data[4] data[5] data[6] data[7] dest src payload payload ' },
  ['Egress',
  {name:'egress_1',     wave: '0.......................' },
  {name:'egress_2',     wave: '0.......................' },
  {name:'egress_2.buffer',        wave: 'xxxxxx99999999.......77777777', data: 'size dest src t_ingress t_egress payload payload packet.data[32:63] data[1] data[2] data[3] data[4] data[5] data[6] data[7] dest src payload payload ' },
  {name:'egress_2.RD_EN',     wave: '0.....H..............l.................' },
  {name:'egress_2.RD_DATA',     wave: '0.....H..............l...............' },   
  {name:'egress_3',     wave: '0.......................' },
  {name:'egress_4',     wave: '0.......................' },
  ],
],
 head:{
   text:'DaFPGASwitch',
   tick:0,
   every:1
 },
 foot:{
   text:'Figure 100',
   tock:0
 },
  config: { hscale: 1.5 }
}
""")
svg.saveas("timing.svg")
