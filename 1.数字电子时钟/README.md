# 数字电子时钟

本项目实现一个基于 100 MHz 输入时钟的六位数字电子时钟，并提供完整自检测试与分场景验收演示。当前已完成 Questa 功能仿真验收和 Vivado 初步综合，尚未完成 FPGA 板级验证。

## 功能与实现

- 采用 24 小时制显示时、分、秒，支持秒、分、时的自然进位及跨日回绕。
- 通过三个按键分别调整时、分、秒；按键信号经过同步、消抖，并转换为单周期按下事件。
- 驱动六位共阳极数码管，段选 `seg` 和位选 `an` 均为低有效，段位顺序为 `{g,f,e,d,c,b,a}`。
- 可通过按键设置闹钟小时和分钟，并切换闹钟使能状态。
- 闹钟启用后，在当前小时、分钟均与设定值匹配的整个期间持续输出报警；离开匹配分钟或取消使能后停止。
- `clock_divider` 产生的是每秒出现一次、宽度为一个输入时钟周期的 `tick_1hz` 脉冲，不是占空比 50% 的 1 Hz 方波。

## RTL 模块

| 模块 | 文件 | 职责 |
| --- | --- | --- |
| `clock_top` | `rtl/clock_top.v` | 顶层模块，连接分频、计时、按键、显示和闹钟模块 |
| `clock_divider` | `rtl/clock_divider.v` | 将输入时钟转换为每秒一次的单周期计时使能脉冲 |
| `time_counter` | `rtl/time_counter.v` | 保存 24 小时时间，处理计时进位和三个时间调整事件 |
| `key` | `rtl/key_debounce.v` | 对异步按键进行两级同步与消抖，按下时输出单周期脉冲 |
| `seg_decoder` | `rtl/seg_decoder.v` | 将时、分、秒转换为六位共阳极数码管的动态扫描信号 |
| `alarm_controller` | `rtl/alarm_controller.v` | 保存闹钟时分与使能状态，并根据当前时分产生持续报警信号 |

连接关系如下：`clock_divider` 为 `time_counter` 提供计时脉冲；三个 `key` 实例向 `time_counter` 提供时间调整事件；`time_counter` 的时间输出同时送入 `seg_decoder` 和 `alarm_controller`；`alarm_controller` 内部另有三个 `key` 实例处理闹钟设置与使能按键。所有模块由 `clock_top` 统一例化和连接。

## 目录结构

```text
1.数字电子时钟/
├── rtl/    # Verilog 设计代码
├── tb/     # SystemVerilog 自检与演示测试代码
└── sim/    # Questa 启动脚本、波形配置和仿真结果目录
```

## 正式参数与仿真参数

顶层正式默认参数为 `CLK_HZ=100_000_000`、`DEBOUNCE_TIME=1000`、`SCAN_CYCLE=100_000`，对应当前 100 MHz 时钟设计。测试平台保持 10 ns 的输入时钟周期，但会缩小分频、消抖和扫描参数：完整自检使用 `SIM_CLK_HZ=10_000`、`SIM_DEBOUNCE=4`、`SIM_SCAN_CYCLE=3`，部分演示进一步将分频参数缩小到 `20`。

这些缩小参数只用于加速功能验证。此时 `tick_1hz` 仍保持“每 `CLK_HZ` 个输入周期产生一个单周期脉冲”的逻辑关系，但不代表物理时间上的 1 Hz 输出。

## Questa 完整自检

安装 Questa 并确保 `vlib`、`vlog`、`vsim` 可在命令行使用。从本目录执行：

```tcl
vlib work
vlog -sv rtl/clock_divider.v rtl/time_counter.v rtl/key_debounce.v rtl/seg_decoder.v rtl/alarm_controller.v rtl/clock_top.v tb/tb_clock_top.sv
vsim -c work.tb_clock_top -do "run -all; quit -f"
```

测试平台会自动检查复位、数码管扫描、按键消抖、单周期计时脉冲、时间进位、跨日回绕以及闹钟设置、匹配和取消；任一检查失败都会触发 `$fatal`。

部分 Windows 版 Questa 无法在含中文字符的工作路径中创建库数据库。若出现 `_lib.qdb` 或 `unable to open database file` 错误，可在本目录临时映射一个未占用的 ASCII 盘符后执行上述命令：

```powershell
subst O: "$PWD"
Set-Location O:\
# 完成仿真并离开 O: 后执行：subst O: /d
```

## 验收演示

从本目录启动 Questa。可在 Questa Transcript 中执行表内命令，也可用 `vsim -do sim/01_divider.do` 这类命令直接启动对应演示。

| 脚本 | 作用 | Transcript 运行命令 |
| --- | --- | --- |
| `sim/01_divider.do` | 展示单周期 `tick_1hz` 及计时器对脉冲的消费 | `do sim/01_divider.do` |
| `sim/02_count.do` | 展示 `12:59:58 → 12:59:59 → 13:00:00` | `do sim/02_count.do` |
| `sim/02_midnight.do` | 独立展示 `23:59:59 → 00:00:00` | `do sim/02_midnight.do` |
| `sim/03_keys.do` | 展示抖动拒绝、时分秒调整和长按不重复触发 | `do sim/03_keys.do` |
| `sim/04_display.do` | 展示 `12:34:56` 的六位低有效动态扫描 | `do sim/04_display.do` |
| `sim/05_alarm.do` | 展示闹钟设置、使能、持续报警和取消 | `do sim/05_alarm.do` |

计数、跨日、显示和闹钟演示会直接设置测试平台内部时间寄存器，以缩短波形；脚本输出会明确标记为 `TEST SETUP`，该初始化不是用户操作或自然计时过程。初始化完成后才检查由真实 `tick_1hz` 驱动的状态变化。所有演示均保留 `$fatal` 自动检查，波形保存到 `sim/results/`，该目录中的生成波形不纳入版本控制。

## 验证状态

- Questa：完整顶层自检和各验收演示用于功能验证。
- Vivado：已完成初步综合。
- FPGA：尚未完成开发板下载、引脚与时序条件下的板级运行验证。
