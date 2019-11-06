@echo off
REM Script to automatically select upload method for stm32-based multi-protocol module.

set driverLetter=%~dp0
set driverLetter=%driverLetter:~0,2%
%driverLetter%
cd %~dp0

set comport=%1

set fwpath=%2
set fwpath=%fwpath:/=\%

set blpath=%3
set blpath=%blpath:/=\%

REM Probe for a DFU device
ECHO Probing for an STM32F303 DFU device ...
".\dfu-util-0.9-win64\dfu-util.exe" -d 0483:df11 -a 0 -l | FIND /I "Found DFU"

if %errorlevel% equ 0 (
	ECHO Found DFU device
	GOTO DFU_FLASH
) ELSE (
  GOTO FTDI_CHECK
)

:DFU_FLASH
ECHO.
ECHO Flashing module via DFU
ECHO.
ECHO Writing bootloader ...
ECHO ".\dfu-util-0.9-win64\dfu-util.exe" -d 0483:df11 -a 0 -s 0x08000000 -D "%blpath%"
".\dfu-util-0.9-win64\dfu-util.exe" -d 0483:df11 -a 0 -s 0x08000000 -D "%blpath%"
ECHO.
ECHO Writing Multi firmware ...
ECHO ".\dfu-util-0.9-win64\dfu-util.exe" -d 0483:df11 -a 0 -s 0x08002000 -R -D "%fwpath%"
".\dfu-util-0.9-win64\dfu-util.exe" -d 0483:df11 -a 0 -s 0x08002000 -D "%fwpath%"
ECHO.
ECHO Done.
GOTO :EOF

:FTDI_CHECK
REM Attempt to read from the STM module via the specified serial port
ECHO Probing serial port %comport% for STM32 in BOOT0 mode ...
stm32flash.exe -b 115200 %comport%

if %errorlevel% equ 0 (
	ECHO Found module on %comport%
	GOTO FTDI_FLASH
) ELSE (
  ECHO Module in BOOT0 mode not found on %comport%
  GOTO :EOF
)

:FTDI_FLASH
ECHO.
ECHO Flashing module via FTDI adapter on %comport%
ECHO.
ECHO Erasing ...
ECHO stm32flash.exe -o -S 0x8000000:253952 -b 115200 %comport%
stm32flash.exe -o -S 0x8000000:253952 -b 115200 %comport%

ECHO Writing bootloader ...
ECHO stm32flash.exe -v -e 0 -b 115200 -w %blpath% %comport%
stm32flash.exe -v -e 0 -b 115200 -w %blpath% %comport%

ECHO Writing Multi firmware ...
ECHO stm32flash.exe -v -s 4 -e 0 -g 0x8002000 -b 115200 -w %fwpath% %comport%
stm32flash.exe -v -s 4 -e 0 -g 0x8002000 -b 115200 -w %fwpath% %comport%
ECHO.
ECHO Done.
GOTO :EOF
