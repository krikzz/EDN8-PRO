/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  ** This notice applies to any and all portions of this file
  * that are not between comment pairs USER CODE BEGIN and
  * USER CODE END. Other portions of this file, whether 
  * inserted by the user or by software development tools
  * are owned by their respective copyright owners.
  *
  * COPYRIGHT(c) 2019 STMicroelectronics
  *
  * Redistribution and use in source and binary forms, with or without modification,
  * are permitted provided that the following conditions are met:
  *   1. Redistributions of source code must retain the above copyright notice,
  *      this list of conditions and the following disclaimer.
  *   2. Redistributions in binary form must reproduce the above copyright notice,
  *      this list of conditions and the following disclaimer in the documentation
  *      and/or other materials provided with the distribution.
  *   3. Neither the name of STMicroelectronics nor the names of its contributors
  *      may be used to endorse or promote products derived from this software
  *      without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"
#include "stm32f4xx_ll_adc.h"
#include "stm32f4xx_ll_crc.h"
#include "stm32f4xx_ll_dma.h"
#include "stm32f4xx_ll_iwdg.h"
#include "stm32f4xx_ll_rtc.h"
#include "stm32f4xx_ll_spi.h"
#include "stm32f4xx_ll_tim.h"
#include "stm32f4xx_ll_usart.h"
#include "stm32f4xx_ll_rcc.h"
#include "stm32f4xx.h"
#include "stm32f4xx_ll_system.h"
#include "stm32f4xx_ll_gpio.h"
#include "stm32f4xx_ll_exti.h"
#include "stm32f4xx_ll_bus.h"
#include "stm32f4xx_ll_cortex.h"
#include "stm32f4xx_ll_utils.h"
#include "stm32f4xx_ll_pwr.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define cart_ff_Pin LL_GPIO_PIN_1
#define cart_ff_GPIO_Port GPIOA
#define flash_wp_Pin LL_GPIO_PIN_2
#define flash_wp_GPIO_Port GPIOA
#define spi1_ssb_Pin LL_GPIO_PIN_4
#define spi1_ssb_GPIO_Port GPIOA
#define cfg_don_Pin LL_GPIO_PIN_4
#define cfg_don_GPIO_Port GPIOC
#define mcu_busy_Pin LL_GPIO_PIN_5
#define mcu_busy_GPIO_Port GPIOC
#define fifo_rxf_Pin LL_GPIO_PIN_0
#define fifo_rxf_GPIO_Port GPIOB
#define nstat_Pin LL_GPIO_PIN_1
#define nstat_GPIO_Port GPIOB
#define ncfg_Pin LL_GPIO_PIN_2
#define ncfg_GPIO_Port GPIOB
#define spi2_ss_Pin LL_GPIO_PIN_12
#define spi2_ss_GPIO_Port GPIOB
#define xio0_Pin LL_GPIO_PIN_13
#define xio0_GPIO_Port GPIOB
#define xio1_Pin LL_GPIO_PIN_14
#define xio1_GPIO_Port GPIOB
#define xio2_Pin LL_GPIO_PIN_15
#define xio2_GPIO_Port GPIOB
#define pwr_sys_Pin LL_GPIO_PIN_6
#define pwr_sys_GPIO_Port GPIOC
#define pwr_usb_Pin LL_GPIO_PIN_7
#define pwr_usb_GPIO_Port GPIOC
#define SDIO_D0_Pin LL_GPIO_PIN_8
#define SDIO_D0_GPIO_Port GPIOC
#define SDIO_D1_Pin LL_GPIO_PIN_9
#define SDIO_D1_GPIO_Port GPIOC
#define mcu0_Pin LL_GPIO_PIN_8
#define mcu0_GPIO_Port GPIOA
#define mcu1_Pin LL_GPIO_PIN_9
#define mcu1_GPIO_Port GPIOA
#define mcu2_Pin LL_GPIO_PIN_10
#define mcu2_GPIO_Port GPIOA
#define SDIO_D2_Pin LL_GPIO_PIN_10
#define SDIO_D2_GPIO_Port GPIOC
#define SDIO_D3_Pin LL_GPIO_PIN_11
#define SDIO_D3_GPIO_Port GPIOC
#define SDIO_CK_Pin LL_GPIO_PIN_12
#define SDIO_CK_GPIO_Port GPIOC
#define SDIO_CMD_Pin LL_GPIO_PIN_2
#define SDIO_CMD_GPIO_Port GPIOD
#define led_Pin LL_GPIO_PIN_5
#define led_GPIO_Port GPIOB
#define fds_sw_Pin LL_GPIO_PIN_9
#define fds_sw_GPIO_Port GPIOB
/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
