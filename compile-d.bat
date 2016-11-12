@echo off

set name=MyStrategy

del /F /Q %name%.exe

SET FILES=

for %%i in (*.d) do (
    call concatenate %%i
)

for %%i in (model\*.d) do (
    call concatenate %%i
)

dmd -O -release -inline -noboundscheck -L/STACK:268435456 -wi -m32 %FILES% -of%name% 2>compilation.log
