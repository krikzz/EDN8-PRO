/* 
 * File:   spi.h
 * Author: igor
 *
 * Created on May 17, 2019, 8:54 PM
 */

#ifndef SPI_H
#define	SPI_H

#define SPI_MSB 0
#define SPI_LSB 1

void spiInit();
void spiRX(SPI_TypeDef *spi, u8 *dst, u32 len);
void spiTX(SPI_TypeDef *spi, u8 *src, u32 len);
void spiTX_DMA(SPI_TypeDef *spi, u8 *src, u32 len);
void spiTXRX(SPI_TypeDef *spi, u8 *src, u8 *dst, u32 len);
void spiBitDir(SPI_TypeDef *spi, u32 dir);
void spiSS(u8 ss_line, u8 state);
void spiTXBusy(SPI_TypeDef *spi);

#endif	/* SPI_H */

