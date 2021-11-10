

#include "edio.h"

void spiInit() {

    u8 tmp = 0;

    SPI1->CR1 |= SPI_CR1_SPE;
    SPI2->CR1 |= SPI_CR1_SPE;

    spiSS(SPI_SS_FLA, 1);
    spiSS(SPI_SS_MEM, 1);

    spiTX(SPI1, &tmp, 1);
    spiTX(SPI1, &tmp, 1);
}

void spiRX(SPI_TypeDef *spi, u8 *dst, u32 len) {


    while (len--) {
        while (!(spi->SR & SPI_SR_TXE));
        *((volatile u8 *)&(spi->DR)) = 0xff;
        while (!(spi->SR & SPI_SR_RXNE));
        *dst++ = *((volatile u8 *)&(spi->DR));
    }

}

void spiTX(SPI_TypeDef *spi, u8 *src, u32 len) {

    volatile u32 tmp;

    while (len--) {

        while (!(spi->SR & SPI_SR_TXE));
        *((volatile u8 *)&(spi->DR)) = *src++;
    }

    while (!(spi->SR & SPI_SR_TXE));
    while ((spi->SR & SPI_SR_BSY));


    tmp = spi->DR;
    tmp = spi->SR;
    UNUSED(tmp);
}

void spiTX_DMA(SPI_TypeDef *spi, u8 *src, u32 len) {

    //spiWR(spi, src, len);
    //spi1. TX: dma2, stream 3/5, chann3. RX: dma2, stream 0/2, chann3.
    //spi2. TX: dma1, stream 4,   chann0. RX: dma1, stream 3,   chann0.

    if (spi == SPI2) {
        spiTX(spi, src, len);
    }

    spi->CR2 |= SPI_CR2_TXDMAEN;
    DMA2_Stream5->CR &= ~DMA_SxCR_EN;
    DMA2->HIFCR = DMA_HIFCR_CTCIF5 | DMA_HIFCR_CHTIF5 | DMA_HIFCR_CTEIF5;

    DMA2_Stream5->PAR = (u32) & spi->DR;
    DMA2_Stream5->M0AR = (u32) src;
    DMA2_Stream5->NDTR = len;
    //DMA2_Stream5->CR = DMA_SxCR_CHSEL_0 | DMA_SxCR_CHSEL_1 | DMA_SxCR_DIR_0 | DMA_SxCR_MINC | DMA_SxCR_EN;
    DMA2_Stream5->CR |= DMA_SxCR_EN; //rest of dma configured by CubeMX

}

void spiTXBusy(SPI_TypeDef *spi) {

    if (spi == SPI2)return;

    if (!(spi->CR2 & SPI_CR2_TXDMAEN))return;
    while ((DMA2->HISR & DMA_HISR_TCIF5) == 0);
    DMA2_Stream5->CR &= ~DMA_SxCR_EN;
    spi->CR2 &= ~SPI_CR2_TXDMAEN;
}

void spiTXRX(SPI_TypeDef *spi, u8 *src, u8 *dst, u32 len) {


    while (len--) {
        while (!(spi->SR & SPI_SR_TXE));
        *((volatile u8 *)&(spi->DR)) = *src++;
        while (!(spi->SR & SPI_SR_RXNE));
        *dst++ = *((volatile u8 *)&(spi->DR));
    }

}

void spiBitDir(SPI_TypeDef *spi, u32 dir) {

    if (dir == SPI_LSB) {
        spi->CR1 |= SPI_CR1_LSBFIRST;
    } else if (dir == SPI_MSB) {
        spi->CR1 &= ~SPI_CR1_LSBFIRST;
    }
}

void spiSS(u8 ss_line, u8 state) {

    switch (ss_line) {

        case SPI_SS_MEM:
            gpioWR_port(spi1_ssb_GPIO_Port, spi1_ssb_Pin, state);
            break;
        case SPI_SS_FLA:
            gpioWR_port(spi2_ss_GPIO_Port, spi2_ss_Pin, state);
            break;
    }
}


/* not working
void spiRX_DMA(SPI_TypeDef *spi, u8 *dst, u32 len) {

    if (spi == SPI2) {
        spiRX(spi, dst, len);
    }

    spi->CR2 |= SPI_CR2_RXDMAEN;
    DMA2_Stream0->CR &= ~DMA_SxCR_EN;
    DMA1->LIFCR = DMA_LIFCR_CTCIF0 | DMA_LIFCR_CHTIF0 | DMA_LIFCR_CTEIF0;

    DMA2_Stream0->PAR = (u32) & spi->DR;
    DMA2_Stream0->M0AR = (u32) dst;
    DMA2_Stream0->NDTR = len;
    DMA2_Stream0->CR |= DMA_SxCR_EN; //rest of dma configured by CubeMX

    while ((DMA2->LISR & DMA_LISR_TCIF0) == 0);
    DMA2_Stream0->CR &= ~DMA_SxCR_EN;
    spi->CR2 &= ~SPI_CR2_RXDMAEN;
}
*/