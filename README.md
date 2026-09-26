RK3506 裸机开发示例与教程配套代码。

本仓库记录在 RK3506 上从零开始写裸机程序的过程：交叉编译环境搭建、Thumb 汇编点灯、编译链接、U-Boot mw 下载、go 执行、反汇编验证，以及串口调试中踩过的坑。

所有代码均在 Ubuntu 22.04 + RK3506 开发板 上实测通过。

已实现内容
☑ Ubuntu 22.04 交叉编译工具链安装与验证
☑ 手写 Thumb 汇编 led_thumb.s，控制 GPIO0_D0 闪烁
☑ 编译、链接、抽取 .bin
☑ 生成 U-Boot mw 命令（小端、32 位字）
☑ 分批 + md 回读，避免串口丢字符
☑ 反汇编验货：确认 Thumb-2、入口地址、段大小
☑ U-Boot 下 go 0x01000000 运行
☑ 双终端工作流：终端 A 编译，终端 B 串口操作
后续计划：

□ UART 裸机输出
□ 定时器 / 中断
□ 修改 bootdelay，更方便进 U-Boot
□ 更稳的下载方式（loady / tftpboot）
硬件与软件环境
项目	配置
开发板	RK3506（ATK-DLRK3506）
系统	Ubuntu 22.04.5 LTS
CPU	i7-13700H
内存	15 GiB（可用约 7.4 GiB）
显卡	RTX 4050 Laptop，6 GB
串口	CH343，/dev/ttyACM0，波特率 1500000
交叉编译工具链
bash
sudo apt update
sudo apt install -y gcc-arm-none-eabi binutils-arm-none-eabi picocom python3
验证：

bash
arm-none-eabi-gcc --version | head -1
picocom --version | head -1
python3 --version
目录结构
text
rk3506-baremetal/
├── README.md
├── LICENSE
├── 01-led-thumb/
│   ├── led_thumb.s          # Thumb 汇编源码
│   ├── led.lds              # 可选链接脚本
│   ├── Makefile             # 一键编译
│   ├── tools/
│   │   ├── bin2mw.py        # .bin → mw.txt
│   │   └── bin2batches.py   # mw.txt → batches.txt（分批 + 回读）
│   └── README.md            # 本节详细说明
└── ...

系列文章
本仓库配套 CSDN 系列：

https://blog.csdn.net/2301_79071254/category_13213840.html

RK3506 裸机开发(一)：Ubuntu 22.04 交叉编译与串口环境搭建

RK3506 裸机开发(二)：手写 Thumb 汇编实现 LED 闪烁

RK3506 裸机开发(三)：编译、下载、反汇编验证与 U-Boot 命令行实战

文章链接后续补充。

许可证
MIT License，详见 LICENSE。

参考
RK3506 TRM

U-Boot docs/reference/u-boot_next-dev_rk3506_common.h

U-Boot docs/reference/u-boot_next-dev_rk3506_defconfig

如果这个仓库对你有帮助，欢迎 Star。有问题可以在 Issues 里交流。
