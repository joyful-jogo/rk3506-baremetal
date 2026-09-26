/**************************************************************
 * 文件名: led.s
 * 描述: RK3506 裸机实验 - 点亮 ATK-DLRK3506B 板载 LED（心跳灯）
 *
 * 硬件事实（正点原子《ATK-DLRK3506 嵌入式Linux驱动开发指南V1.2》§7.3 · PDF p62）:
 *   板载 LED0 = GPIO0_D0，经三极管驱动，GPIO 输出高电平点亮。
 *   设备树: gpios = <&gpio0 RK_PD0 GPIO_ACTIVE_HIGH>;
 *   手册路径: ~/rk3506/【正点原子】RK3506B开发板/开发板网盘A盘-基础资料/10、用户手册/01、开发文档/03【正点原子】ATK-DLRK3506嵌入式Linux驱动开发指南V1.2.pdf
 *
 * 依据: 手册完整路径
 *   ~/rk3506/【正点原子】RK3506B开发板/开发板网盘A盘-基础资料/08、RK官方文档/doc/cn/Socs/Datasheet/Rockchip_RK3506_TRM_Part_1_V1.2-20250811.pdf
 *   （印刷页码 = PDF 页码，可直接跳转；路径/页码总表见 ../docs/00_sources.md）
 *   - §1.1   Address Mapping        PDF p18     : GPIO0 base = 0xFF940000
 *   - §17.4.2 Registers Summary     PDF p408    : DR_H=0x04, DDR_H=0x0C
 *   - §17.4.3 Detail Registers      PDF p409-410: bit31:16 = write_mask
 *   - §17.5  Interface Description  PDF p421    : gpio0_port[24] = GPIO0_D0
 *   - §18.3  GPIO0_IOC              PDF p453-454: GPIO0_IOC_GPIO0D_CON=0x0830, reset 已选GPIO0_D0
 *   - §2.6   CRU_PMU_GATE_CON00     PDF p123    : bit8 pclk_gpio0_en, reset=0 已开
 *
 * 关键: 引脚在控制器内的编号 = 端口序号*8 + 引脚序号
 *        GPIO0_D0 = 3*8 + 0 = 24
 *        pin 0~15  -> _L 寄存器, 位号 = pin
 *        pin 16~31 -> _H 寄存器, 位号 = pin - 16
 *
 *   所以 GPIO0_D0 用 _H 寄存器, 位号是 8（不是 0!）:
 *   _H 的 bit0~7 对应 C 组 (C0~C7)，bit8~15 才是 D 组 (D0~D7)。
 *
 * 因此本文件中:
 *   写允许位 = bit(16+8) = bit24 -> 0x01000000
 *   输出     = 0x01000000 | 0x00000100 = 0x01000100
 *   输出高   = 0x01000100  (点亮)
 *   输出低   = 0x01000000  (熄灭)
 **************************************************************/
 
.syntax unified
.arch armv7-a
.cpu cortex-a7
.thumb

.global _start
.text

.thumb_func
_start:
push {r4, r5, r6, r7, lr}

    /* ------------------------------------------------------------
     * 1. 引脚复用：GPIO0_D0 选为 GPIO（复位默认即如此）
     *    Reg : GPIO0_IOC_GPIO0D_CON
     *    Addr: GPIO0_IOC base(0xFF950000) + 0x0830 = 0xFF950830
     *    Bit : [1:0] = gpio0d0_sel = 2'b00 (GPIO0D0)
     *          写允许 = [17:16]
     *          复位值 0x0000072C -> [1:0]=00, 已是 GPIO，此段可删
     * ------------------------------------------------------------ */
    ldr r0, =0xFF950830          /* GPIO0_IOC_GPIO0D_CON */
    ldr r1, =0x00030000          /* [17:16]=1 允许写 [1:0]; [1:0]=0 选 GPIO0D0 */
    str r1, [r0]

    /* ------------------------------------------------------------
     * 2. 时钟：确保 pclk_gpio0 开启
     *    Reg : CRU_PMU_GATE_CON00   (注意在 CRU_PMU，不是主 CRU!)
     *    Addr: CRU_PMU base(0xFF9B0000) + 0x0800 = 0xFF9B0800
     *    Bit : bit8 = pclk_gpio0_en, 1=关时钟, 复位0=已开
     * ------------------------------------------------------------ */
    ldr r0, =0xFF9B0800          /* CRU_PMU_GATE_CON00 */
    ldr r1, =0x01000000          /* bit24=写允许, bit8=0 -> 时钟保持开启 */
    str r1, [r0]

    /* ------------------------------------------------------------
     * 3. 方向：GPIO0_D0 设为输出
     *    Reg : GPIO_SWPORT_DDR_H   (D 组用 _H)
     *    Addr: GPIO0 base(0xFF940000) + 0x000C = 0xFF94000C
     *    Bit : bit8 = 1 -> Output ; 写允许 = bit24
     * ------------------------------------------------------------ */
    ldr r0, =0xFF940000          /* GPIO0 base */
    ldr r1, =0x01000100          /* bit24=写允许, bit8=1 -> 输出 */
    str r1, [r0, #0x0C]          /* GPIO_SWPORT_DDR_H */

    /* ------------------------------------------------------------
     * 4. 数据：输出高电平 -> 点亮
     *    Reg : GPIO_SWPORT_DR_H
     *    Addr: GPIO0 base(0xFF940000) + 0x0004 = 0xFF940004
     * ------------------------------------------------------------ */
    ldr r1, =0x01000100          /* bit24=写允许, bit8=1 -> 高电平点亮 */
    str r1, [r0, #0x04]          /* GPIO_SWPORT_DR_H */

    /* ------------------------------------------------------------
     * 5. 闪烁（粗延时，实际项目请用 TIMER）
     * ------------------------------------------------------------ */
blink:
    ldr r1, =0x01000100            /* 亮：bit24 写允许，bit8 输出高 */
    str r1, [r0, #0x04]   	  /* GPIO_SWPORT_DR_H */
    ldr r2, =0x20000000		
delay_on:
    subs r2, r2, #1 		/* 计数减 1 */
    bne delay_on		 /* 不为 0 则继续延时 */

    ldr r1, =0x01000000          /* 灭 */
    str r1, [r0, #0x04]
    ldr r2, =0x10000000  	
delay_off:
    subs r2, r2, #1
    bne delay_off

    b blink
    
